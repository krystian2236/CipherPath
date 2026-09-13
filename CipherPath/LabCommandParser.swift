import Foundation

enum LabCommand: Equatable, Sendable {
  case help
  case clear
  case ping(target: String)
  case nmap(options: [String], target: String)
  case curl(url: String)
  case ftp(target: String)
  case smbclient(arguments: [String])
  case ssh(destination: String)
  case ls(path: String?)
  case cd(path: String)
  case cat(path: String)
  case find(arguments: [String])
  case id
  case whoami
  case sudoList
}

enum LabCommandParseResult: Equatable, Sendable {
  case command(LabCommand)
  case rejected(String)

  var isRejected: Bool {
    if case .rejected = self { return true }
    return false
  }
}

enum LabCommandParser {
  private static let forbiddenCharacters = CharacterSet(charactersIn: ";|&><`$()")

  static func parse(_ input: String) -> LabCommandParseResult {
    guard input.rangeOfCharacter(from: forbiddenCharacters) == nil else {
      return .rejected("Operatory powłoki nie są dostępne w laboratorium.")
    }

    let tokens = input.split(whereSeparator: \Character.isWhitespace).map(String.init)
    guard let program = tokens.first else {
      return .rejected("Wpisz polecenie lub użyj help.")
    }

    let arguments = Array(tokens.dropFirst())
    switch program.lowercased() {
    case "help" where arguments.isEmpty:
      return .command(.help)
    case "clear" where arguments.isEmpty:
      return .command(.clear)
    case "ping" where arguments.count == 1:
      return .command(.ping(target: arguments[0]))
    case "nmap" where !arguments.isEmpty:
      return .command(.nmap(options: Array(arguments.dropLast()), target: arguments.last!))
    case "curl" where arguments.count == 1:
      return .command(.curl(url: arguments[0]))
    case "ftp" where arguments.count == 1:
      return .command(.ftp(target: arguments[0]))
    case "smbclient" where !arguments.isEmpty:
      return .command(.smbclient(arguments: arguments))
    case "ssh" where arguments.count == 1:
      return .command(.ssh(destination: arguments[0]))
    case "ls" where arguments.count <= 1:
      return .command(.ls(path: arguments.first))
    case "cd" where arguments.count == 1:
      return .command(.cd(path: arguments[0]))
    case "cat" where arguments.count == 1:
      return .command(.cat(path: arguments[0]))
    case "find" where !arguments.isEmpty:
      return .command(.find(arguments: arguments))
    case "id" where arguments.isEmpty:
      return .command(.id)
    case "whoami" where arguments.isEmpty:
      return .command(.whoami)
    case "sudo" where arguments == ["-l"]:
      return .command(.sudoList)
    default:
      return .rejected("Polecenie nie jest dostępne w tym laboratorium.")
    }
  }
}
