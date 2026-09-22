import Foundation

struct LearningProgress: Codable, Equatable, Sendable {
  var completedStages: [String: [LessonStage]] = [:]
  var labMissions: [String: LabMissionProgress] = [:]
  var pointsWallet: PointsWallet = .initial
  var recentActivities: [LearningActivity] = []
  var lessonNotes: [String: String] = [:]
  var securityChecks: [String: SecurityChecklistRecord] = [:]
  var bookmarkedLessonIDs: Set<String> = []
  var practiceHistory: [PracticeHistoryEntry] = []
  var lastLessonID: String?
  var dailyGoalXP: Int = 100
  var xpEarnedToday = 0
  var streakDays = 0
  var lastActiveDay: String?

  private enum CodingKeys: String, CodingKey {
    case completedStages
    case labMissions
    case pointsWallet
    case recentActivities
    case lessonNotes
    case securityChecks
    case bookmarkedLessonIDs
    case practiceHistory
    case lastLessonID
    case dailyGoalXP
    case xpEarnedToday
    case streakDays
    case lastActiveDay
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
    recentActivities = try container.decodeIfPresent(
      [LearningActivity].self, forKey: .recentActivities
    ) ?? []
    lessonNotes = try container.decodeIfPresent(
      [String: String].self, forKey: .lessonNotes
    ) ?? [:]
    securityChecks = try container.decodeIfPresent(
      [String: SecurityChecklistRecord].self, forKey: .securityChecks
    ) ?? [:]
    bookmarkedLessonIDs = try container.decodeIfPresent(Set<String>.self, forKey: .bookmarkedLessonIDs) ?? []
    practiceHistory = try container.decodeIfPresent([PracticeHistoryEntry].self, forKey: .practiceHistory) ?? []
    lastLessonID = try container.decodeIfPresent(String.self, forKey: .lastLessonID)
    dailyGoalXP = try container.decodeIfPresent(Int.self, forKey: .dailyGoalXP) ?? 100
    xpEarnedToday = try container.decodeIfPresent(Int.self, forKey: .xpEarnedToday) ?? 0
    streakDays = try container.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
    lastActiveDay = try container.decodeIfPresent(String.self, forKey: .lastActiveDay)
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

  var recentActivities: [LearningActivity] {
    progress.recentActivities
  }

  var continueLesson: LearningLesson? {
    guard let id = progress.lastLessonID else { return nil }
    return lesson(withID: id)
  }

  var dailyGoalProgress: Double {
    min(Double(progress.xpEarnedToday) / Double(max(progress.dailyGoalXP, 1)), 1)
  }

  var isDailyGoalComplete: Bool {
    progress.xpEarnedToday >= progress.dailyGoalXP
  }

  var streakDays: Int { progress.streakDays }

  var practiceHistory: [PracticeHistoryEntry] { progress.practiceHistory }

  func isBookmarked(lessonID: String) -> Bool {
    progress.bookmarkedLessonIDs.contains(lessonID)
  }

  func toggleBookmark(lessonID: String) {
    if !progress.bookmarkedLessonIDs.insert(lessonID).inserted {
      progress.bookmarkedLessonIDs.remove(lessonID)
    }
    save()
  }

  func setDailyGoalXP(_ value: Int) {
    progress.dailyGoalXP = min(max(value, 25), 500)
    save()
  }

  func note(for lessonID: String) -> String {
    progress.lessonNotes[lessonID, default: ""]
  }

  func saveNote(_ note: String, for lessonID: String) {
    let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      progress.lessonNotes.removeValue(forKey: lessonID)
    } else {
      progress.lessonNotes[lessonID] = String(trimmed.prefix(2_000))
    }
    save()
  }

  func isSecurityCheckCompleted(_ itemID: String) -> Bool {
    progress.securityChecks[itemID] != nil
  }

  func securityReviewDate(for itemID: String) -> Date? {
    progress.securityChecks[itemID]?.checkedAt
  }

  func setSecurityCheck(_ itemID: String, completed: Bool) {
    if completed {
      progress.securityChecks[itemID] = SecurityChecklistRecord(checkedAt: .now)
    } else {
      progress.securityChecks.removeValue(forKey: itemID)
    }
    save()
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
    recordDailyProgress(reward(lessonID: lessonID, mode: mode).xp)
    progress.practiceHistory.insert(
      PracticeHistoryEntry(
        lessonID: lessonID,
        labTitle: StarterLabs.definition(for: lessonID)?.title ?? lesson.title,
        mode: mode,
        xp: reward(lessonID: lessonID, mode: mode).xp
      ),
      at: 0
    )
    progress.practiceHistory = Array(progress.practiceHistory.prefix(30))
    recordActivity(
      kind: .labCompleted,
      lessonID: lessonID,
      title: "\(lesson.title) • laboratorium ukończone"
    )
    save()
    return true
  }

  @discardableResult
  func complete(stage: LessonStage, lessonID: String) -> Bool {
    guard let lesson = lesson(withID: lessonID),
          canStart(lesson),
          currentStage(for: lesson) == stage else { return false }

    progress.completedStages[lessonID, default: []].append(stage)
    progress.lastLessonID = lessonID
    touchActivityDay()
    recordActivity(
      kind: .lessonStageCompleted,
      lessonID: lessonID,
      title: "\(lesson.title) • \(stage.title)"
    )
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

  private func recordActivity(
    kind: LearningActivityKind,
    lessonID: String,
    title: String
  ) {
    progress.recentActivities.insert(
      LearningActivity(kind: kind, lessonID: lessonID, title: title),
      at: 0
    )
    progress.recentActivities = Array(progress.recentActivities.prefix(20))
  }

  private func recordDailyProgress(_ xp: Int) {
    touchActivityDay()
    progress.xpEarnedToday += max(xp, 0)
  }

  private func touchActivityDay() {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = "yyyy-MM-dd"
    let today = formatter.string(from: .now)
    if progress.lastActiveDay == today { return }

    if let last = progress.lastActiveDay,
       let lastDate = formatter.date(from: last),
       Calendar.current.dateComponents([.day], from: lastDate, to: .now).day == 1 {
      progress.streakDays += 1
    } else {
      progress.streakDays = 1
    }
    progress.lastActiveDay = today
    progress.xpEarnedToday = 0
  }

  private func save() {
    guard let data = try? JSONEncoder().encode(progress) else { return }
    defaults.set(data, forKey: storageKey)
  }
}
