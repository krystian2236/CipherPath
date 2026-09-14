import Foundation
import Testing

@testable import CipherPath

@Suite("Points wallet")
struct PointsWalletTests {
  @Test("New wallet starts with one hundred points")
  func startsWithInitialBalance() {
    let wallet = PointsWallet.initial

    #expect(wallet.balance == 100)
    #expect(wallet.transactions.map(\.id) == ["initial"])
  }

  @Test("Hint costs twenty points only once per mission mode")
  func hintIsChargedOnce() {
    var wallet = PointsWallet.initial

    #expect(wallet.purchase(.hint, lessonID: "web-http", mode: .guided) == .purchased)
    #expect(wallet.balance == 80)
    #expect(wallet.purchase(.hint, lessonID: "web-http", mode: .guided) == .alreadyUnlocked)
    #expect(wallet.balance == 80)
  }

  @Test("Solution costs fifty points")
  func solutionHasExpectedCost() {
    var wallet = PointsWallet.initial

    #expect(wallet.purchase(.solution, lessonID: "network-scout", mode: .adventure) == .purchased)
    #expect(wallet.balance == 50)
  }

  @Test("Purchase cannot make balance negative")
  func rejectsPurchaseWithoutEnoughPoints() {
    var wallet = PointsWallet(
      transactions: [
        PointsTransaction(
          id: "fixture",
          kind: .initialBalance,
          amount: 10,
          date: Date(timeIntervalSince1970: 1),
          lessonID: nil,
          mode: nil
        )
      ]
    )

    #expect(wallet.purchase(.hint, lessonID: "mobile-storage", mode: .guided) == .insufficient(missing: 10))
    #expect(wallet.balance == 10)
    #expect(wallet.transactions.count == 1)
  }

  @Test("Mission reward is granted only once across modes")
  func missionRewardIsIdempotent() {
    var wallet = PointsWallet.initial

    let firstReward = wallet.rewardMission(lessonID: "fundamentals-scout")
    let repeatedReward = wallet.rewardMission(lessonID: "fundamentals-scout")

    #expect(firstReward)
    #expect(!repeatedReward)
    #expect(wallet.balance == 200)
    #expect(wallet.transactions.filter { $0.kind == .missionReward }.count == 1)
  }

  @Test("Lesson reward uses lesson wording in visible history")
  func lessonRewardUsesLessonWording() {
    let transaction = PointsTransaction(
      id: "reward:test",
      kind: .missionReward,
      amount: 100,
      date: Date(timeIntervalSince1970: 10),
      lessonID: "blue-team-find-log-event",
      mode: nil
    )

    let row = PointsHistoryRowModel.rows(for: [transaction])[0]
    #expect(row.title == "Nagroda za lekcję")
  }

  @Test("Developer adjustment adds test points")
  func addsDeveloperTestPoints() {
    var wallet = PointsWallet.initial

    wallet.addDevelopmentPoints(100, date: Date(timeIntervalSince1970: 30))

    #expect(wallet.balance == 200)
    #expect(wallet.transactions.last?.kind == .developerAdjustment)
  }
}

@Suite("Featured lesson access")
struct FeaturedLessonAccessTests {
  @Test("Featured lesson always respects the active release policy")
  func featuredLessonRespectsAccessPolicy() {
    let appStorePolicy = ContentAccessPolicy.releasePolicy(for: .appStore)
    let appStoreLesson = FeaturedLessonSelection.lesson(for: appStorePolicy)

    #expect(appStoreLesson.id == "blue-team-suspicious-login")
    #expect(appStorePolicy.access(for: appStoreLesson) == .included)

    let developerPolicy = ContentAccessPolicy.releasePolicy(for: .developer)
    let developerLesson = FeaturedLessonSelection.lesson(for: developerPolicy)

    #expect(developerLesson.id == "blue-team-suspicious-login")
    #expect(developerPolicy.access(for: developerLesson) == .included)
  }
}

@Suite("Dashboard copy")
struct DashboardCopyTests {
  @Test("Featured content uses lesson terminology while Missions stays independent")
  func featuredContentUsesLessonTerminology() {
    #expect(DashboardCopy.featuredLessonTitle == "Polecana lekcja")
    #expect(DashboardCopy.pointsSubtitle == "Zdobywaj w lekcjach i wykorzystuj na podpowiedzi")
    #expect(!DashboardCopy.featuredLessonTitle.lowercased().contains("misja"))
    #expect(MissionsTabPresentation.current == .comingSoon)
    #expect(!MissionsTabPresentation.current.showsLessonLinks)
  }

  @Test("Release does not advertise Pro before StoreKit exists")
  func sectionTitleMatchesDistribution() {
    #expect(DashboardCopy.featureSectionTitle(for: .appStore) == "Punkty")
    #expect(DashboardCopy.featureSectionTitle(for: .developer) == "CipherPath Pro")
  }
}

@Suite("Release surface")
struct ReleaseSurfaceTests {
  @Test("Unfinished Missions and Store stay developer-only")
  func unfinishedFeaturesStayDeveloperOnly() {
    #expect(AppDistributionMode.developer.showsMissionsTab)
    #expect(AppDistributionMode.developer.showsFutureStore)
    #expect(!AppDistributionMode.appStore.showsMissionsTab)
    #expect(!AppDistributionMode.appStore.showsFutureStore)
  }

  @Test("App Store release stays open until StoreKit ships")
  func appStoreHasNoDeadPaidGate() {
    #expect(ContentAccessPolicy.forDistribution(.appStore).tier == .free)
    #expect(ContentAccessPolicy.releasePolicy(for: .appStore).tier == .pro)
    #expect(ContentAccessPolicy.releasePolicy(for: .developer).tier == .pro)
  }
}

@Suite("Scan accessibility")
struct ScanAccessibilityTests {
  @Test("Scan progress announces interpolated host counts")
  func scanProgressAnnouncesActualCounts() {
    #expect(ScanProgressAccessibility.value(completed: 7, total: 42) == "7 z 42 adresów")
  }
}

@Suite("DEV UI references")
struct DevUIReferenceTests {
  @Test("VectorSec labels use stable English technical paths")
  func labelsUseStablePaths() {
    #expect(DevLocation.dashboard.displayLabel == "[DEV: VECTORSEC / START]")
    #expect(DevLocation.dashboardMission.displayLabel == "[DEV: VECTORSEC / START / FEATURED_LESSON]")
    #expect(DevLocation.pathDetail.displayLabel == "[DEV: VECTORSEC / PATHS / PATH_DETAIL]")
    #expect(DevLocation.practiceScanner.displayLabel == "[DEV: VECTORSEC / PRACTICE / SCANNER]")
    #expect(DevLocation.labTerminal.displayLabel == "[DEV: VECTORSEC / LAB / TERMINAL]")
  }

  @Test("Tap copy values identify app screen component and SwiftUI view")
  func copyValuesAreAgentReady() {
    #expect(
      DevLocation.dashboardMission.uiRef
        == "UIREF app=VectorSec screen=start component=featuredLesson view=DashboardView"
    )
    #expect(
      DevLocation.practiceToolbox.uiRef
        == "UIREF app=VectorSec screen=practice component=toolbox view=ToolboxView"
    )
    #expect(Set(DevLocation.allCases.map(\.uiRef)).count == DevLocation.allCases.count)
  }

  @Test("DEV references never appear in App Store distribution")
  func visibilityStaysDeveloperOnly() {
    #expect(DevLocation.isVisible(in: .developer))
    #expect(!DevLocation.isVisible(in: .appStore))
  }
}

@Suite("App language")
struct AppLanguageTests {
  @Test("Language choices stay stable for persisted preferences")
  func choicesStayStable() {
    #expect(AppLanguage.allCases == [.system, .polish, .english])
    #expect(AppLanguage.system.rawValue == "system")
    #expect(AppLanguage.polish.rawValue == "pl")
    #expect(AppLanguage.english.rawValue == "en")
  }

  @Test("Only explicit language choices override the system locale")
  func localeOverrideMatchesSelection() {
    #expect(AppLanguage.system.localeOverride == nil)
    #expect(AppLanguage.polish.localeOverride?.identifier == "pl")
    #expect(AppLanguage.english.localeOverride?.identifier == "en")
  }

  @Test("Unknown stored values safely fall back to System")
  func storedValueFallbackIsSafe() {
    #expect(AppLanguage.fromStoredValue("pl") == .polish)
    #expect(AppLanguage.fromStoredValue("en") == .english)
    #expect(AppLanguage.fromStoredValue("unknown") == .system)
    #expect(AppLanguage.fromStoredValue(nil) == .system)
  }
}
