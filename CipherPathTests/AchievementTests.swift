import Foundation
import Testing

@testable import CipherPath

@Suite("Lab modes and achievements")
struct AchievementTests {
  private func isolatedDefaults() -> UserDefaults {
    UserDefaults(suiteName: "CipherPathTests.Achievements.\(UUID().uuidString)")!
  }

  @Test("Older progress receives the initial points balance")
  func migratesProgressWithoutWallet() throws {
    let legacyData = Data(#"{"completedStages":{},"labMissions":{}}"#.utf8)

    let progress = try JSONDecoder().decode(LearningProgress.self, from: legacyData)

    #expect(progress.pointsWallet.balance == 100)
  }

  @Test("Purchased assistance persists with its updated balance")
  @MainActor
  func persistsPurchasedAssistance() {
    let defaults = isolatedDefaults()
    let lessonID = "web-http-anatomy"
    let store = LearningProgressStore(defaults: defaults)

    let result = store.purchaseAssistance(
      lessonID: lessonID,
      mode: .guided,
      purchase: .hint,
      distribution: .appStore
    )
    let restored = LearningProgressStore(defaults: defaults)

    #expect(result == .purchased)
    #expect(restored.pointsBalance == 80)
    #expect(restored.labProgress(for: lessonID).assistanceByMode[.guided] == .hint)
  }

  @Test("Mission points are awarded once across Guided and Adventure")
  @MainActor
  func awardsMissionPointsOnceAcrossModes() {
    let lessonID = "fundamentals-digital-safety"
    let store = LearningProgressStore(defaults: isolatedDefaults())

    #expect(store.completeLab(lessonID: lessonID, mode: .guided, distribution: .appStore))
    #expect(store.pointsBalance == 200)
    #expect(store.completeLab(lessonID: lessonID, mode: .adventure, distribution: .appStore))
    #expect(store.pointsBalance == 200)
    #expect(store.labProgress(for: lessonID).xp == 250)
  }

  @Test("Developer points reset preserves completed missions")
  @MainActor
  func resetsOnlyDeveloperWallet() {
    let lessonID = "fundamentals-digital-safety"
    let store = LearningProgressStore(defaults: isolatedDefaults())
    #expect(store.completeLab(lessonID: lessonID, mode: .guided, distribution: .appStore))
    store.addPointsForDevelopment(100)

    store.resetPointsForDevelopment()

    #expect(store.pointsBalance == 100)
    #expect(store.labProgress(for: lessonID).completedModes == [.guided])
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

  @Test("Awards distinct path medals from completed missions")
  @MainActor
  func evaluatesPathAchievements() {
    let store = LearningProgressStore(defaults: isolatedDefaults())

    #expect(store.completeLab(lessonID: "blue-team-find-log-event", mode: .guided))
    #expect(store.completeLab(lessonID: "blue-team-suspicious-login", mode: .guided))
    #expect(store.completeLab(lessonID: "web-http-anatomy", mode: .guided))
    #expect(store.completeLab(lessonID: "web-spot-input-risk", mode: .guided))

    let blueTeam = AchievementCatalog.evaluate(store.progress, id: .blueTeamAnalyst)
    let web = AchievementCatalog.evaluate(store.progress, id: .webDefender)
    let redTeam = AchievementCatalog.evaluate(store.progress, id: .redTeamOperator)

    #expect(blueTeam.isUnlocked)
    #expect(web.isUnlocked)
    #expect(!redTeam.isUnlocked)
    #expect(blueTeam.current == 2)
    #expect(web.current == 2)
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
