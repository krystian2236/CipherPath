import Foundation

struct LearningProgress: Codable, Equatable, Sendable {
  var completedStages: [String: [LessonStage]] = [:]
  var labMissions: [String: LabMissionProgress] = [:]
  var pointsWallet: PointsWallet = .initial

  private enum CodingKeys: String, CodingKey {
    case completedStages
    case labMissions
    case pointsWallet
  }

  init() {}

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    completedStages = try container.decodeIfPresent(
      [String: [LessonStage]].self, forKey: .completedStages
    ) ?? [:]
    labMissions = try container.decodeIfPresent(
      [String: LabMissionProgress].self, forKey: .labMissions
    ) ?? [:]
    pointsWallet = try container.decodeIfPresent(
      PointsWallet.self, forKey: .pointsWallet
    ) ?? .initial
  }
}

@MainActor
final class LearningProgressStore: ObservableObject {
  @Published private(set) var progress: LearningProgress

  private let defaults: UserDefaults
  private let storageKey: String

  init(
    defaults: UserDefaults = .standard,
    storageKey: String = "cipherpath.learningProgress.v1"
  ) {
    self.defaults = defaults
    self.storageKey = storageKey
    if let data = defaults.data(forKey: storageKey),
       let restored = try? JSONDecoder().decode(LearningProgress.self, from: data) {
      progress = restored
    } else {
      progress = LearningProgress()
    }
  }

  func canStart(_ lesson: LearningLesson) -> Bool {
    lesson.availability == .available
  }

  func currentStage(for lesson: LearningLesson) -> LessonStage? {
    guard canStart(lesson) else { return nil }
    let completed = progress.completedStages[lesson.id, default: []]
    guard completed.count < lesson.stages.count else { return nil }
    return lesson.stages[completed.count]
  }

  func isCompleted(lessonID: String) -> Bool {
    guard let lesson = lesson(withID: lessonID) else { return false }
    return progress.completedStages[lessonID, default: []].count == lesson.stages.count
  }

  func labProgress(for lessonID: String) -> LabMissionProgress {
    progress.labMissions[lessonID, default: LabMissionProgress()]
  }

  var pointsBalance: Int {
    progress.pointsWallet.balance
  }

  func canStartLab(
    lessonID: String,
    mode: LabMode,
    distribution: AppDistributionMode = .currentBuild
  ) -> Bool {
    guard let lesson = lesson(withID: lessonID),
          canStart(lesson),
          StarterLabs.definition(for: lesson) != nil else { return false }
    if mode == .guided || distribution == .developer { return true }
    return labProgress(for: lessonID).completedModes.contains(.guided)
  }

  func reward(lessonID: String, mode: LabMode) -> LabReward {
    let mission = labProgress(for: lessonID)
    let assistance = mission.assistanceByMode[mode]
      ?? (mission.hintUsedModes.contains(mode) ? .hint : .none)
    return LabReward.evaluate(mode: mode, assistance: assistance)
  }

  @discardableResult
  func recordAssistance(
    lessonID: String,
    mode: LabMode,
    level: LabAssistanceLevel,
    distribution: AppDistributionMode = .currentBuild
  ) -> Bool {
    guard distribution == .appStore,
          level != .none,
          canStartLab(lessonID: lessonID, mode: mode, distribution: distribution) else {
      return false
    }

    let current = progress.labMissions[lessonID, default: LabMissionProgress()]
      .assistanceByMode[mode] ?? .none
    guard level > current else { return false }

    progress.labMissions[lessonID, default: LabMissionProgress()].assistanceByMode[mode] = level
    progress.labMissions[lessonID, default: LabMissionProgress()].hintUsedModes.insert(mode)
    save()
    return true
  }

  @discardableResult
  func recordHint(lessonID: String, mode: LabMode) -> Bool {
    recordAssistance(
      lessonID: lessonID,
      mode: mode,
      level: .hint,
      distribution: .appStore
    )
  }

  @discardableResult
  func purchaseAssistance(
    lessonID: String,
    mode: LabMode,
    purchase: PointsPurchase,
    distribution: AppDistributionMode = .currentBuild
  ) -> PointsPurchaseResult {
    guard canStartLab(lessonID: lessonID, mode: mode, distribution: distribution) else {
      return .insufficient(missing: purchase.cost)
    }
    guard distribution == .appStore else { return .purchased }

    var wallet = progress.pointsWallet
    let result = wallet.purchase(purchase, lessonID: lessonID, mode: mode)
    guard result == .purchased else { return result }

    progress.pointsWallet = wallet
    let assistance: LabAssistanceLevel = purchase == .hint ? .hint : .solution
    let current = progress.labMissions[lessonID, default: LabMissionProgress()]
      .assistanceByMode[mode] ?? .none
    if assistance > current {
      progress.labMissions[lessonID, default: LabMissionProgress()].assistanceByMode[mode] = assistance
    }
    progress.labMissions[lessonID, default: LabMissionProgress()].hintUsedModes.insert(mode)
    save()
    return result
  }

  @discardableResult
  func saveCheckpoint(
    lessonID: String,
    mode: LabMode,
    session: LabSession
  ) -> Bool {
    guard let definition = StarterLabs.definition(for: lessonID),
          definition.id == session.definitionID else { return false }
    progress.labMissions[lessonID, default: LabMissionProgress()].checkpoints[mode] =
      LabCheckpoint(
        definitionID: session.definitionID,
        completedObjectiveIDs: session.completedObjectiveIDs,
        capturedFlagIDs: session.capturedFlagIDs
      )
    save()
    return true
  }

  func restoredLabSession(
    lessonID: String,
    mode: LabMode,
    definitionID: String
  ) -> LabSession {
    guard let checkpoint = labProgress(for: lessonID).checkpoints[mode],
          checkpoint.definitionID == definitionID else {
      return LabSession(definitionID: definitionID)
    }
    return LabSession(
      definitionID: definitionID,
      isRunning: false,
      history: [],
      discoveries: [],
      completedObjectiveIDs: checkpoint.completedObjectiveIDs,
      capturedFlagIDs: checkpoint.capturedFlagIDs
    )
  }

  @discardableResult
  func completeLab(
    lessonID: String,
    mode: LabMode,
    distribution: AppDistributionMode = .currentBuild
  ) -> Bool {
    guard let lesson = lesson(withID: lessonID),
          canStartLab(lessonID: lessonID, mode: mode, distribution: distribution) else { return false }
    let inserted = progress.labMissions[lessonID, default: LabMissionProgress()]
      .completedModes.insert(mode).inserted
    guard inserted else { return false }

    progress.labMissions[lessonID, default: LabMissionProgress()].xp += reward(
      lessonID: lessonID,
      mode: mode
    ).xp
    progress.labMissions[lessonID, default: LabMissionProgress()].checkpoints.removeValue(
      forKey: mode
    )
    if mode == .guided {
      progress.completedStages[lessonID] = lesson.stages
    }
    if distribution == .appStore {
      _ = progress.pointsWallet.rewardMission(lessonID: lessonID)
    }
    save()
    return true
  }

  @discardableResult
  func complete(stage: LessonStage, lessonID: String) -> Bool {
    guard let lesson = lesson(withID: lessonID),
          canStart(lesson),
          currentStage(for: lesson) == stage else { return false }

    progress.completedStages[lessonID, default: []].append(stage)
    save()
    return true
  }

  func reset() {
    progress = LearningProgress()
    defaults.removeObject(forKey: storageKey)
  }

  func resetPointsForDevelopment() {
    progress.pointsWallet = .initial
    save()
  }

  func addPointsForDevelopment(_ amount: Int) {
    progress.pointsWallet.addDevelopmentPoints(amount)
    save()
  }

  private func lesson(withID id: String) -> LearningLesson? {
    StarterCurriculum.lessons.first { $0.id == id }
  }

  private func save() {
    guard let data = try? JSONEncoder().encode(progress) else { return }
    defaults.set(data, forKey: storageKey)
  }
}
