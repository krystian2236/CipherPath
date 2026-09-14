import Testing

@testable import CipherPath

@Suite("Starter labs")
struct StarterLabsTests {
  private let networkLessonID = "fundamentals-read-port-scan"
  private let webLessonID = "web-http-anatomy"

  @Test("Maps two different lessons to complete playable labs")
  func mapsTwoCompleteLabs() throws {
    let network = try #require(StarterLabs.definition(for: networkLessonID))
    let web = try #require(StarterLabs.definition(for: webLessonID))

    #expect(network.id != web.id)
    #expect(network.targetAddress != web.targetAddress)
    #expect(network.rules != web.rules)
    #expect(network.flags != web.flags)

    for definition in [network, web] {
      #expect(!definition.title.isEmpty)
      #expect(!definition.allowedPrograms.isEmpty)
      #expect(!definition.rules.isEmpty)
      #expect(!definition.objectives.isEmpty)
      #expect(!definition.flags.isEmpty)
      #expect(!definition.suggestedCommands.isEmpty)
      #expect(!definition.defenseSummary.isEmpty)
    }
  }

  @Test("Every rule stays inside its lab allowlist and virtual target")
  func rulesStayInsideControlledLab() throws {
    let definitions = [
      try #require(StarterLabs.definition(for: networkLessonID)),
      try #require(StarterLabs.definition(for: webLessonID)),
    ]

    for definition in definitions {
      for rule in definition.rules {
        #expect(definition.allowedPrograms.contains(rule.command.program))
        if let target = rule.command.explicitTarget {
          #expect(target == definition.targetAddress)
        }
      }
    }
  }

  @Test("Does not attach a lab to an unrelated lesson")
  func leavesClassicLessonsUnchanged() {
    #expect(StarterLabs.definition(for: "unknown-lesson") == nil)
  }

  @Test("Routes every released lesson to an interactive lab")
  func selectsTheCorrectLessonExperience() throws {
    for lesson in StarterCurriculum.lessons {
      #expect(LessonExperience.resolve(for: lesson) == .interactiveLab)
    }
  }

  @Test("Provides two diverse labs for every learning path")
  func providesCompleteDiverseCatalog() {
    let availableLessons = StarterCurriculum.lessons.filter {
      $0.availability == .available
    }
    let definitions = availableLessons.compactMap(StarterLabs.definition(for:))

    #expect(availableLessons.count == 25)
    #expect(definitions.count == 25)
    #expect(Set(definitions.map(\.id)).count == 25)
    #expect(Set(definitions.map(\.targetAddress)).count == definitions.count)
    #expect(Set(definitions.map(\.allowedPrograms)).count >= 5)
    #expect(definitions.contains { $0.flags.count == 2 })

    for path in LearningPath.allCases {
      let pathDefinitions = StarterCurriculum.lessons(in: path)
        .filter { $0.availability == .available }
        .compactMap(StarterLabs.definition(for:))
      #expect(pathDefinitions.count == 5)
    }
  }

  @Test("Completes the catalog with headers, privacy, and release review labs")
  func addsFinalThreeLabs() throws {
    let headers = try #require(
      StarterLabs.definition(for: "web-security-headers")
    )
    let privacy = try #require(
      StarterLabs.definition(for: "mobile-app-privacy")
    )
    let release = try #require(
      StarterLabs.definition(for: "mobile-release-review")
    )

    #expect(headers.allowedPrograms == ["curl"])
    #expect(headers.rules.contains { $0.output.contains("Strict-Transport-Security: missing") })
    #expect(privacy.rules.contains { $0.output.contains("PrivacyInfo.xcprivacy") })
    #expect(release.allowedPrograms.contains("sha256sum"))
    #expect(release.flags.first?.answer == "Wydanie spełnia kompletną listę kontroli")
  }

  @Test("Adds evidence, response, reporting, and access-control investigations")
  func addsNextFourLessonPackage() throws {
    let evidence = try #require(
      StarterLabs.definition(for: "fundamentals-security-evidence")
    )
    let response = try #require(
      StarterLabs.definition(for: "blue-team-incident-notes")
    )
    let report = try #require(
      StarterLabs.definition(for: "red-team-defensive-report")
    )
    let access = try #require(
      StarterLabs.definition(for: "web-access-control")
    )

    #expect(evidence.allowedPrograms.contains("sha256sum"))
    #expect(evidence.allowedPrograms.contains("ls"))
    #expect(evidence.rules.contains {
      $0.command == .ls(path: "/case") && $0.output.contains("notes")
    })
    #expect(evidence.rules.contains {
      $0.command == .lsAll(path: "/case/notes") && $0.output.contains(".template.txt")
    })
    #expect(evidence.suggestedCommands.first == "ls /case")
    #expect(response.rules.contains { $0.output.contains("isolate after preserve") })
    #expect(report.flags.first?.answer == "Raport łączy dowód, wpływ i naprawę")
    #expect(access.allowedPrograms == ["curl"])
    #expect(access.rules.contains { $0.output.contains("viewer=200 admin-record") })
  }

  @Test("Adds four distinct guided investigations to the Pro catalog")
  func addsFourLessonPackage() throws {
    let terminal = try #require(
      StarterLabs.definition(for: "fundamentals-terminal-basics")
    )
    let baseline = try #require(
      StarterLabs.definition(for: "blue-team-network-baseline")
    )
    let riskChain = try #require(
      StarterLabs.definition(for: "red-team-risk-chain")
    )
    let transport = try #require(
      StarterLabs.definition(for: "mobile-transport-security")
    )

    #expect(terminal.suggestedCommands == ["ls", "cd training", "ls", "cat briefing.txt"])
    #expect(baseline.rules.contains { $0.output.contains("unexpected=8443/tcp") })
    #expect(riskChain.flags.first?.answer == "Trzy słabości tworzą jedną ścieżkę ryzyka")
    #expect(transport.allowedPrograms == ["cat", "curl"])
    #expect(transport.rules.contains { $0.output.contains("NSAllowsArbitraryLoads=true") })
  }

  @Test("Discovers the training files from the shell root")
  func discoversTrainingFilesWithRelativeCommands() throws {
    let terminal = try #require(
      StarterLabs.definition(for: "fundamentals-terminal-basics")
    )
    var session = LabSession(definitionID: terminal.id)

    _ = LabEngine.execute("run", definition: terminal, session: &session)
    let root = LabEngine.execute("ls", definition: terminal, session: &session)
    let change = LabEngine.execute("cd training", definition: terminal, session: &session)
    let training = LabEngine.execute("ls", definition: terminal, session: &session)
    let briefing = LabEngine.execute("cat briefing.txt", definition: terminal, session: &session)

    #expect(root.output == "training/")
    #expect(change.status == .success)
    #expect(session.currentDirectory == "/training")
    #expect(training.output.contains("briefing.txt"))
    #expect(briefing.revealedAnswer == "Najpierw odczytaj, potem działaj")
  }

  @Test("Adds a file integrity investigation and an HTTP session review")
  func addsTwoDistinctProLabs() throws {
    let integrity = try #require(StarterLabs.definition(for: "blue-team-file-integrity"))
    let session = try #require(StarterLabs.definition(for: "web-session-basics"))

    #expect(integrity.allowedPrograms.contains("sha256sum"))
    #expect(integrity.suggestedCommands.contains("sha256sum /evidence/app.bin"))
    #expect(session.allowedPrograms == ["curl"])
    #expect(session.rules.contains { $0.output.contains("Set-Cookie:") })
    #expect(integrity.flags.first?.answer == "Plik aplikacji został zmieniony")
    #expect(session.flags.first?.answer == "Ciasteczko sesji wymaga Secure i HttpOnly")
  }

  @Test("Adds private address analysis and scoped SMB reconnaissance")
  func addsNextTwoProLabs() throws {
    let addresses = try #require(
      StarterLabs.definition(for: "fundamentals-network-addresses")
    )
    let reconnaissance = try #require(
      StarterLabs.definition(for: "red-team-owned-lab-recon")
    )

    #expect(addresses.allowedPrograms == ["cat"])
    #expect(addresses.rules.contains { $0.output.contains("10.0.0.0/8") })
    #expect(reconnaissance.allowedPrograms.contains("smbclient"))
    #expect(reconnaissance.suggestedCommands.contains("smbclient -L //192.0.2.32 -N"))
    #expect(addresses.flags.first?.answer == "Zakresy RFC1918 są prywatne")
    #expect(reconnaissance.flags.first?.answer == "Udział audit jest dostępny anonimowo")
  }

  @Test("Every lab has reachable flags, valid objectives, and safe suggestions")
  func validatesCatalogIntegrity() {
    for definition in StarterLabs.all {
      let objectiveIDs = Set(definition.objectives.map(\.id))
      let ruleObjectiveIDs = Set(definition.rules.compactMap(\.objectiveID))

      #expect(definition.targetAddress.hasPrefix("192.0.2."))
      #expect(Set(definition.flags.map(\.id)).count == definition.flags.count)
      #expect(ruleObjectiveIDs.isSubset(of: objectiveIDs))

      for flag in definition.flags {
        #expect(flag.requiredObjectiveIDs.isSubset(of: objectiveIDs))
        #expect(definition.rules.contains { $0.output.contains(flag.value) })
      }

      var session = LabSession(definitionID: definition.id)
      LabEngine.start(session: &session)
      for suggestion in definition.suggestedCommands {
        guard case .command(let command) = LabCommandParser.parse(suggestion) else {
          Issue.record("Nieprawidłowa podpowiedź: \(suggestion)")
          continue
        }
        #expect(definition.allowedPrograms.contains(command.program))
        #expect(
          LabEngine.execute(suggestion, definition: definition, session: &session).status
            == .success
        )
      }
    }
  }
}
