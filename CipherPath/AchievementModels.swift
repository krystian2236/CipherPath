import Foundation

enum AchievementID: String, CaseIterable, Codable, Sendable {
  case firstFlag
  case withoutHints
  case labMaster
  case networkScout
  case blueTeamAnalyst
  case redTeamOperator
  case webDefender
  case mobileGuardian
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
        title: "Pierwsza odpowiedź",
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
    case .networkScout:
      categoryAchievement(
        id: id,
        title: "Zwiadowca sieci",
        requirement: "Ukończ 2 lekcje ze ścieżki Podstawy",
        rarity: .bronze,
        progress: progress,
        prefix: "fundamentals-",
        target: 2
      )
    case .blueTeamAnalyst:
      categoryAchievement(
        id: id,
        title: "Analityk Blue Team",
        requirement: "Ukończ 2 lekcje Blue Team",
        rarity: .silver,
        progress: progress,
        prefix: "blue-team-",
        target: 2
      )
    case .redTeamOperator:
      categoryAchievement(
        id: id,
        title: "Operator Red Team",
        requirement: "Ukończ 2 lekcje Red Team",
        rarity: .silver,
        progress: progress,
        prefix: "red-team-",
        target: 2
      )
    case .webDefender:
      categoryAchievement(
        id: id,
        title: "Obrońca aplikacji Web",
        requirement: "Ukończ 2 lekcje bezpieczeństwa Web",
        rarity: .silver,
        progress: progress,
        prefix: "web-",
        target: 2
      )
    case .mobileGuardian:
      categoryAchievement(
        id: id,
        title: "Strażnik mobile",
        requirement: "Ukończ 2 lekcje bezpieczeństwa mobile",
        rarity: .gold,
        progress: progress,
        prefix: "mobile-",
        target: 2
      )
    }
  }

  private static func categoryAchievement(
    id: AchievementID,
    title: String,
    requirement: String,
    rarity: AchievementRarity,
    progress: LearningProgress,
    prefix: String,
    target: Int
  ) -> AchievementProgress {
    let current = progress.labMissions.filter { lessonID, mission in
      lessonID.hasPrefix(prefix) && mission.completedModes.contains(.guided)
    }.count
    return AchievementProgress(
      id: id,
      title: title,
      requirement: requirement,
      rarity: rarity,
      current: min(current, target),
      target: target
    )
  }

  static func evaluateAll(_ progress: LearningProgress) -> [AchievementProgress] {
    AchievementID.allCases.map { evaluate(progress, id: $0) }
  }
}
