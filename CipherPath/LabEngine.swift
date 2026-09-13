import Foundation

enum LabEngine {
  static func start(session: inout LabSession) {
    session.isRunning = true
  }

  static func execute(
    _ input: String,
    definition: LabDefinition,
    session: inout LabSession
  ) -> LabExecutionResult {
    guard session.isRunning, session.definitionID == definition.id else {
      return LabExecutionResult(
        status: .machineStopped,
        output: "Najpierw uruchom wirtualną maszynę."
      )
    }

    let parseResult = LabCommandParser.parse(input)
    guard case .command(let command) = parseResult else {
      return LabExecutionResult(
        status: .parseRejected,
        output: "Polecenie zostało odrzucone przez bezpieczny terminal."
      )
    }

    if command == .help {
      let output = "Dostępne polecenia: \(definition.allowedPrograms.sorted().joined(separator: ", "))"
      session.history.append(LabTerminalEntry(command: input, output: output))
      return LabExecutionResult(status: .success, output: output)
    }

    if command == .clear {
      session.history.removeAll()
      return LabExecutionResult(status: .success, output: "")
    }

    guard definition.allowedPrograms.contains(command.program) else {
      return LabExecutionResult(
        status: .programRejected,
        output: "To polecenie nie jest dostępne w tej misji."
      )
    }

    if let target = command.explicitTarget, target != definition.targetAddress {
      return LabExecutionResult(
        status: .targetRejected,
        output: "Możesz pracować wyłącznie z wirtualnym celem tej misji."
      )
    }

    guard let rule = definition.rules.first(where: { $0.command == command }) else {
      return LabExecutionResult(
        status: .noMatchingRule,
        output: "Ta składnia nie prowadzi dalej. Użyj help lub sprawdź cel misji."
      )
    }

    session.history.append(LabTerminalEntry(command: input, output: rule.output))
    if let discovery = rule.discovery, !session.discoveries.contains(discovery) {
      session.discoveries.append(discovery)
    }
    if let objectiveID = rule.objectiveID {
      session.completedObjectiveIDs.insert(objectiveID)
    }
    return LabExecutionResult(status: .success, output: rule.output)
  }

  static func submit(
    flag input: String,
    definition: LabDefinition,
    session: inout LabSession
  ) -> LabFlagResult {
    guard session.isRunning, session.definitionID == definition.id else {
      return .incorrect
    }

    let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let flag = definition.flags.first(where: {
      $0.value.caseInsensitiveCompare(normalized) == .orderedSame
    }) else {
      return .incorrect
    }

    let missingObjectives = flag.requiredObjectiveIDs.subtracting(session.completedObjectiveIDs)
    guard missingObjectives.isEmpty else {
      return .locked(requiredObjectiveIDs: missingObjectives.sorted())
    }

    guard !session.capturedFlagIDs.contains(flag.id) else {
      return .alreadyCaptured(flagID: flag.id)
    }

    session.capturedFlagIDs.append(flag.id)
    return .accepted(flagID: flag.id)
  }
}
