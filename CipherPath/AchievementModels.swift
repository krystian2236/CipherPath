import Foundation

enum AchievementID: String, CaseIterable, Codable, Sendable {
  case firstFlag
  case withoutHints
  case labMaster
  case firstLesson
  case fiveLabs
  case completedPath
  case sevenDayStreak
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

struct LearningPathProgressSummary: Identifiable, Equatable, Sendable {
  let path: LearningPath
  let completedLessons: Int
  let availableLessons: Int
  let completedLabs: Int
  let xp: Int

  var id: LearningPath { path }

  static func make(
    for path: LearningPath,
    progress: LearningProgress,
    policy: ContentAccessPolicy
  ) -> Self {
    let lessons = StarterCurriculum.lessons(in: path).filter {
      policy.access(for: $0) == .included
    }
    let completedLessons = lessons.filter {
      progress.completedStages[$0.id, default: []].count == $0.stages.count
    }.count
    let completedLabs = lessons.filter {
      progress.labMissions[$0.id]?.completedModes.isEmpty == false
    }.count
    let xp = lessons.reduce(0) {
      $0 + (progress.labMissions[$1.id]?.xp ?? 0)
    }
    return LearningPathProgressSummary(
      path: path,
      completedLessons: completedLessons,
      availableLessons: lessons.count,
      completedLabs: completedLabs,
      xp: xp
    )
  }
}

enum AchievementCatalog {
  static func evaluate(_ progress: LearningProgress, id: AchievementID) -> AchievementProgress {
    let guidedCount = progress.labMissions.values.filter {
      $0.completedModes.contains(.guided)
    }.count
    let independentCount = progress.labMissions.values.filter {
      $0.completedModes.contains(.adventure) && !$0.hintUsedModes.contains(.adventure)
    }.count
    let completedLessons = StarterCurriculum.lessons.filter {
      progress.completedStages[$0.id, default: []].count == $0.stages.count
    }.count
    let completedPaths = LearningPath.allCases.filter { path in
      let lessons = StarterCurriculum.lessons(in: path)
      return !lessons.isEmpty && lessons.allSatisfy {
        progress.completedStages[$0.id, default: []].count == $0.stages.count
      }
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
    case .firstLesson:
      return AchievementProgress(
        id: id, title: "Pierwsza lekcja", requirement: "Ukończ pierwszą lekcję",
        rarity: .bronze, current: min(completedLessons, 1), target: 1
      )
    case .fiveLabs:
      return AchievementProgress(
        id: id, title: "Pięć laboratoriów", requirement: "Ukończ 5 laboratoriów",
        rarity: .silver, current: min(guidedCount, 5), target: 5
      )
    case .completedPath:
      return AchievementProgress(
        id: id, title: "Cała ścieżka", requirement: "Ukończ całą ścieżkę",
        rarity: .gold, current: min(completedPaths, 1), target: 1
      )
    case .sevenDayStreak:
      return AchievementProgress(
        id: id, title: "Tydzień nauki", requirement: "Utrzymaj serię przez 7 dni",
        rarity: .gold, current: min(progress.streakDays, 7), target: 7
      )
    }
  }

  static func evaluateAll(_ progress: LearningProgress) -> [AchievementProgress] {
    AchievementID.allCases.map { evaluate(progress, id: $0) }
  }
}
