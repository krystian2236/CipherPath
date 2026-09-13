import Foundation
import Testing

@testable import CipherPath

@Suite("Lab modes and achievements")
struct AchievementTests {
  private func isolatedDefaults() -> UserDefaults {
    UserDefaults(suiteName: "CipherPathTests.Achievements.\(UUID().uuidString)")!
  }

  @Test("Adventure unlocks after Guided and XP is awarded only once")
  @MainActor
  func unlocksAdventureAndAwardsDeterministicXP() {
    let lessonID = "fundamentals-digital-safety"
    let store = LearningProgressStore(defaults: isolatedDefaults())

    #expect(!store.canStartLab(lessonID: lessonID, mode: .adventure, distribution: .appStore))
    #expect(store.completeLab(lessonID: lessonID, mode: .guided))
    #expect(store.canStartLab(lessonID: lessonID, mode: .adventure))
    #expect(store.labProgress(for: lessonID).xp == 100)
    #expect(!store.completeLab(lessonID: lessonID, mode: .guided))
    #expect(store.labProgress(for: lessonID).xp == 100)
    #expect(store.completeLab(lessonID: lessonID, mode: .adventure))
    #expect(store.labProgress(for: lessonID).xp == 250)
  }

  @Test("Assistance produces gold silver and bronze mission rewards")
  func assistanceChangesRewardAndGrade() {
    #expect(LabReward.evaluate(mode: .adventure, assistance: .none) == LabReward(xp: 150, grade: .gold))
    #expect(LabReward.evaluate(mode: .adventure, assistance: .hint) == LabReward(xp: 120, grade: .silver))
    #expect(LabReward.evaluate(mode: .adventure, assistance: .solution) == LabReward(xp: 80, grade: .bronze))
  }

  @Test("Developer assistance stays unrestricted and does not reduce rewards")
  @MainActor
  func developerAssistanceHasNoPenaltyOrAdventureGate() {
    let lessonID = "fundamentals-digital-safety"
    let store = LearningProgressStore(defaults: isolatedDefaults())

    #expect(store.canStartLab(lessonID: lessonID, mode: .adventure, distribution: .developer))
    #expect(!store.recordAssistance(
      lessonID: lessonID,
      mode: .adventure,
      level: .solution,
      distribution: .developer
    ))
    #expect(store.reward(lessonID: lessonID, mode: .adventure) == LabReward(xp: 150, grade: .gold))
  }

  @Test("Store build keeps the strongest assistance and applies it once")
  @MainActor
  func storeAssistancePersistsStrongestLevel() {
    let lessonID = "web-http-anatomy"
    let store = LearningProgressStore(defaults: isolatedDefaults())

    #expect(store.recordAssistance(lessonID: lessonID, mode: .guided, level: .hint, distribution: .appStore))
    #expect(store.recordAssistance(lessonID: lessonID, mode: .guided, level: .solution, distribution: .appStore))
    #expect(!store.recordAssistance(lessonID: lessonID, mode: .guided, level: .hint, distribution: .appStore))
    #expect(store.reward(lessonID: lessonID, mode: .guided) == LabReward(xp: 50, grade: .bronze))
    #expect(store.completeLab(lessonID: lessonID, mode: .guided))
    #expect(store.labProgress(for: lessonID).xp == 50)
  }

  @Test("Records hint use per mode and restores it without terminal history")
  @MainActor
  func persistsSafeMissionProgress() {
    let lessonID = "web-http-anatomy"
    let defaults = isolatedDefaults()
    let store = LearningProgressStore(defaults: defaults)

    #expect(store.completeLab(lessonID: lessonID, mode: .guided))
    #expect(store.recordHint(lessonID: lessonID, mode: .adventure))
    let restored = LearningProgressStore(defaults: defaults)

    #expect(restored.labProgress(for: lessonID).completedModes == [.guided])
    #expect(restored.labProgress(for: lessonID).hintUsedModes == [.adventure])
  }

  @Test("Awards medals only after their real skill conditions")
  @MainActor
  func evaluatesAchievementConditions() {
    let store = LearningProgressStore(defaults: isolatedDefaults())

    #expect(!AchievementCatalog.evaluate(store.progress, id: .firstFlag).isUnlocked)
    #expect(store.completeLab(lessonID: "fundamentals-digital-safety", mode: .guided))
    #expect(AchievementCatalog.evaluate(store.progress, id: .firstFlag).isUnlocked)
    #expect(store.completeLab(lessonID: "fundamentals-digital-safety", mode: .adventure))
    #expect(AchievementCatalog.evaluate(store.progress, id: .withoutHints).isUnlocked)
    #expect(!AchievementCatalog.evaluate(store.progress, id: .labMaster).isUnlocked)

    for lesson in StarterCurriculum.lessons.filter({ $0.availability == .available }).dropFirst() {
      #expect(store.completeLab(lessonID: lesson.id, mode: .guided))
    }

    let master = AchievementCatalog.evaluate(store.progress, id: .labMaster)
    #expect(master.isUnlocked)
    #expect(master.current == 10)
    #expect(master.target == 10)
  }

  @Test("Restores a safe checkpoint without command history")
  @MainActor
  func restoresSafeCheckpoint() {
    let lessonID = "fundamentals-read-port-scan"
    let defaults = isolatedDefaults()
    let store = LearningProgressStore(defaults: defaults)
    var session = LabSession(definitionID: "network-scout")
    session.isRunning = true
    session.history = [LabTerminalEntry(command: "secret input", output: "result")]
    session.discoveries = ["Wirtualny host odpowiada"]
    session.completedObjectiveIDs = ["availability"]
    session.capturedFlagIDs = ["user"]

    #expect(store.saveCheckpoint(lessonID: lessonID, mode: .guided, session: session))
    let restoredStore = LearningProgressStore(defaults: defaults)
    let restored = restoredStore.restoredLabSession(
      lessonID: lessonID,
      mode: .guided,
      definitionID: "network-scout"
    )

    #expect(!restored.isRunning)
    #expect(restored.history.isEmpty)
    #expect(restored.discoveries.isEmpty)
    #expect(restored.completedObjectiveIDs == ["availability"])
    #expect(restored.capturedFlagIDs == ["user"])
  }
}
