import Foundation

enum AppDistributionMode: CaseIterable, Equatable, Sendable {
  case appStore
  case developer

  static var currentBuild: Self {
    #if CIPHERPATH_DEVELOPER
      .developer
    #else
      .appStore
    #endif
  }

  var showsAdventureMode: Bool {
    self == .developer
  }
}

enum LearningPath: String, CaseIterable, Codable, Hashable, Sendable {
  case fundamentals
  case blueTeam
  case redTeam
  case webSecurity
  case mobileSecurity

  var title: String {
    switch self {
    case .fundamentals: "Podstawy"
    case .blueTeam: "Blue Team"
    case .redTeam: "Red Team"
    case .webSecurity: "Web Security"
    case .mobileSecurity: "Mobile Security"
    }
  }
}

enum LearningEnvironment: String, Codable, Equatable, Sendable {
  case offlineSimulation
  case ownedLab
}

enum LessonAvailability: String, Codable, Equatable, Sendable {
  case available
  case comingSoon
}

enum ContentAccessTier: String, Codable, Equatable, Sendable {
  case free
  case testFlightDemo
  case pro
  case subscription
}

enum LessonAccess: Equatable, Sendable {
  case included
  case requiresPro
  case requiresSubscription
  case comingSoon
}

struct ContentAccessPolicy: Equatable, Sendable {
  static let current = ContentAccessPolicy(tier: .free)

  let tier: ContentAccessTier

  func access(for lesson: LearningLesson) -> LessonAccess {
    guard lesson.availability == .available else { return .comingSoon }

    switch tier {
    case .free:
      return lesson.order == 1 ? .included : .requiresPro
    case .testFlightDemo:
      return lesson.order <= 2 ? .included : .requiresPro
    case .pro, .subscription:
      return .included
    }
  }

  func includedLessons(in path: LearningPath) -> Int {
    StarterCurriculum.lessons(in: path).filter { access(for: $0) == .included }.count
  }
}

enum MissionDifficulty: String, Equatable, Sendable {
  case easy = "Łatwa"
  case medium = "Średnia"
}

struct MissionBriefing: Equatable, Sendable {
  let story: String
  let objective: String
  let learningOutcomes: [String]
  let estimatedMinutes: Int
  let difficulty: MissionDifficulty

  static func forLesson(_ lesson: LearningLesson) -> Self {
    let story: String
    let objective: String

    switch lesson.path {
    case .fundamentals:
      story = "Otrzymujesz dostęp do kontrolowanego hosta szkoleniowego. Zbierz pierwsze wskazówki i ustal, co naprawdę działa w sieci."
      objective = "Rozpoznaj przygotowane usługi i odnajdź odpowiedź bez wychodzenia poza laboratorium."
    case .blueTeam:
      story = "Centrum operacyjne zgłasza nietypowe zdarzenie. Materiał dowodowy jest gotowy, a Twoim zadaniem jest oddzielić sygnał od szumu."
      objective = "Przeanalizuj ślady, potwierdź incydent i wybierz bezpieczną reakcję."
    case .redTeam:
      story = "Właściciel fikcyjnego systemu zlecił legalny test w ściśle określonym zakresie. Sprawdź, gdzie zaczyna się ścieżka ryzyka."
      objective = "Znajdź kontrolowaną słabość, ustal odpowiedź i wskaż sposób obrony."
    case .webSecurity:
      story = "Aplikacja demonstracyjna zachowuje się nietypowo. Zbadaj przygotowane odpowiedzi i odkryj błąd konfiguracji."
      objective = "Połącz wskazówki z warstwy HTTP i odnajdź odpowiedź w symulacji offline."
    case .mobileSecurity:
      story = "Testowa aplikacja mobilna trafia do przeglądu bezpieczeństwa przed wydaniem. Ty wykonujesz kontrolę jej danych i komunikacji."
      objective = "Oceń przygotowany przypadek i wybierz ochronę właściwą dla iPhone’a."
    }

    return MissionBriefing(
      story: story,
      objective: objective,
      learningOutcomes: [
        lesson.summary,
        "Praca z dowodami w bezpiecznej symulacji",
        "Rozpoznanie ryzyka i właściwej obrony",
      ],
      estimatedMinutes: lesson.order == 1 ? 8 : 12,
      difficulty: lesson.order == 1 ? .easy : .medium
    )
  }
}

enum LessonStage: String, CaseIterable, Codable, Equatable, Sendable {
  case learn
  case check
  case findFlag
  case explanation

  var title: String {
    switch self {
    case .learn: "Poznaj"
    case .check: "Sprawdź"
    case .findFlag: "Znajdź odpowiedź"
    case .explanation: "Wyjaśnienie"
    }
  }
}

struct LearningLesson: Identifiable, Codable, Equatable, Sendable {
  let id: String
  let path: LearningPath
  let order: Int
  let title: String
  let summary: String
  let environment: LearningEnvironment
  let availability: LessonAvailability
  let stages: [LessonStage]
}

enum StarterCurriculum {
  static let paths = LearningPath.allCases

  static let lessons: [LearningLesson] = [
    lesson(
      id: "fundamentals-digital-safety", path: .fundamentals, order: 1,
      title: "Port Detective",
      summary: "Sprawdź host, który nie odpowiada na ping, i rozpoznaj jego usługi."),
    lesson(
      id: "fundamentals-read-port-scan", path: .fundamentals, order: 2,
      title: "Network Scout",
      summary: "Uruchom wirtualny cel, rozpoznaj usługi i odnajdź odpowiedź."),
    lesson(
      id: "fundamentals-network-addresses", path: .fundamentals, order: 3,
      title: "Adresy i sieci prywatne",
      summary: "Nauczysz się odróżniać adres lokalny od publicznego."),
    lesson(
      id: "fundamentals-terminal-basics", path: .fundamentals, order: 4,
      title: "Terminal bez tajemnic",
      summary: "Poznasz bezpieczne podstawy pracy w terminalu."),
    lesson(
      id: "fundamentals-security-evidence", path: .fundamentals, order: 5,
      title: "Dowody i notatki",
      summary: "Zapiszesz obserwacje bez przechowywania sekretów."),

    lesson(
      id: "blue-team-find-log-event", path: .blueTeam, order: 1,
      title: "Log Hunter",
      summary: "Przeszukaj przygotowane logi i znajdź podejrzane zdarzenie."),
    lesson(
      id: "blue-team-suspicious-login", path: .blueTeam, order: 2,
      title: "Incident Lockdown",
      summary: "Odtwórz incydent i wybierz bezpieczną kolejność reakcji."),
    lesson(
      id: "blue-team-file-integrity", path: .blueTeam, order: 3,
      title: "Integralność plików",
      summary: "Porównasz sumy kontrolne w przygotowanym zestawie."),
    lesson(
      id: "blue-team-network-baseline", path: .blueTeam, order: 4,
      title: "Profil normalnego ruchu",
      summary: "Zbudujesz prostą bazę odniesienia dla ruchu sieciowego."),
    lesson(
      id: "blue-team-incident-notes", path: .blueTeam, order: 5,
      title: "Pierwsza reakcja na incydent",
      summary: "Uporządkujesz działania bez zmieniania materiału dowodowego."),

    lesson(
      id: "red-team-scope-first", path: .redTeam, order: 1,
      title: "Forgotten FTP",
      summary: "Rozpoznaj anonimowy udział i odszukaj pozostawioną notatkę."),
    lesson(
      id: "red-team-threat-thinking", path: .redTeam, order: 2,
      title: "Permission Trail",
      summary: "Odnajdź odpowiedź użytkownika i przeanalizuj niebezpieczną regułę sudo."),
    lesson(
      id: "red-team-owned-lab-recon", path: .redTeam, order: 3,
      title: "Rozpoznanie własnego labu",
      summary: "Przygotujesz pasywne rozpoznanie własnego środowiska."),
    lesson(
      id: "red-team-risk-chain", path: .redTeam, order: 4,
      title: "Łańcuch ryzyka",
      summary: "Połączysz kontrolowane obserwacje w ścieżkę ryzyka."),
    lesson(
      id: "red-team-defensive-report", path: .redTeam, order: 5,
      title: "Raport z rekomendacją",
      summary: "Opiszesz znalezisko i praktyczny sposób jego usunięcia."),

    lesson(
      id: "web-http-anatomy", path: .webSecurity, order: 1,
      title: "Hidden Web",
      summary: "Zbadaj fikcyjny serwer WWW i odkryj ujawnioną kopię."),
    lesson(
      id: "web-spot-input-risk", path: .webSecurity, order: 2,
      title: "Unsafe API",
      summary: "Przeanalizuj fikcyjne odpowiedzi API i ujawniony tryb debugowania."),
    lesson(
      id: "web-session-basics", path: .webSecurity, order: 3,
      title: "Sesja i ciasteczka",
      summary: "Poznasz zabezpieczenia fikcyjnej sesji użytkownika."),
    lesson(
      id: "web-access-control", path: .webSecurity, order: 4,
      title: "Kontrola dostępu",
      summary: "Sprawdzisz uprawnienia na przygotowanej macierzy ról."),
    lesson(
      id: "web-security-headers", path: .webSecurity, order: 5,
      title: "Nagłówki ochronne",
      summary: "Dobierzesz ochronne nagłówki do aplikacji demonstracyjnej."),

    lesson(
      id: "mobile-review-permissions", path: .mobileSecurity, order: 1,
      title: "iPhone Vault",
      summary: "Przejrzyj fikcyjny kontener aplikacji i znajdź źle zapisany sekret."),
    lesson(
      id: "mobile-protect-local-data", path: .mobileSecurity, order: 2,
      title: "Mobile Traffic Inspector",
      summary: "Zbadaj kontrolowane żądanie mobilne i wykryj brak TLS."),
    lesson(
      id: "mobile-transport-security", path: .mobileSecurity, order: 3,
      title: "Bezpieczna transmisja",
      summary: "Ocenisz konfigurację połączeń aplikacji demonstracyjnej."),
    lesson(
      id: "mobile-app-privacy", path: .mobileSecurity, order: 4,
      title: "Prywatność aplikacji",
      summary: "Połączysz zbierane dane z wymaganymi deklaracjami."),
    lesson(
      id: "mobile-release-review", path: .mobileSecurity, order: 5,
      title: "Kontrola przed wydaniem",
      summary: "Przejdziesz bezpieczną listę kontrolną aplikacji mobilnej."),
  ]

  static func lessons(in path: LearningPath) -> [LearningLesson] {
    lessons.filter { $0.path == path }.sorted { $0.order < $1.order }
  }

  private static func lesson(
    id: String,
    path: LearningPath,
    order: Int,
    title: String,
    summary: String,
    environment: LearningEnvironment = .offlineSimulation
  ) -> LearningLesson {
    let proLessonIDs = [
      "fundamentals-network-addresses",
      "fundamentals-terminal-basics",
      "fundamentals-security-evidence",
      "blue-team-file-integrity",
      "blue-team-network-baseline",
      "blue-team-incident-notes",
      "red-team-owned-lab-recon",
      "red-team-risk-chain",
      "red-team-defensive-report",
      "web-session-basics",
      "web-access-control",
      "web-security-headers",
      "mobile-transport-security",
      "mobile-app-privacy",
      "mobile-release-review",
    ]
    let availability: LessonAvailability =
      order <= 2 || proLessonIDs.contains(id) ? .available : .comingSoon
    return LearningLesson(
      id: id,
      path: path,
      order: order,
      title: title,
      summary: summary,
      environment: environment,
      availability: availability,
      stages: availability == .available ? LessonStage.allCases : []
    )
  }
}
