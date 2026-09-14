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
    guard session.definitionID == definition.id else {
      return LabExecutionResult(
        status: .machineStopped,
        output: "Ta sesja nie pasuje do wybranego laboratorium."
      )
    }

    let parseResult = LabCommandParser.parse(input)
    guard case .command(let command) = parseResult else {
      return LabExecutionResult(
        status: .parseRejected,
        output: "Polecenie zostało odrzucone przez bezpieczny terminal."
      )
    }

    if command == .run {
      let output: String
      if session.isRunning {
        output = "Jeśli chcesz uzyskać pomoc, wpisz krg -help."
      } else {
        session.isRunning = true
        session.history.removeAll()
        output = "Jeśli chcesz uzyskać pomoc, wpisz krg -help."
      }
      return LabExecutionResult(status: .success, output: output)
    }

    guard session.isRunning else {
      return LabExecutionResult(
        status: .machineStopped,
        output: "Powłoka krg jest zatrzymana. Wpisz run."
      )
    }

    if command == .help {
      let output = """
      krg -help — pokazuje dostępne polecenia
      ip — pokazuje adres celu w symulacji
      clear — czyści historię terminala
      Programy misji: \(definition.allowedPrograms.sorted().joined(separator: ", "))
      """
      session.history.append(LabTerminalEntry(command: input, output: output))
      return LabExecutionResult(status: .success, output: output)
    }

    if command == .ip {
      let output = "lab0: \(definition.targetAddress)\nnetwork: offline simulation"
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

    let resolvedCommand = resolve(command, from: session.currentDirectory)
    guard let rule = definition.rules.first(where: {
      $0.command == command || $0.command == resolvedCommand
    }) else {
      return LabExecutionResult(
        status: .noMatchingRule,
        output: "Ta składnia nie prowadzi dalej. Użyj krg -help lub sprawdź cel misji."
      )
    }

    if case .cd(let path) = rule.command {
      session.currentDirectory = path
    }

    let revealedFlag = definition.flags.first { rule.output.contains($0.value) }
    let readableOutput = revealedFlag.map {
      rule.output.replacingOccurrences(
        of: $0.value,
        with: "[✓] ❯ Odpowiedź: \($0.answer)"
      )
    } ?? rule.output
    session.history.append(LabTerminalEntry(command: input, output: readableOutput))
    if let discovery = rule.discovery, !session.discoveries.contains(discovery) {
      session.discoveries.append(discovery)
    }
    if let objectiveID = rule.objectiveID {
      session.completedObjectiveIDs.insert(objectiveID)
    }
    return LabExecutionResult(
      status: .success,
      output: readableOutput,
      revealedAnswer: revealedFlag?.answer
    )
  }

  static func submit(
    answer input: String,
    definition: LabDefinition,
    session: inout LabSession
  ) -> LabFlagResult {
    guard session.isRunning, session.definitionID == definition.id else {
      return .incorrect
    }

    let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let flag = definition.flags.first(where: {
      $0.answer.caseInsensitiveCompare(normalized) == .orderedSame
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

  private static func resolve(_ command: LabCommand, from currentDirectory: String) -> LabCommand {
    switch command {
    case .ls(let path):
      return .ls(path: absolute(path, from: currentDirectory))
    case .lsAll(let path):
      return .lsAll(path: absolute(path, from: currentDirectory))
    case .cd(let path):
      return .cd(path: absolute(path, from: currentDirectory))
    case .cat(let path):
      return .cat(path: absolute(path, from: currentDirectory))
    case .sha256sum(let path):
      return .sha256sum(path: absolute(path, from: currentDirectory))
    default:
      return command
    }
  }

  private static func absolute(_ path: String?, from currentDirectory: String) -> String {
    guard let path, !path.isEmpty else { return currentDirectory }
    if path.hasPrefix("/") { return path }
    return currentDirectory == "/" ? "/\(path)" : "\(currentDirectory)/\(path)"
  }
}
