import Foundation

struct LearningProgress: Codable, Equatable, Sendable {
  var completedStages: [String: [LessonStage]] = [:]
  var labMissions: [String: LabMissionProgress] = [:]

  private enum CodingKeys: String, CodingKey {
    case completedStages
    case labMissions
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

  func canStartLab(lessonID: String, mode: LabMode) -> Bool {
    guard let lesson = lesson(withID: lessonID),
          canStart(lesson),
          StarterLabs.definition(for: lesson) != nil else { return false }
    if mode == .guided { return true }
    return labProgress(for: lessonID).completedModes.contains(.guided)
  }

  @discardableResult
  func recordHint(lessonID: String, mode: LabMode) -> Bool {
    guard canStartLab(lessonID: lessonID, mode: mode) else { return false }
    let inserted = progress.labMissions[lessonID, default: LabMissionProgress()]
      .hintUsedModes.insert(mode).inserted
    if inserted { save() }
    return inserted
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
  func completeLab(lessonID: String, mode: LabMode) -> Bool {
    guard let lesson = lesson(withID: lessonID),
          canStartLab(lessonID: lessonID, mode: mode) else { return false }
    let inserted = progress.labMissions[lessonID, default: LabMissionProgress()]
      .completedModes.insert(mode).inserted
    guard inserted else { return false }

    progress.labMissions[lessonID, default: LabMissionProgress()].xp += mode.xpReward
    progress.labMissions[lessonID, default: LabMissionProgress()].checkpoints.removeValue(
      forKey: mode
    )
    if mode == .guided {
      progress.completedStages[lessonID] = lesson.stages
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

  private func lesson(withID id: String) -> LearningLesson? {
    StarterCurriculum.lessons.first { $0.id == id }
  }

  private func save() {
    guard let data = try? JSONEncoder().encode(progress) else { return }
    defaults.set(data, forKey: storageKey)
  }
}
