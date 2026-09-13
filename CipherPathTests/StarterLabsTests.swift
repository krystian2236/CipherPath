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
    #expect(StarterLabs.definition(for: "blue-team-file-integrity") == nil)
  }

  @Test("Routes mapped lessons to a lab and keeps other lessons classic")
  func selectsTheCorrectLessonExperience() throws {
    let labLesson = try #require(
      StarterCurriculum.lessons.first { $0.id == networkLessonID }
    )
    let classicLesson = try #require(
      StarterCurriculum.lessons.first { $0.id == "blue-team-file-integrity" }
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

    #expect(availableLessons.count == 10)
    #expect(definitions.count == 10)
    #expect(Set(definitions.map(\.id)).count == 10)
    #expect(Set(definitions.map(\.allowedPrograms)).count >= 5)
    #expect(definitions.contains { $0.flags.count == 2 })

    for path in LearningPath.allCases {
      let pathDefinitions = StarterCurriculum.lessons(in: path)
        .filter { $0.availability == .available }
        .compactMap(StarterLabs.definition(for:))
      #expect(pathDefinitions.count == 2)
    }
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
