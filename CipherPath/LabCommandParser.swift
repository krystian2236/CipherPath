import Foundation

enum LabCommand: Equatable, Sendable {
  case help
  case run
  case ip
  case clear
  case ping(target: String)
  case nmap(options: [String], target: String)
  case curl(url: String)
  case ftp(target: String)
  case smbclient(arguments: [String])
  case ssh(destination: String)
  case ls(path: String?)
  case lsAll(path: String?)
  case cd(path: String)
  case cat(path: String)
  case sha256sum(path: String)
  case find(arguments: [String])
  case id
  case whoami
  case sudoList
}

enum LabCommandParseResult: Equatable, Sendable {
  case command(LabCommand)
  case programNotAllowed
  case rejected(String)

  var isRejected: Bool {
    switch self {
    case .programNotAllowed, .rejected:
      return true
    case .command:
      return false
    }
  }
}

enum LabCommandParser {
  private static let forbiddenCharacters = CharacterSet(charactersIn: ";|&><`$()")

  static func parse(
    _ input: String,
    allowedPrograms: Set<String>? = nil
  ) -> LabCommandParseResult {
    guard input.rangeOfCharacter(from: forbiddenCharacters) == nil else {
      return .rejected("Operatory powłoki nie są dostępne w laboratorium.")
    }

    let tokens = input.split(whereSeparator: \Character.isWhitespace).map(String.init)
    guard let program = tokens.first else {
      return .rejected("Wpisz polecenie. Po uruchomieniu użyj krg -help.")
    }

    let arguments = Array(tokens.dropFirst())
    let result: LabCommandParseResult
    switch program.lowercased() {
    case "krg" where arguments == ["-help"] || arguments == ["--help"]:
      result = .command(.help)
    case "run" where arguments.isEmpty:
      result = .command(.run)
    case "ip" where arguments.isEmpty:
      result = .command(.ip)
    case "clear" where arguments.isEmpty:
      result = .command(.clear)
    case "ping" where arguments.count == 1:
      result = .command(.ping(target: arguments[0]))
    case "nmap" where !arguments.isEmpty:
      result = .command(.nmap(options: Array(arguments.dropLast()), target: arguments.last!))
    case "curl" where arguments.count == 1:
      result = .command(.curl(url: arguments[0]))
    case "ftp" where arguments.count == 1:
      result = .command(.ftp(target: arguments[0]))
    case "smbclient" where !arguments.isEmpty:
      result = .command(.smbclient(arguments: arguments))
    case "ssh" where arguments.count == 1:
      result = .command(.ssh(destination: arguments[0]))
    case "ls" where arguments.first == "-la" && arguments.count <= 2:
      result = .command(.lsAll(path: arguments.count == 2 ? arguments[1] : nil))
    case "ls" where arguments.count <= 1:
      result = .command(.ls(path: arguments.first))
    case "cd" where arguments.count == 1:
      result = .command(.cd(path: arguments[0]))
    case "cat" where arguments.count == 1:
      result = .command(.cat(path: arguments[0]))
    case "sha256sum" where arguments.count == 1:
      result = .command(.sha256sum(path: arguments[0]))
    case "find" where !arguments.isEmpty:
      result = .command(.find(arguments: arguments))
    case "id" where arguments.isEmpty:
      result = .command(.id)
    case "whoami" where arguments.isEmpty:
      result = .command(.whoami)
    case "sudo" where arguments == ["-l"]:
      result = .command(.sudoList)
    default:
      result = .rejected("Polecenie nie jest dostępne w tym laboratorium.")
    }

    guard case .command(let command) = result, let allowedPrograms else {
      return result
    }

    let builtInPrograms: Set<String> = ["help", "run", "ip", "clear", "ls", "cd"]
    guard builtInPrograms.contains(command.program) || allowedPrograms.contains(command.program) else {
      return .programNotAllowed
    }

    return result
  }
}
