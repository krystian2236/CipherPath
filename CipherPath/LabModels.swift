import Foundation

enum LabMode: String, Codable, CaseIterable, Hashable, Sendable {
  case guided
  case adventure

  var title: String {
    switch self {
    case .guided: "Prowadzony"
    case .adventure: "Przygodowy"
    }
  }

  var xpReward: Int {
    switch self {
    case .guided: 100
    case .adventure: 150
    }
  }
}

struct LabMissionProgress: Codable, Equatable, Sendable {
  var completedModes: Set<LabMode> = []
  var hintUsedModes: Set<LabMode> = []
  var xp = 0
  var checkpoints: [LabMode: LabCheckpoint] = [:]
}

struct LabCheckpoint: Codable, Equatable, Sendable {
  let definitionID: String
  let completedObjectiveIDs: Set<String>
  let capturedFlagIDs: [String]
}

struct LabObjective: Equatable, Sendable {
  let id: String
  let title: String
}

struct LabFlag: Equatable, Sendable {
  let id: String
  let value: String
  let requiredObjectiveIDs: Set<String>

  init(id: String, value: String, requiredObjectiveIDs: Set<String> = []) {
    self.id = id
    self.value = value
    self.requiredObjectiveIDs = requiredObjectiveIDs
  }
}

struct LabRule: Equatable, Sendable {
  let command: LabCommand
  let output: String
  let discovery: String?
  let objectiveID: String?

  init(
    command: LabCommand,
    output: String,
    discovery: String? = nil,
    objectiveID: String? = nil
  ) {
    self.command = command
    self.output = output
    self.discovery = discovery
    self.objectiveID = objectiveID
  }
}

struct LabDefinition: Equatable, Sendable {
  let id: String
  let title: String
  let targetAddress: String
  let allowedPrograms: Set<String>
  let rules: [LabRule]
  let objectives: [LabObjective]
  let flags: [LabFlag]
  let suggestedCommands: [String]
  let defenseSummary: String
}

struct LabTerminalEntry: Equatable, Sendable {
  let command: String
  let output: String
}

struct LabSession: Equatable, Sendable {
  let definitionID: String
  var isRunning = false
  var history: [LabTerminalEntry] = []
  var discoveries: [String] = []
  var completedObjectiveIDs: Set<String> = []
  var capturedFlagIDs: [String] = []
}

enum LabExecutionStatus: Equatable, Sendable {
  case success
  case machineStopped
  case parseRejected
  case programRejected
  case targetRejected
  case noMatchingRule
}

struct LabExecutionResult: Equatable, Sendable {
  let status: LabExecutionStatus
  let output: String
}

enum LabFlagResult: Equatable, Sendable {
  case incorrect
  case locked(requiredObjectiveIDs: [String])
  case accepted(flagID: String)
  case alreadyCaptured(flagID: String)
}

extension LabCommand {
  var program: String {
    switch self {
    case .help: "help"
    case .clear: "clear"
    case .ping: "ping"
    case .nmap: "nmap"
    case .curl: "curl"
    case .ftp: "ftp"
    case .smbclient: "smbclient"
    case .ssh: "ssh"
    case .ls: "ls"
    case .cd: "cd"
    case .cat: "cat"
    case .find: "find"
    case .id: "id"
    case .whoami: "whoami"
    case .sudoList: "sudo"
    }
  }

  var explicitTarget: String? {
    switch self {
    case .ping(let target), .ftp(let target):
      return target
    case .nmap(_, let target):
      return target
    case .curl(let url):
      return URL(string: url)?.host
    case .ssh(let destination):
      return destination.split(separator: "@").last.map(String.init)
    case .smbclient(let arguments):
      guard let share = arguments.first(where: { $0.hasPrefix("//") }) else { return nil }
      return share.dropFirst(2).split(separator: "/").first.map(String.init)
    case .help, .clear, .ls, .cd, .cat, .find, .id, .whoami, .sudoList:
      return nil
    }
  }
}
