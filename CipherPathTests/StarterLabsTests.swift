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
    #expect(StarterLabs.definition(for: "blue-team-incident-notes") == nil)
  }

  @Test("Routes mapped lessons to a lab and keeps other lessons classic")
  func selectsTheCorrectLessonExperience() throws {
    let labLesson = try #require(
      StarterCurriculum.lessons.first { $0.id == networkLessonID }
    )
    let classicLesson = try #require(
      StarterCurriculum.lessons.first { $0.id == "blue-team-incident-notes" }
    )

    #expect(LessonExperience.resolve(for: labLesson) == .interactiveLab)
    #expect(LessonExperience.resolve(for: classicLesson) == .classic)
  }

  @Test("Provides two diverse labs for every learning path")
  func providesCompleteDiverseCatalog() {
    let availableLessons = StarterCurriculum.lessons.filter {
      $0.availability == .available
    }
    let definitions = availableLessons.compactMap(StarterLabs.definition(for:))

    #expect(availableLessons.count == 18)
    #expect(definitions.count == 18)
    #expect(Set(definitions.map(\.id)).count == 18)
    #expect(Set(definitions.map(\.allowedPrograms)).count >= 5)
    #expect(definitions.contains { $0.flags.count == 2 })

    for path in LearningPath.allCases {
      let pathDefinitions = StarterCurriculum.lessons(in: path)
        .filter { $0.availability == .available }
        .compactMap(StarterLabs.definition(for:))
      let expectedCount = path == .webSecurity ? 3 : (path == .mobileSecurity ? 3 : 4)
      #expect(pathDefinitions.count == expectedCount)
    }
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

    #expect(terminal.suggestedCommands == ["ls /training", "cd /training", "cat briefing.txt"])
    #expect(baseline.rules.contains { $0.output.contains("unexpected=8443/tcp") })
    #expect(riskChain.flags.first?.answer == "Trzy słabości tworzą jedną ścieżkę ryzyka")
    #expect(transport.allowedPrograms == ["cat", "curl"])
    #expect(transport.rules.contains { $0.output.contains("NSAllowsArbitraryLoads=true") })
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

      for suggestion in definition.suggestedCommands {
        guard case .command(let command) = LabCommandParser.parse(suggestion) else {
          Issue.record("Nieprawidłowa podpowiedź: \(suggestion)")
          continue
        }
        #expect(definition.rules.contains { $0.command == command })
      }
    }
  }
}
