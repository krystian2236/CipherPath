import XCTest
import Testing

@testable import CipherPath

private func isolatedDefaults() -> UserDefaults {
  let suiteName = "CipherPathTests.Isolated.\(UUID().uuidString)"
  return UserDefaults(suiteName: suiteName)!
}

@Suite("Starter curriculum")
struct StarterCurriculumTests {
  @Test("MVP contains five learning paths and twenty-five visible lessons")
  func containsCompleteVisibleCatalog() {
    #expect(StarterCurriculum.paths == LearningPath.allCases)
    #expect(StarterCurriculum.lessons.count == 25)
    #expect(
      LearningPath.allCases.allSatisfy {
        StarterCurriculum.lessons(in: $0).count == 5
      }
    )
  }

  @Test("Pro exposes the complete twenty-five-mission catalog")
  func keepsReleaseAvailabilityPerPath() {
    for path in LearningPath.allCases {
      let lessons = StarterCurriculum.lessons(in: path)
      let releasedCount = 5
      #expect(lessons.filter { $0.availability == .available }.count == releasedCount)
      #expect(lessons.filter { $0.availability == .comingSoon }.count == 5 - releasedCount)
      #expect(lessons.map(\.order) == [1, 2, 3, 4, 5])
    }
  }

  @Test("Every available lesson follows the complete mission flow")
  func availableLessonsContainFourRequiredStages() {
    let availableLessons = StarterCurriculum.lessons.filter {
      $0.availability == .available
    }

    #expect(availableLessons.count == 25)
    #expect(
      availableLessons.allSatisfy {
        $0.stages == [.learn, .check, .findFlag, .explanation]
      }
    )
  }

  @Test("Lesson identifiers are unique")
  func identifiersAreUnique() {
    let identifiers = StarterCurriculum.lessons.map(\.id)
    #expect(Set(identifiers).count == identifiers.count)
  }

  @Test("Starter lessons use only controlled learning environments")
  func lessonsUseControlledEnvironments() {
    #expect(
      StarterCurriculum.lessons.allSatisfy {
        $0.environment == .offlineSimulation || $0.environment == .ownedLab
      }
    )
  }
}

@Suite("Content access")
struct ContentAccessTests {
  @Test("Missions tab exposes controlled offline lessons")
  func missionsTabIsAvailable() {
    #expect(MissionsTabPresentation.current == .available)
    #expect(MissionsTabPresentation.current.showsLessonLinks)
  }

  @Test("Developer location labels are stable and hidden from store builds")
  func developerLocationLabelsIdentifyAppParts() {
    #expect(DevLocation.dashboardMission.label == "[DEV: START / DZISIEJSZA MISJA]")
    #expect(!DevLocation.allCases.map(\.copyValue).contains("DEV: KARTA ŚCIEŻKI"))
    #expect(!DevLocation.allCases.map(\.copyValue).contains("DEV: LAB / MASZYNA"))
    #expect(DevLocation.labTerminal.label == "[DEV: LAB / TERMINAL]")
    #expect(DevLocation.labTerminal.copyValue == "DEV: LAB / TERMINAL")
    #expect(DevLocation.achievements.label == "[DEV: OSIĄGNIĘCIA]")
    #expect(DevLocation.isVisible(in: .developer))
    #expect(!DevLocation.isVisible(in: .appStore))
  }

  @Test("Adventure selector is available only in the developer build")
  func adventureVisibilityFollowsDistribution() {
    #expect(AppDistributionMode.developer.showsAdventureMode)
    #expect(!AppDistributionMode.appStore.showsAdventureMode)
  }

  @Test("Path cards derive progress from the selected access tier")
  func pathCardsUseActualAccessCounts() {
    let pro = ContentAccessPolicy(tier: .pro)
    let demo = ContentAccessPolicy(tier: .testFlightDemo)

    #expect(PathCardSummary.make(for: .blueTeam, policy: pro).includedCount == 5)
    #expect(PathCardSummary.make(for: .blueTeam, policy: pro).remainingCount == 0)
    #expect(PathCardSummary.make(for: .webSecurity, policy: pro).includedCount == 5)
    #expect(PathCardSummary.make(for: .fundamentals, policy: pro).includedCount == 5)
    #expect(PathCardSummary.make(for: .redTeam, policy: pro).includedCount == 5)
    #expect(PathCardSummary.make(for: .mobileSecurity, policy: pro).includedCount == 5)

    for path in LearningPath.allCases {
      #expect(PathCardSummary.make(for: path, policy: demo).includedCount == 2)
      #expect(PathCardSummary.make(for: path, policy: demo).remainingCount == 3)
    }
  }

  @Test("Points opens while the future store stays inactive")
  func pointsOpenAndStoreStaysInactive() {
    #expect(FutureFeatureCatalog.previews.map(\.id) == ["points", "store"])
    #expect(FutureFeatureCatalog.previews[0].isEnabled)
    #expect(!FutureFeatureCatalog.previews[1].isEnabled)
  }

  @Test("Points history is newest first with readable signed amounts")
  func pointsHistoryIsReadable() {
    let transactions = [
      PointsTransaction(
        id: "older",
        kind: .missionReward,
        amount: 100,
        date: Date(timeIntervalSince1970: 10),
        lessonID: "fundamentals-digital-safety",
        mode: nil
      ),
      PointsTransaction(
        id: "newer",
        kind: .hint,
        amount: -20,
        date: Date(timeIntervalSince1970: 20),
        lessonID: "web-http-anatomy",
        mode: .guided
      ),
    ]

    let rows = PointsHistoryRowModel.rows(for: transactions)

    #expect(rows.map(\.id) == ["newer", "older"])
    #expect(rows.map(\.amountText) == ["−20 pkt", "+100 pkt"])
  }

  @Test("Developer build has no paid lesson gate while App Store starts free")
  func distributionSelectsIndependentAccessRules() {
    #expect(ContentAccessPolicy.forDistribution(.developer).tier == .pro)
    #expect(ContentAccessPolicy.forDistribution(.appStore).tier == .free)
  }

  @Test("TestFlight demo keeps ten missions while new lessons require Pro")
  func testFlightDemoOpensCurrentCatalog() {
    let policy = ContentAccessPolicy(tier: .testFlightDemo)
    let included = StarterCurriculum.lessons.filter { policy.access(for: $0) == .included }

    #expect(included.count == 10)
    #expect(policy.access(for: StarterCurriculum.lessons(in: .blueTeam)[2]) == .requiresPro)
    #expect(policy.access(for: StarterCurriculum.lessons(in: .webSecurity)[2]) == .requiresPro)
  }

  @Test("Free tier opens one mission in every path")
  func freeTierOpensOneMissionPerPath() {
    let policy = ContentAccessPolicy(tier: .free)

    for path in LearningPath.allCases {
      let lessons = StarterCurriculum.lessons(in: path)
      #expect(policy.access(for: lessons[0]) == .included)
      #expect(policy.access(for: lessons[1]) == .requiresPro)
      #expect(policy.access(for: lessons[2]) == .requiresPro)
    }
  }

  @Test("Pro tier opens every released mission")
  func proTierOpensReleasedCatalog() {
    let policy = ContentAccessPolicy(tier: .pro)

    for lesson in StarterCurriculum.lessons {
      let expected: LessonAccess = lesson.availability == .available ? .included : .comingSoon
      #expect(policy.access(for: lesson) == expected)
    }
  }
}

@Suite("Mission briefing")
struct MissionBriefingTests {
  @Test("Every playable mission has a complete briefing before the lab")
  func playableMissionsHaveCompleteBriefings() {
    let playable = StarterCurriculum.lessons.filter { $0.availability == .available }

    for lesson in playable {
      let briefing = MissionBriefing.forLesson(lesson)
      #expect(!briefing.story.isEmpty)
      #expect(!briefing.objective.isEmpty)
      #expect(!briefing.learningOutcomes.isEmpty)
      #expect(briefing.estimatedMinutes > 0)
      #expect(briefing.difficulty == .easy || briefing.difficulty == .medium)
    }
  }
}

@Suite("Port scan access")
struct PortScanAccessTests {
  @Test("App Store scan requires consent and a private address")
  func appStoreRequiresConsentAndPrivateAddress() {
    let policy = PortScanAccessPolicy(mode: .appStore)

    #expect(policy.validate(host: "192.168.1.20", authorizationConfirmed: false) == .authorizationRequired)
    #expect(policy.validate(host: "192.168.1.20", authorizationConfirmed: true) == .allowed("192.168.1.20"))
    #expect(policy.validate(host: "8.8.8.8", authorizationConfirmed: true) == .privateAddressRequired)
    #expect(policy.validate(host: "example.com", authorizationConfirmed: true) == .privateAddressRequired)
  }

  @Test("Developer scan accepts a valid host without the Store gate")
  func developerAcceptsValidHostWithoutStoreGate() {
    let policy = PortScanAccessPolicy(mode: .developer)

    #expect(policy.validate(host: "example.com", authorizationConfirmed: false) == .allowed("example.com"))
    #expect(policy.validate(host: "8.8.8.8", authorizationConfirmed: false) == .allowed("8.8.8.8"))
  }

  @Test("Every mode rejects malformed hosts")
  func modesRejectMalformedHosts() {
    for mode in AppDistributionMode.allCases {
      let policy = PortScanAccessPolicy(mode: mode)
      #expect(policy.validate(host: "not a host", authorizationConfirmed: true) == .invalidHost)
    }
  }
}

@Suite("Learning progress")
struct LearningProgressTests {
  private func comingSoonLessonFixture() -> LearningLesson {
    LearningLesson(
      id: "coming-soon-test",
      path: .fundamentals,
      order: 99,
      title: "Wkrótce",
      summary: "Kontrolowana lekcja testowa",
      environment: .offlineSimulation,
      availability: .comingSoon,
      stages: []
    )
  }

  @Test("A lesson advances through stages in the required order")
  @MainActor
  func advancesInRequiredOrder() {
    let lesson = StarterCurriculum.lessons.first { $0.availability == .available }!
    let store = LearningProgressStore(defaults: isolatedDefaults())

    #expect(store.currentStage(for: lesson) == .learn)
    #expect(store.complete(stage: .learn, lessonID: lesson.id))
    #expect(store.currentStage(for: lesson) == .check)
    #expect(store.complete(stage: .check, lessonID: lesson.id))
    #expect(store.currentStage(for: lesson) == .findFlag)
    #expect(store.complete(stage: .findFlag, lessonID: lesson.id))
    #expect(store.currentStage(for: lesson) == .explanation)
    #expect(store.complete(stage: .explanation, lessonID: lesson.id))
    #expect(store.currentStage(for: lesson) == nil)
    #expect(store.isCompleted(lessonID: lesson.id))
  }

  @Test("A learner cannot skip the current stage")
  @MainActor
  func rejectsSkippedStage() {
    let lesson = StarterCurriculum.lessons.first { $0.availability == .available }!
    let store = LearningProgressStore(defaults: isolatedDefaults())

    #expect(!store.complete(stage: .findFlag, lessonID: lesson.id))
    #expect(store.currentStage(for: lesson) == .learn)
  }

  @Test("Completing the same stage twice is idempotent")
  @MainActor
  func completingStageTwiceIsIdempotent() {
    let lesson = StarterCurriculum.lessons.first { $0.availability == .available }!
    let store = LearningProgressStore(defaults: isolatedDefaults())

    #expect(store.complete(stage: .learn, lessonID: lesson.id))
    #expect(!store.complete(stage: .learn, lessonID: lesson.id))
    #expect(store.progress.completedStages[lesson.id] == [.learn])
  }

  @Test("Progress survives recreation of the store")
  @MainActor
  func persistsAndRestoresProgress() {
    let lesson = StarterCurriculum.lessons.first { $0.availability == .available }!
    let defaults = isolatedDefaults()
    let firstStore = LearningProgressStore(defaults: defaults)

    #expect(firstStore.complete(stage: .learn, lessonID: lesson.id))
    let restoredStore = LearningProgressStore(defaults: defaults)

    #expect(restoredStore.currentStage(for: lesson) == .check)
    #expect(restoredStore.progress.completedStages[lesson.id] == [.learn])
  }

  @Test("Coming soon lessons cannot be started")
  @MainActor
  func rejectsComingSoonLesson() {
    let lesson = comingSoonLessonFixture()
    let store = LearningProgressStore(defaults: isolatedDefaults())

    #expect(!store.canStart(lesson))
    #expect(!store.complete(stage: .learn, lessonID: lesson.id))
    #expect(store.progress.completedStages[lesson.id] == nil)
  }

  @Test("Reset removes all saved learning progress")
  @MainActor
  func resetClearsStoredProgress() {
    let lesson = StarterCurriculum.lessons.first { $0.availability == .available }!
    let defaults = isolatedDefaults()
    let store = LearningProgressStore(defaults: defaults)
    #expect(store.complete(stage: .learn, lessonID: lesson.id))

    store.reset()
    let restoredStore = LearningProgressStore(defaults: defaults)

    #expect(restoredStore.progress.completedStages.isEmpty)
    #expect(restoredStore.currentStage(for: lesson) == .learn)
  }
}

@Suite("Lesson mission content")
struct LessonMissionContentTests {
  @Test("Every available lesson has complete offline mission material")
  func availableLessonsHaveCompleteMaterial() {
    let lessons = StarterCurriculum.lessons.filter { $0.availability == .available }

    for lesson in lessons {
      let content = LessonMissionContent.content(for: lesson)
      #expect(!content.legalNotice.isEmpty)
      #expect(!content.learnText.isEmpty)
      #expect(!content.checkPrompt.isEmpty)
      #expect(!content.offlineEvidence.isEmpty)
      #expect(content.expectedFlag.hasPrefix("CIPHER{"))
      #expect(!content.explanation.isEmpty)
    }
  }

  @Test("Flag validation ignores spaces and letter case")
  func flagValidationNormalizesInput() {
    let lesson = StarterCurriculum.lessons.first { $0.id == "blue-team-find-log-event" }!
    let content = LessonMissionContent.content(for: lesson)

    #expect(content.accepts(flag: "  cipher{login_alert}  "))
    #expect(!content.accepts(flag: "CIPHER{WRONG}"))
  }

  @Test("Coming soon lessons do not expose mission material")
  func comingSoonLessonsHaveNoMaterial() {
    let lesson = comingSoonLessonFixture()

    #expect(LessonMissionContent.availableContent(for: lesson) == nil)
  }

  private func comingSoonLessonFixture() -> LearningLesson {
    LearningLesson(
      id: "coming-soon-test",
      path: .fundamentals,
      order: 99,
      title: "Wkrótce",
      summary: "Kontrolowana lekcja testowa",
      environment: .offlineSimulation,
      availability: .comingSoon,
      stages: []
    )
  }
}

@Suite("Session restoration")
struct SessionRestorationTests {
  @Test("Unknown tab falls back to Start")
  func unknownTabFallsBackToStart() {
    #expect(AppTab.restored(from: 999) == .start)
  }

  @Test("Primary navigation follows the learning journey")
  func primaryNavigationFollowsLearningJourney() {
    #expect(AppTab.navigationOrder == [.start, .learn, .practice, .security, .progress])
    #expect(AppTab.navigationOrder.map(\.sectionTitle) == ["Start", "Learn", "Practice", "Security", "Progress"])
  }

  @Test("Completing a lesson stage records local activity")
  @MainActor
  func completingLessonStageRecordsActivity() {
    let lesson = StarterCurriculum.lessons.first { $0.availability == .available }!
    let store = LearningProgressStore(defaults: isolatedDefaults())

    #expect(store.complete(stage: .learn, lessonID: lesson.id))
    #expect(store.recentActivities.count == 1)
    #expect(store.recentActivities[0].kind == LearningActivityKind.lessonStageCompleted)
    #expect(store.recentActivities[0].lessonID == lesson.id)
    #expect(store.recentActivities[0].title.contains("Poznaj"))
  }

  @Test("Legacy progress without activities remains readable")
  func legacyProgressDecodesWithoutActivityHistory() throws {
    let data = try JSONEncoder().encode(LearningProgress())
    var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    object.removeValue(forKey: "recentActivities")
    let legacyData = try JSONSerialization.data(withJSONObject: object)

    let restored = try JSONDecoder().decode(LearningProgress.self, from: legacyData)
    #expect(restored.recentActivities.isEmpty)
  }

  @Test("Lesson notes stay local and are restored")
  @MainActor
  func lessonNotesPersistLocally() {
    let defaults = isolatedDefaults()
    let lessonID = "fundamentals-digital-safety"
    let store = LearningProgressStore(defaults: defaults)

    store.saveNote("  Sprawdź tylko przygotowany host.  ", for: lessonID)
    #expect(store.note(for: lessonID) == "Sprawdź tylko przygotowany host.")

    let restored = LearningProgressStore(defaults: defaults)
    #expect(restored.note(for: lessonID) == "Sprawdź tylko przygotowany host.")
  }

  @Test("Security checklist stores a local review date")
  @MainActor
  func securityChecklistPersistsReview() {
    let defaults = isolatedDefaults()
    let store = LearningProgressStore(defaults: defaults)

    #expect(!store.isSecurityCheckCompleted("mfa"))
    store.setSecurityCheck("mfa", completed: true)
    #expect(store.isSecurityCheckCompleted("mfa"))
    #expect(store.securityReviewDate(for: "mfa") != nil)

    let restored = LearningProgressStore(defaults: defaults)
    #expect(restored.isSecurityCheckCompleted("mfa"))
    restored.setSecurityCheck("mfa", completed: false)
    #expect(!restored.isSecurityCheckCompleted("mfa"))
  }

  @Test("Progress summarizes each path without hidden lessons")
  func pathProgressUsesCurrentAccessPolicy() {
    let summary = LearningPathProgressSummary.make(
      for: .fundamentals,
      progress: LearningProgress(),
      policy: ContentAccessPolicy(tier: .free)
    )

    #expect(summary.availableLessons == 1)
    #expect(summary.completedLessons == 0)
    #expect(summary.completedLabs == 0)
    #expect(summary.xp == 0)
  }

  @Test("Shortcut route restores the selected command")
  func shortcutRouteRestoresSelectedCommand() {
    #expect(ISHWorkspaceRoute(rawValue: SSHShortcutID.commonPorts.rawValue)?.shortcutID == .commonPorts)
    #expect(ISHWorkspaceRoute(rawValue: ISHWorkspaceRoute.library.rawValue) == .library)
  }
}

@Suite("Toolbox workflow")
struct ToolboxWorkflowTests {
  private let webDevice = NetworkDevice(
    address: "192.168.1.20",
    hostname: "server.local",
    openPorts: [22, 80, 443],
    lastSeen: Date()
  )

  @Test("Stages keep the defensive workflow order")
  func stagesKeepDefensiveWorkflowOrder() {
    #expect(ToolboxStage.allCases.map(\.title) == ["Discover", "Inspect", "Verify"])
  }

  @Test("Discovery requires a private network context")
  func discoveryRequiresNetworkContext() {
    #expect(ToolboxAvailability.evaluate(tool: .nativeDiscovery, device: nil, hasNetwork: true).isAvailable)
    #expect(!ToolboxAvailability.evaluate(tool: .nativeDiscovery, device: nil, hasNetwork: false).isAvailable)
  }

  @Test("Host inspection requires a selected device")
  func hostInspectionRequiresSelectedDevice() {
    #expect(ToolboxAvailability.evaluate(tool: .nmapCommonPorts, device: webDevice, hasNetwork: true).isAvailable)
    #expect(!ToolboxAvailability.evaluate(tool: .nmapCommonPorts, device: nil, hasNetwork: true).isAvailable)
  }

  @Test("Service tools use ports from only the selected device")
  func serviceToolsUseSelectedDevicePorts() {
    #expect(ToolboxAvailability.evaluate(tool: .whatWeb, device: webDevice, hasNetwork: true).isAvailable)
    #expect(ToolboxAvailability.evaluate(tool: .sslScan, device: webDevice, hasNetwork: true).isAvailable)
    #expect(!ToolboxAvailability.evaluate(tool: .enum4Linux, device: webDevice, hasNetwork: true).isAvailable)

    let smbDevice = NetworkDevice(
      address: "192.168.1.30",
      hostname: nil,
      openPorts: [445],
      lastSeen: Date()
    )
    #expect(ToolboxAvailability.evaluate(tool: .enum4Linux, device: smbDevice, hasNetwork: true).isAvailable)
    #expect(!ToolboxAvailability.evaluate(tool: .whatWeb, device: smbDevice, hasNetwork: true).isAvailable)
  }
}

final class CipherPathTests: XCTestCase {
  func testPrivateNetworkRecognition() {
    XCTAssertTrue(
      NetworkContext(
        address: "192.168.1.20",
        netmask: "255.255.255.0",
        interfaceName: "en0"
      ).isPrivateOrLinkLocal
    )
    XCTAssertFalse(
      NetworkContext(
        address: "8.8.8.8",
        netmask: "255.255.255.0",
        interfaceName: "en0"
      ).isPrivateOrLinkLocal
    )
  }

  func testLocal24ExcludesCurrentDevice() {
    let context = NetworkContext(
      address: "192.168.4.12",
      netmask: "255.255.255.0",
      interfaceName: "en0"
    )

    XCTAssertEqual(context.hostsInLocal24.count, 253)
    XCTAssertFalse(context.hostsInLocal24.contains("192.168.4.12"))
    XCTAssertTrue(context.hostsInLocal24.contains("192.168.4.1"))
    XCTAssertEqual(context.scanRangeDescription, "192.168.4.0/24")
  }

  func testKnownPortNames() {
    XCTAssertEqual(PortCatalog.name(for: 80), "HTTP")
    XCTAssertEqual(PortCatalog.name(for: 1883), "MQTT")
    XCTAssertEqual(PortCatalog.name(for: 9100), "Drukarka")
  }

  func testTargetNormalization() {
    XCTAssertEqual(
      TargetValidator.normalizedHost("https://example.com/path?q=1"),
      "example.com"
    )
    XCTAssertEqual(
      TargetValidator.normalizedHost("  192.168.1.1  "),
      "192.168.1.1"
    )
    XCTAssertNil(TargetValidator.normalizedHost("not a host"))
  }

  func testPortValidation() {
    XCTAssertEqual(TargetValidator.port("443"), 443)
    XCTAssertNil(TargetValidator.port("0"))
    XCTAssertNil(TargetValidator.port("70000"))
    XCTAssertEqual(
      TargetValidator.customPorts(start: "100", end: "110")?.count,
      11
    )
    XCTAssertEqual(
      TargetValidator.customPorts(start: "1", end: "512")?.count,
      512
    )
    XCTAssertNil(TargetValidator.customPorts(start: "1", end: "513"))
  }

  func testScanProfilesIncreaseCoverage() {
    XCTAssertLessThan(ScanProfile.quick.ports.count, ScanProfile.standard.ports.count)
    XCTAssertLessThan(ScanProfile.standard.ports.count, ScanProfile.extended.ports.count)
  }

  func testDeviceClassificationAndExposure() {
    let printer = NetworkDevice(
      address: "192.168.1.44",
      hostname: "drukarka.local",
      openPorts: [80, 631, 9100],
      lastSeen: Date()
    )
    let remoteDesktop = NetworkDevice(
      address: "192.168.1.55",
      hostname: nil,
      openPorts: [3389],
      lastSeen: Date()
    )

    XCTAssertEqual(printer.kind, .printer)
    XCTAssertEqual(printer.primaryName, "drukarka.local")
    XCTAssertEqual(printer.exposure, .medium)
    XCTAssertEqual(remoteDesktop.kind, .computer)
    XCTAssertEqual(remoteDesktop.exposure, .high)
  }

  func testPortMetadata() {
    XCTAssertTrue(PortCatalog.info(for: 443).isEncrypted)
    XCTAssertFalse(PortCatalog.info(for: 23).isEncrypted)
    XCTAssertEqual(PortCatalog.info(for: 5432).category, "Baza danych")
  }

  func testDeviceProbeTelemetry() {
    let device = NetworkDevice(
      address: "192.168.1.80",
      hostname: nil,
      openPorts: [22, 443],
      lastSeen: Date(),
      portObservations: [
        PortObservation(port: 22, latencyMilliseconds: 12.5),
        PortObservation(port: 443, latencyMilliseconds: 8.2),
      ],
      testedPortCount: 10,
      timedOutPortCount: 3,
      deniedPortCount: 1,
      probeDurationMilliseconds: 640
    )

    XCTAssertEqual(device.closedPortCount, 4)
    XCTAssertEqual(device.latency(for: 443), 8.2)
    XCTAssertEqual(device.testedPortCount, 10)
  }

  func testScanSessionCalculations() {
    let startedAt = Date()
    let details = ScanSessionDetails(
      id: UUID(),
      startedAt: startedAt,
      finishedAt: startedAt.addingTimeInterval(5),
      profile: .quick,
      subnet: "192.168.1.0/24",
      totalHosts: 20,
      portsPerHost: 10,
      completedHosts: 10,
      detectedDevices: 2,
      openPorts: 4,
      timedOutProbes: 10,
      deniedProbes: 2,
      resolvedHostnames: 1
    )

    XCTAssertEqual(details.plannedProbes, 200)
    XCTAssertEqual(details.completedProbes, 100)
    XCTAssertEqual(details.closedProbes, 84)
    XCTAssertEqual(details.progress, 0.5)
    XCTAssertEqual(details.duration, 5, accuracy: 0.01)
  }

  func testScanCompletionReportsLocalNetworkDenial() {
    let phase = ScanCompletion.phase(
      deviceCount: 0,
      completedProbes: 120,
      deniedProbes: 120,
      finishedAt: Date(timeIntervalSince1970: 10)
    )

    XCTAssertEqual(
      phase,
      .failed(
        "Brak dostępu do sieci lokalnej. Włącz go w Ustawieniach iPhone’a: Prywatność i ochrona > Sieć lokalna."
      )
    )
  }

  func testScanCompletionKeepsValidEmptyResult() {
    let finishedAt = Date(timeIntervalSince1970: 20)

    XCTAssertEqual(
      ScanCompletion.phase(
        deviceCount: 0,
        completedProbes: 120,
        deniedProbes: 0,
        finishedAt: finishedAt
      ),
      .finished(finishedAt)
    )
  }

  func testScanStagesHaveStableUserFacingOrder() {
    XCTAssertEqual(
      ScanStage.allCases.map(\.title),
      ["Sieć", "IP i porty", "DNS i usługi", "Wyniki"]
    )
    XCTAssertEqual(ScanStage.network.progress, 0.1)
    XCTAssertEqual(ScanStage.results.progress, 1)
  }

  func testISHTargetValidation() {
    XCTAssertTrue(ISHTargetValidator.isPrivate("192.168.1.0/24"))
    XCTAssertTrue(ISHTargetValidator.isPrivate("172.20.4.5"))
    XCTAssertFalse(ISHTargetValidator.isPrivate("8.8.8.8"))
    XCTAssertFalse(ISHTargetValidator.isPrivate("example.com"))
  }

  func testISHTargetValidationRejectsCIDRPrefixesShorterThanPrivateBlock() {
    XCTAssertFalse(ISHTargetValidator.isPrivate("10.0.0.0/7"))
    XCTAssertTrue(ISHTargetValidator.isPrivate("10.0.0.0/8"))
    XCTAssertFalse(ISHTargetValidator.isPrivate("172.16.0.0/11"))
    XCTAssertTrue(ISHTargetValidator.isPrivate("172.16.0.0/12"))
    XCTAssertFalse(ISHTargetValidator.isPrivate("192.168.0.0/15"))
    XCTAssertTrue(ISHTargetValidator.isPrivate("192.168.0.0/16"))
    XCTAssertFalse(ISHTargetValidator.isPrivate("169.254.0.0/15"))
    XCTAssertTrue(ISHTargetValidator.isPrivate("169.254.0.0/16"))
  }

  func testISHTargetValidationRejectsMalformedCIDRSuffixes() {
    XCTAssertFalse(ISHTargetValidator.isPrivate("10.0.0.0/33"))
    XCTAssertFalse(ISHTargetValidator.isPrivate("10.0.0.0/999"))
    XCTAssertFalse(ISHTargetValidator.isPrivate("10.0.0.0/abc"))
    XCTAssertFalse(ISHTargetValidator.isPrivate("10.0.0.0/"))
    XCTAssertFalse(ISHTargetValidator.isPrivate("10.0.0.0/8/16"))
  }

  func testISHTargetValidationHostOnlyRejectsCIDR() {
    XCTAssertTrue(ISHTargetValidator.isPrivateHost("192.168.1.20"))
    XCTAssertFalse(ISHTargetValidator.isPrivateHost("192.168.1.20/24"))
    XCTAssertFalse(ISHTargetValidator.isPrivateHost("192.168.1.0/24"))
    XCTAssertFalse(ISHTargetValidator.isPrivateHost("8.8.8.8"))
  }

  func testISHCommandUsesUnprivilegedConnectScan() {
    let command = ISHCommandBuilder.command(
      target: "192.168.1.40",
      mode: .serviceDetails,
      knownPorts: [22, 443]
    )

    XCTAssertTrue(command.contains("--unprivileged"))
    XCTAssertTrue(command.contains("-sT"))
    XCTAssertTrue(command.contains("-Pn"))
    XCTAssertTrue(command.contains("-sV --version-light"))
    XCTAssertTrue(command.contains("'22,443'"))
    XCTAssertFalse(command.contains(" -A "))
  }

  func testNmapGuideUsesFiveOrderedAnalyses() {
    XCTAssertEqual(
      NmapGuideStep.allCases.map(\.title),
      [
        "Wykrywanie urządzeń",
        "Nazwy urządzeń",
        "Najważniejsze porty",
        "Rozpoznawanie usług",
        "Dokładna analiza urządzenia",
      ]
    )
    XCTAssertTrue(NmapGuideStep.discovery.isAvailable(hasDevices: true, completedSteps: 0))
    XCTAssertFalse(NmapGuideStep.names.isAvailable(hasDevices: true, completedSteps: 0))
    XCTAssertTrue(NmapGuideStep.names.isAvailable(hasDevices: true, completedSteps: 1))
    XCTAssertFalse(NmapGuideStep.discovery.isAvailable(hasDevices: false, completedSteps: 5))
  }

  func testSSHShortcutCategoriesFollowWorkflowOrder() {
    XCTAssertEqual(
      SSHShortcutCategory.allCases.map(\.title),
      [
        "Połączenie z Maciem",
        "Informacje o sieci",
        "Wykrywanie urządzeń",
        "DNS i nazwy",
        "Porty i usługi",
        "Raporty",
      ]
    )
  }

  func testSSHLoginRequiresUsernameAndHost() {
    let result = SSHShortcutLibrary.resolve(
      .connect,
      context: SSHShortcutContext(username: "", host: "", target: nil)
    )

    XCTAssertEqual(result, .blocked("Uzupełnij użytkownika i host Maca."))
  }

  func testSSHConnectionRejectsShellMetacharacters() {
    let result = SSHShortcutLibrary.resolve(
      .connect,
      context: SSHShortcutContext(username: "user;id", host: "mac.local", target: nil)
    )

    XCTAssertEqual(result, .blocked("Użytkownik lub host zawiera niedozwolone znaki."))
  }

  func testSSHConnectionBuildsStandardURLForExternalClient() {
    let result = SSHShortcutLibrary.connectionURL(
      context: SSHShortcutContext(username: "krystian", host: "MacBook.local", target: nil)
    )

    XCTAssertEqual(result, URL(string: "ssh://krystian@MacBook.local"))
  }

  func testSSHDiscoveryRejectsPublicTarget() {
    let result = SSHShortcutLibrary.resolve(
      .discoverHosts,
      context: SSHShortcutContext(
        username: "krystian",
        host: "mac.local",
        target: "8.8.8.8"
      )
    )

    XCTAssertEqual(result, .blocked("Wybierz prywatny adres lub podsieć."))
  }

  func testSSHShortcutSearchMatchesTitleSummaryAndCategory() {
    let all = SSHShortcutLibrary.shortcuts

    XCTAssertEqual(
      SSHShortcutSearch.filter(all, query: "DNS").map(\.id),
      [.dnsServers, .reverseDNS]
    )
    XCTAssertEqual(
      SSHShortcutSearch.filter(all, query: "raport").map(\.category),
      [.reports, .reports]
    )
    XCTAssertEqual(SSHShortcutSearch.filter(all, query: "").count, all.count)
  }

  func testSSHShortcutSearchLimitsResultsToSelectedCategory() {
    let all = SSHShortcutLibrary.shortcuts

    XCTAssertEqual(
      SSHShortcutSearch.filter(all, category: .ports, query: "").map(\.id),
      [.commonPorts, .serviceVersions, .detailedHost]
    )
    XCTAssertEqual(
      SSHShortcutSearch.filter(all, category: .networkInfo, query: "DNS").map(\.id),
      [.dnsServers]
    )
  }

  func testNmapStepsMapToOrderedSSHShortcuts() {
    XCTAssertEqual(
      NmapGuideStep.allCases.map(\.shortcutID),
      [.discoverHosts, .reverseDNS, .commonPorts, .serviceVersions, .detailedHost]
    )
  }

  func testSSHReverseDNSRejectsSubnetTarget() {
    let result = SSHShortcutLibrary.resolve(
      .reverseDNS,
      context: SSHShortcutContext(
        username: "krystian",
        host: "mac.local",
        target: "192.168.1.0/24"
      )
    )

    XCTAssertEqual(result, .blocked("Wybierz pojedynczy prywatny adres (bez podsieci)."))
  }

  func testSSHReverseDNSAcceptsSingleHostTarget() {
    let result = SSHShortcutLibrary.resolve(
      .reverseDNS,
      context: SSHShortcutContext(
        username: "krystian",
        host: "mac.local",
        target: "192.168.1.20"
      )
    )

    XCTAssertEqual(result, .command("dscacheutil -q host -a ip_address '192.168.1.20'"))
  }
}

@Suite("Known device model")
struct KnownDeviceModelTests {
  @Test("Identity includes network and address")
  func identityIncludesNetworkAndAddress() {
    let home = KnownDeviceKey(networkID: "192.168.1.0/24", address: "192.168.1.20")
    let office = KnownDeviceKey(networkID: "10.0.0.0/24", address: "192.168.1.20")

    #expect(home != office)
  }

  @Test("Custom name takes priority over DNS and inferred kind")
  func customNameTakesPriority() {
    let device = NetworkDevice(
      address: "192.168.1.44",
      hostname: "printer.local",
      openPorts: [631],
      lastSeen: Date(timeIntervalSince1970: 10)
    )
    let record = KnownDeviceRecord(
      id: UUID(),
      key: KnownDeviceKey(networkID: "192.168.1.0/24", address: device.address),
      hostname: device.hostname,
      customName: "Drukarka w biurze",
      trustStatus: .trusted,
      firstSeen: Date(timeIntervalSince1970: 1),
      lastSeen: Date(timeIntervalSince1970: 10),
      openPorts: device.openPorts,
      kind: device.kind
    )

    #expect(device.displayName(using: record) == "Drukarka w biurze")
  }

  @Test("Blank custom name falls back to DNS")
  func blankNameFallsBackToDNS() {
    let device = NetworkDevice(
      address: "192.168.1.44",
      hostname: "printer.local",
      openPorts: [631],
      lastSeen: Date(timeIntervalSince1970: 10)
    )
    let record = KnownDeviceRecord(
      id: UUID(),
      key: KnownDeviceKey(networkID: "192.168.1.0/24", address: device.address),
      hostname: device.hostname,
      customName: "   ",
      trustStatus: .unknown,
      firstSeen: Date(timeIntervalSince1970: 1),
      lastSeen: Date(timeIntervalSince1970: 10),
      openPorts: device.openPorts,
      kind: device.kind
    )

    #expect(device.displayName(using: record) == "printer.local")
  }

  @Test("New status takes priority for current scan")
  func newStatusTakesPriority() {
    let key = KnownDeviceKey(networkID: "home", address: "192.168.1.20")
    let record = KnownDeviceRecord(
      id: UUID(),
      key: key,
      hostname: nil,
      customName: nil,
      trustStatus: .trusted,
      firstSeen: .now,
      lastSeen: .now,
      openPorts: [80],
      kind: .unknown
    )

    #expect(DeviceRegistryStatus(record: record, isNew: true) == .new)
    #expect(DeviceRegistryStatus(record: record, isNew: false) == .trusted)
    #expect(DeviceRegistryStatus(record: nil, isNew: false) == .unknown)
  }

  @Test("Review count includes new and unknown but excludes trusted")
  func reviewCount() {
    let statuses: [DeviceRegistryStatus] = [.new, .unknown, .trusted, .trusted]

    #expect(DeviceRegistryStatus.reviewCount(in: statuses) == 2)
  }
}

@MainActor
@Suite("Known device store")
struct KnownDeviceStoreTests {
  private func temporaryURL() -> URL {
    FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString)
      .appendingPathExtension("json")
  }

  @Test("Merge inserts unknown device and returns its key as new")
  func mergeInsertsUnknownDevice() {
    let url = temporaryURL()
    defer { try? FileManager.default.removeItem(at: url) }
    let store = KnownDeviceStore(fileURL: url)
    let device = NetworkDevice(
      address: "192.168.1.44",
      hostname: "printer.local",
      openPorts: [631],
      lastSeen: Date(timeIntervalSince1970: 10)
    )

    let inserted = store.merge(
      devices: [device],
      networkID: "192.168.1.0/24",
      at: Date(timeIntervalSince1970: 10)
    )

    let key = KnownDeviceKey(networkID: "192.168.1.0/24", address: device.address)
    #expect(inserted == Set([key]))
    #expect(store.records.first?.trustStatus == .unknown)
    #expect(store.records.first?.firstSeen == Date(timeIntervalSince1970: 10))
  }

  @Test("Merge preserves user fields and first seen")
  func mergePreservesUserFields() {
    let url = temporaryURL()
    defer { try? FileManager.default.removeItem(at: url) }
    let store = KnownDeviceStore(fileURL: url)
    let key = KnownDeviceKey(networkID: "192.168.1.0/24", address: "192.168.1.44")
    let first = NetworkDevice(
      address: key.address,
      hostname: "old.local",
      openPorts: [80],
      lastSeen: Date(timeIntervalSince1970: 10)
    )
    store.merge(devices: [first], networkID: key.networkID, at: Date(timeIntervalSince1970: 10))
    store.rename(key, customName: "Salon")
    store.setTrust(key, status: .trusted)

    let updated = NetworkDevice(
      address: key.address,
      hostname: "new.local",
      openPorts: [80, 443],
      lastSeen: Date(timeIntervalSince1970: 20)
    )
    let inserted = store.merge(
      devices: [updated], networkID: key.networkID, at: Date(timeIntervalSince1970: 20)
    )
    let record = store.record(for: updated, networkID: key.networkID)

    #expect(inserted.isEmpty)
    #expect(record?.customName == "Salon")
    #expect(record?.trustStatus == .trusted)
    #expect(record?.firstSeen == Date(timeIntervalSince1970: 10))
    #expect(record?.lastSeen == Date(timeIntervalSince1970: 20))
    #expect(record?.openPorts == [80, 443])
  }

  @Test("Same address on another network creates another record")
  func sameAddressOnAnotherNetwork() {
    let url = temporaryURL()
    defer { try? FileManager.default.removeItem(at: url) }
    let store = KnownDeviceStore(fileURL: url)
    let device = NetworkDevice(
      address: "192.168.1.44",
      hostname: nil,
      openPorts: [80],
      lastSeen: Date(timeIntervalSince1970: 10)
    )

    store.merge(devices: [device], networkID: "home", at: Date(timeIntervalSince1970: 10))
    store.merge(devices: [device], networkID: "office", at: Date(timeIntervalSince1970: 20))

    #expect(store.records.count == 2)
  }

  @Test("Records survive a JSON round trip")
  func persistenceRoundTrip() {
    let url = temporaryURL()
    defer { try? FileManager.default.removeItem(at: url) }
    let device = NetworkDevice(
      address: "192.168.1.20",
      hostname: "mac.local",
      openPorts: [22],
      lastSeen: Date(timeIntervalSince1970: 10)
    )
    let firstStore = KnownDeviceStore(fileURL: url)
    firstStore.merge(devices: [device], networkID: "home", at: Date(timeIntervalSince1970: 10))
    firstStore.rename(KnownDeviceKey(networkID: "home", address: device.address), customName: "Mac")

    let reloaded = KnownDeviceStore(fileURL: url)

    #expect(reloaded.records.count == 1)
    #expect(reloaded.records.first?.customName == "Mac")
  }

  @Test("Corrupt JSON starts an empty registry and reports recovery")
  func corruptJSONRecovery() throws {
    let url = temporaryURL()
    try Data("not-json".utf8).write(to: url)
    defer {
      try? FileManager.default.removeItem(at: url)
      let siblings = try? FileManager.default.contentsOfDirectory(
        at: url.deletingLastPathComponent(),
        includingPropertiesForKeys: nil
      )
      for sibling in siblings ?? []
      where sibling.lastPathComponent.hasPrefix(url.lastPathComponent + ".corrupt-") {
        try? FileManager.default.removeItem(at: sibling)
      }
    }

    let store = KnownDeviceStore(fileURL: url)

    #expect(store.records.isEmpty)
    #expect(store.errorMessage != nil)
  }
}

@MainActor
@Suite("Scanner registry integration")
struct ScannerRegistryIntegrationTests {
  @Test("Completed results merge and expose transient new keys")
  func completedResultsMerge() {
    let url = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString)
      .appendingPathExtension("json")
    defer { try? FileManager.default.removeItem(at: url) }
    let store = KnownDeviceStore(fileURL: url)
    let scanner = NetworkScanner(knownDeviceStore: store)
    let device = NetworkDevice(
      address: "192.168.1.20",
      hostname: nil,
      openPorts: [80],
      lastSeen: Date(timeIntervalSince1970: 10)
    )

    scanner.completeRegistryMerge(
      devices: [device],
      networkID: "192.168.1.0/24",
      at: Date(timeIntervalSince1970: 10)
    )

    let key = KnownDeviceKey(networkID: "192.168.1.0/24", address: device.address)
    #expect(store.records.count == 1)
    #expect(scanner.newDeviceKeys == Set([key]))
  }

  @Test("Creating a scanner does not mutate the registry")
  func scannerCreationDoesNotMerge() {
    let url = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString)
      .appendingPathExtension("json")
    defer { try? FileManager.default.removeItem(at: url) }
    let store = KnownDeviceStore(fileURL: url)

    _ = NetworkScanner(knownDeviceStore: store)

    #expect(store.records.isEmpty)
  }
}
