import Foundation

enum AchievementID: String, CaseIterable, Codable, Sendable {
  case firstFlag
  case withoutHints
  case labMaster
}

enum AchievementRarity: String, Codable, Sendable {
  case bronze = "Łatwe"
  case silver = "Średnie"
  case gold = "Trudne"
}

struct AchievementProgress: Equatable, Sendable {
  let id: AchievementID
  let title: String
  let requirement: String
  let rarity: AchievementRarity
  let current: Int
  let target: Int

  var isUnlocked: Bool { current >= target }
}

enum AchievementCatalog {
  static func evaluate(_ progress: LearningProgress, id: AchievementID) -> AchievementProgress {
    let guidedCount = progress.labMissions.values.filter {
      $0.completedModes.contains(.guided)
    }.count
    let independentCount = progress.labMissions.values.filter {
      $0.completedModes.contains(.adventure) && !$0.hintUsedModes.contains(.adventure)
    }.count

    switch id {
    case .firstFlag:
      return AchievementProgress(
        id: id,
        title: "Pierwsza flaga",
        requirement: "Ukończ pierwsze laboratorium",
        rarity: .bronze,
        current: min(guidedCount, 1),
        target: 1
      )
    case .withoutHints:
      return AchievementProgress(
        id: id,
        title: "Bez podpowiedzi",
        requirement: "Ukończ tryb przygodowy bez podpowiedzi",
        rarity: .silver,
        current: min(independentCount, 1),
        target: 1
      )
    case .labMaster:
      return AchievementProgress(
        id: id,
        title: "Mistrz laboratoriów",
        requirement: "Ukończ 10 laboratoriów prowadzonych",
        rarity: .gold,
        current: min(guidedCount, 10),
        target: 10
      )
    }
  }

  static func evaluateAll(_ progress: LearningProgress) -> [AchievementProgress] {
    AchievementID.allCases.map { evaluate(progress, id: $0) }
  }
}
