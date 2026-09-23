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

  var showsGuidance: Bool {
    self == .guided
  }

  var guidanceLabel: String {
    showsGuidance ? "Prowadzony" : "Bez podpowiedzi"
  }
}

enum LabAssistanceLevel: Int, Codable, Comparable, Sendable {
  case none = 0
  case hint = 1
  case solution = 2

  static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

enum LabGrade: String, Codable, Equatable, Sendable {
  case gold = "Złoto"
  case silver = "Srebro"
  case bronze = "Brąz"
}

struct LabReward: Codable, Equatable, Sendable {
  let xp: Int
  let grade: LabGrade

  static func evaluate(mode: LabMode, assistance: LabAssistanceLevel) -> Self {
    switch (mode, assistance) {
    case (.guided, .none): LabReward(xp: 100, grade: .gold)
    case (.guided, .hint): LabReward(xp: 80, grade: .silver)
    case (.guided, .solution): LabReward(xp: 50, grade: .bronze)
    case (.adventure, .none): LabReward(xp: 150, grade: .gold)
    case (.adventure, .hint): LabReward(xp: 120, grade: .silver)
    case (.adventure, .solution): LabReward(xp: 80, grade: .bronze)
    }
  }
}

struct AssistancePurchaseMessage: Equatable, Sendable {
  let result: PointsPurchaseResult
  let purchase: PointsPurchase

  var text: String {
    switch result {
    case .purchased:
      purchase == .hint
        ? "Podpowiedź odblokowana za 20 pkt."
        : "Rozwiązanie odblokowane za 50 pkt."
    case .alreadyUnlocked:
      "Ta pomoc jest już odblokowana."
    case .insufficient(let missing):
      "Brakuje \(missing) pkt, aby odblokować tę pomoc."
    }
  }
}

struct MissionPointsSummary: Equatable, Sendable {
  let reward: Int
  let spent: Int

  var net: Int { reward - spent }

  var text: String {
    "\(reward) − \(spent) = \(net) pkt"
  }
}

struct LabMissionProgress: Codable, Equatable, Sendable {
  var completedModes: Set<LabMode> = []
  var hintUsedModes: Set<LabMode> = []
  var assistanceByMode: [LabMode: LabAssistanceLevel] = [:]
  var xp = 0
  var checkpoints: [LabMode: LabCheckpoint] = [:]

  private enum CodingKeys: String, CodingKey {
    case completedModes
    case hintUsedModes
    case assistanceByMode
    case xp
    case checkpoints
  }

  init() {}

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    completedModes = try container.decodeIfPresent(Set<LabMode>.self, forKey: .completedModes) ?? []
    hintUsedModes = try container.decodeIfPresent(Set<LabMode>.self, forKey: .hintUsedModes) ?? []
    assistanceByMode = try container.decodeIfPresent(
      [LabMode: LabAssistanceLevel].self,
      forKey: .assistanceByMode
    ) ?? Dictionary(uniqueKeysWithValues: hintUsedModes.map { ($0, .hint) })
    xp = try container.decodeIfPresent(Int.self, forKey: .xp) ?? 0
    checkpoints = try container.decodeIfPresent(
      [LabMode: LabCheckpoint].self,
      forKey: .checkpoints
    ) ?? [:]
  }
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
  let answer: String
  let requiredObjectiveIDs: Set<String>

  init(id: String, value: String, answer: String, requiredObjectiveIDs: Set<String> = []) {
    self.id = id
    self.value = value
    self.answer = answer
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
  var currentDirectory = "/"
  var history: [LabTerminalEntry] = []
  var discoveries: [String] = []
  var completedObjectiveIDs: Set<String> = []
  var capturedFlagIDs: [String] = []
}

enum LessonDisplayState: Equatable, Sendable {
  case start
  case active
  case hints(revealed: Int)
  case incorrect
  case stepComplete
  case completed

  enum Event: Equatable, Sendable {
    case begin
    case requestHint
    case revealNextHint
    case incorrectAnswer
    case correctAnswer
    case finishLesson
    case returnToTask
  }

  static func transition(from state: Self, on event: Event) -> Self {
    switch (state, event) {
    case (.start, .begin): .active
    case (.active, .requestHint), (.incorrect, .requestHint): .hints(revealed: 1)
    case (.hints(let revealed), .revealNextHint) where revealed < 2:
      .hints(revealed: revealed + 1)
    case (.active, .incorrectAnswer), (.hints, .incorrectAnswer): .incorrect
    case (.active, .correctAnswer), (.hints, .correctAnswer), (.incorrect, .correctAnswer): .stepComplete
    case (.stepComplete, .finishLesson): .completed
    case (.hints, .returnToTask), (.incorrect, .returnToTask): .active
    default: state
    }
  }

  var revealsSolution: Bool {
    if case .hints(let revealed) = self { return revealed >= 3 }
    return false
  }
}

enum TerminalUnlock: String, Codable, CaseIterable, Sendable {
  case run
  case krg
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
  let revealedAnswer: String?

  init(status: LabExecutionStatus, output: String, revealedAnswer: String? = nil) {
    self.status = status
    self.output = output
    self.revealedAnswer = revealedAnswer
  }
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
    case .hiddenOrbit: "krg-orbit"
    case .hiddenVault: "krg-vault"
    case .ip: "ip"
    case .clear: "clear"
    case .ping: "ping"
    case .nmap: "nmap"
    case .curl: "curl"
    case .ftp: "ftp"
    case .smbclient: "smbclient"
    case .ssh: "ssh"
    case .ls: "ls"
    case .lsAll: "ls"
    case .lsDirectories: "ls"
    case .cd: "cd"
    case .cat: "cat"
    case .sha256sum: "sha256sum"
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
    case .help, .hiddenOrbit, .hiddenVault, .ip, .clear, .ls, .lsAll, .lsDirectories, .cd, .cat, .sha256sum, .find, .id, .whoami, .sudoList:
      return nil
    }
  }
}
