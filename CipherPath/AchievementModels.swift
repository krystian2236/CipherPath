import Foundation

enum AchievementID: String, CaseIterable, Codable, Sendable {
  case firstFlag
  case withoutHints
  case halfwayThere
  case perfectionist
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
  /// Number of currently released lessons; achievement targets scale with this
  /// so difficulty stays proportional to the actual catalog size.
  static var totalAvailableLessons: Int {
    StarterCurriculum.lessons.filter { $0.availability == .available }.count
  }

  private static func half(_ total: Int) -> Int {
    max(1, Int((Double(total) / 2).rounded(.up)))
  }

  static func evaluate(_ progress: LearningProgress, id: AchievementID) -> AchievementProgress {
    let total = totalAvailableLessons
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
    case .halfwayThere:
      let target = half(total)
      return AchievementProgress(
        id: id,
        title: "W połowie drogi",
        requirement: "Ukończ połowę dostępnych laboratoriów prowadzonych (\(target))",
        rarity: .silver,
        current: min(guidedCount, target),
        target: target
      )
    case .perfectionist:
      let target = half(total)
      return AchievementProgress(
        id: id,
        title: "Perfekcjonista",
        requirement: "Ukończ połowę dostępnych laboratoriów w trybie przygodowym bez podpowiedzi (\(target))",
        rarity: .gold,
        current: min(independentCount, target),
        target: target
      )
    case .labMaster:
      return AchievementProgress(
        id: id,
        title: "Mistrz laboratoriów",
        requirement: "Ukończ wszystkie dostępne laboratoria prowadzone (\(total))",
        rarity: .gold,
        current: min(guidedCount, total),
        target: total
      )
    }
  }

  static func evaluateAll(_ progress: LearningProgress) -> [AchievementProgress] {
    AchievementID.allCases.map { evaluate(progress, id: $0) }
  }
}
