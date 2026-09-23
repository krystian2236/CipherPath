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

    let parseResult = LabCommandParser.parse(
      input,
      allowedPrograms: definition.allowedPrograms.union(["krg-orbit", "krg-vault"])
    )
    if case .programNotAllowed = parseResult {
      return LabExecutionResult(
        status: .programRejected,
        output: "To polecenie nie jest dostępne w tej misji."
      )
    }
    guard case .command(let command) = parseResult else {
      return LabExecutionResult(
        status: .parseRejected,
        output: "Polecenie zostało odrzucone przez bezpieczny terminal."
      )
    }

    if command == .hiddenOrbit || command == .hiddenVault {
      let expectedTrigger = command == .hiddenOrbit ? "ls -d */" : "ls -d ~/"
      guard isTerminalEasterEgg(definition), session.history.last?.command == expectedTrigger else {
        return LabExecutionResult(
          status: .programRejected,
          output: "To hasło nie jest dostępne w tym miejscu."
        )
      }
      session.isRunning = true
      let output = "RUN\n--- KRG{TERMINAL_BEHIND_THE_SCREEN} ---\nUkryta ścieżka odnaleziona."
      session.history.append(LabTerminalEntry(command: input, output: output))
      return LabExecutionResult(status: .success, output: output)
    }

    guard session.isRunning else {
      return LabExecutionResult(
        status: .machineStopped,
        output: "Powłoka krg jest zatrzymana. Wpisz run."
      )
    }

    if command == .help {
      let programHelp = definition.allowedPrograms.sorted().compactMap(programUsage).joined(separator: "\n")
      let output = """
      help — pokazuje dostępne polecenia
      ip — pokazuje adres celu w symulacji
      clear — czyści historię terminala
      ls [ścieżka] — pokazuje widoczne pliki i katalogi
      ls -la [ścieżka] — pokazuje także ukryte elementy
      cd <katalog> — zmienia katalog roboczy
      Programy misji: \(definition.allowedPrograms.sorted().joined(separator: ", "))
      Składnia programów:
      \(programHelp)
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

    let isNavigationCommand = command.isNavigationCommand
    guard isNavigationCommand || definition.allowedPrograms.contains(command.program) else {
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
    if let rule = definition.rules.first(where: {
      $0.command == command || $0.command == resolvedCommand
    }) {
      return execute(rule, input: input, definition: definition, session: &session)
    }

    if let navigationResult = executeNavigation(
      resolvedCommand,
      input: input,
      definition: definition,
      session: &session
    ) {
      return navigationResult
    }

    return LabExecutionResult(
      status: .noMatchingRule,
      output: "Ta składnia nie prowadzi dalej. Użyj help lub sprawdź cel misji."
    )
  }

  private static func execute(
    _ rule: LabRule,
    input: String,
    definition: LabDefinition,
    session: inout LabSession
  ) -> LabExecutionResult {
    if case .cd(let path) = rule.command {
      session.currentDirectory = normalized(path)
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

  private static func programUsage(_ program: String) -> String? {
    switch program {
    case "ping": "ping <IP>"
    case "nmap": "nmap -sV <IP> lub nmap -sC -sV <IP>"
    case "curl": "curl http://<IP>[:port][/ścieżka]"
    case "ftp": "ftp <IP>"
    case "smbclient": "smbclient -L //<IP> -N"
    case "ssh": "ssh [użytkownik@]<IP>"
    case "cat": "cat <plik>"
    case "sha256sum": "sha256sum <plik>"
    case "find": "find <katalog> -type f lub find <katalog> -name *.log"
    case "id": "id"
    case "whoami": "whoami"
    case "sudo": "sudo -l"
    case "ls", "cd": nil
    default: nil
    }
  }

  private static func executeNavigation(
    _ command: LabCommand,
    input: String,
    definition: LabDefinition,
    session: inout LabSession
  ) -> LabExecutionResult? {
    let filesystem = VirtualFilesystem(definition: definition)
    let output: String

    switch command {
    case .ls(let path):
      guard let listing = filesystem.list(path: path ?? session.currentDirectory, includeHidden: false) else {
        return LabExecutionResult(status: .noMatchingRule, output: "Nie znaleziono takiego katalogu w laboratorium.")
      }
      output = listing
    case .lsAll(let path):
      guard let listing = filesystem.list(path: path ?? session.currentDirectory, includeHidden: true) else {
        return LabExecutionResult(status: .noMatchingRule, output: "Nie znaleziono takiego katalogu w laboratorium.")
      }
      output = listing
    case .lsDirectories(let path):
      guard isTerminalEasterEgg(definition) else {
        return LabExecutionResult(status: .programRejected, output: "To polecenie nie jest dostępne w tej misji.")
      }
      output = path == "*/"
        ? "KRG-ORBIT"
        : "KRG-VAULT"
    case .cd(let path):
      guard filesystem.directories.contains(path) else {
        return LabExecutionResult(status: .noMatchingRule, output: "Nie znaleziono takiego katalogu w laboratorium.")
      }
      session.currentDirectory = path
      output = "Current directory: \(path)"
    default:
      return nil
    }

    session.history.append(LabTerminalEntry(command: input, output: output))
    return LabExecutionResult(status: .success, output: output)
  }

  private static func isTerminalEasterEgg(_ definition: LabDefinition) -> Bool {
    definition.id == "terminal-basics"
  }

  private struct VirtualFilesystem {
    var directories: Set<String> = ["/"]
    var files: Set<String> = []

    init(definition: LabDefinition) {
      for rule in definition.rules {
        switch rule.command {
        case .cat(let path), .sha256sum(let path):
          addFile(path)
        case .find(let arguments):
          if let path = arguments.first { addDirectory(path) }
        case .ls(let path), .lsAll(let path):
          if let path { addDirectory(path) }
        case .cd(let path):
          addDirectory(path)
        default:
          break
        }
      }
    }

    mutating func addFile(_ rawPath: String) {
      let path = LabEngine.absolute(rawPath, from: "/")
      files.insert(path)
      addDirectory(LabEngine.parent(of: path))
    }

    mutating func addDirectory(_ rawPath: String) {
      var path = LabEngine.absolute(rawPath, from: "/")
      while directories.insert(path).inserted, path != "/" {
        path = LabEngine.parent(of: path)
      }
    }

    func list(path rawPath: String, includeHidden: Bool) -> String? {
      let path = LabEngine.normalized(rawPath)
      guard directories.contains(path) else { return nil }

      var entries: [String] = []
      for directory in directories where directory != path && LabEngine.parent(of: directory) == path {
        let name = LabEngine.name(of: directory)
        if includeHidden || !name.hasPrefix(".") { entries.append("\(name)/") }
      }
      for file in files where LabEngine.parent(of: file) == path {
        let name = LabEngine.name(of: file)
        if includeHidden || !name.hasPrefix(".") { entries.append(name) }
      }
      entries.sort()

      if includeHidden {
        entries.insert(contentsOf: [".", ".."], at: 0)
      }
      return entries.isEmpty ? "(brak widocznych plików)" : entries.joined(separator: "\n")
    }
  }

  private static func parent(of rawPath: String) -> String {
    let components = normalized(rawPath).split(separator: "/")
    guard components.count > 1 else { return "/" }
    return "/" + components.dropLast().joined(separator: "/")
  }

  private static func name(of rawPath: String) -> String {
    normalized(rawPath).split(separator: "/").last.map(String.init) ?? "/"
  }

  private static func normalized(_ rawPath: String) -> String {
    var components: [Substring] = []
    for component in rawPath.split(separator: "/", omittingEmptySubsequences: true) {
      switch component {
      case ".":
        continue
      case "..":
        if !components.isEmpty { components.removeLast() }
      default:
        components.append(component)
      }
    }
    return components.isEmpty ? "/" : "/" + components.joined(separator: "/")
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
    case .find(let arguments):
      guard let path = arguments.first else { return command }
      return .find(arguments: [absolute(path, from: currentDirectory)] + arguments.dropFirst())
    default:
      return command
    }
  }

  private static func absolute(_ path: String?, from currentDirectory: String) -> String {
    guard let path, !path.isEmpty else { return currentDirectory }
    if path.hasPrefix("/") { return normalized(path) }
    return normalized(currentDirectory == "/" ? "/\(path)" : "\(currentDirectory)/\(path)")
  }
}

private extension LabCommand {
  var isNavigationCommand: Bool {
    switch self {
    case .ls, .lsAll, .lsDirectories, .cd:
      true
    default:
      false
    }
  }
}
