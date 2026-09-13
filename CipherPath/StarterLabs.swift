import Foundation

enum LessonExperience: Equatable, Sendable {
  case interactiveLab
  case classic

  static func resolve(for lesson: LearningLesson) -> LessonExperience {
    StarterLabs.definition(for: lesson) == nil ? .classic : .interactiveLab
  }
}

enum StarterLabs {
  static let all: [LabDefinition] = [
    portDetective,
    networkScout,
    logHunter,
    incidentLockdown,
    forgottenFTP,
    permissionTrail,
    hiddenWeb,
    unsafeAPI,
    iPhoneVault,
    mobileTrafficInspector,
  ]

  static func definition(for lesson: LearningLesson) -> LabDefinition? {
    definition(for: lesson.id)
  }

  static func definition(for lessonID: String) -> LabDefinition? {
    switch lessonID {
    case "fundamentals-digital-safety": portDetective
    case "fundamentals-read-port-scan": networkScout
    case "blue-team-find-log-event": logHunter
    case "blue-team-suspicious-login": incidentLockdown
    case "red-team-scope-first": forgottenFTP
    case "red-team-threat-thinking": permissionTrail
    case "web-http-anatomy": hiddenWeb
    case "web-spot-input-risk": unsafeAPI
    case "mobile-review-permissions": iPhoneVault
    case "mobile-protect-local-data": mobileTrafficInspector
    default: nil
    }
  }

  private static let portDetective = LabDefinition(
    id: "port-detective",
    title: "Port Detective",
    targetAddress: "192.0.2.10",
    allowedPrograms: ["ping", "nmap"],
    rules: [
      LabRule(
        command: .ping(target: "192.0.2.10"),
        output: "PING 192.0.2.10\n3 packets transmitted, 0 received\nUwaga: brak odpowiedzi nie oznacza wyłączonego hosta.",
        discovery: "Host nie odpowiada na ICMP",
        objectiveID: "availability"
      ),
      LabRule(
        command: .nmap(options: ["-sC", "-sV"], target: "192.0.2.10"),
        output: "PORT    STATE SERVICE VERSION\n443/tcp open  https   Atlas 3.1\n8443/tcp open  https-alt\nCIPHER{PING_IS_NOT_PROOF}",
        discovery: "Usługi odpowiadają mimo zablokowanego ping",
        objectiveID: "services"
      ),
    ],
    objectives: [
      LabObjective(id: "availability", title: "Sprawdź odpowiedź ICMP"),
      LabObjective(id: "services", title: "Potwierdź dostępność skanem usług"),
    ],
    flags: [
      LabFlag(
        id: "user", value: "CIPHER{PING_IS_NOT_PROOF}",
        requiredObjectiveIDs: ["availability", "services"]
      )
    ],
    suggestedCommands: ["ping 192.0.2.10", "nmap -sC -sV 192.0.2.10"],
    defenseSummary: "ICMP może być filtrowany. Dostępność oceniaj kilkoma kontrolowanymi metodami i dokumentuj ograniczenia pomiaru."
  )

  private static let networkScout = LabDefinition(
    id: "network-scout",
    title: "Network Scout",
    targetAddress: "192.0.2.11",
    allowedPrograms: ["ping", "nmap", "curl"],
    rules: [
      LabRule(
        command: .ping(target: "192.0.2.11"),
        output: "PING 192.0.2.11\n3 packets transmitted, 3 received, 0% packet loss",
        discovery: "Wirtualny host odpowiada",
        objectiveID: "availability"
      ),
      LabRule(
        command: .nmap(options: ["-sC", "-sV"], target: "192.0.2.11"),
        output: "PORT   STATE SERVICE VERSION\n22/tcp open  ssh     OpenSSH 9.3\n80/tcp open  http    Cinder 1.0",
        discovery: "Otwarte porty: 22/ssh i 80/http",
        objectiveID: "services"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.11"),
        output: "HTTP/1.1 200 OK\nServer: Cinder/1.0\n\nSystem monitor: /status",
        discovery: "Serwis WWW wskazuje ścieżkę /status"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.11/status"),
        output: "host=scout-01\nstate=training\nflag=CIPHER{SCOUT_READY}",
        discovery: "Odnaleziona flaga użytkownika",
        objectiveID: "flag"
      ),
    ],
    objectives: [
      LabObjective(id: "availability", title: "Sprawdź, czy host odpowiada"),
      LabObjective(id: "services", title: "Rozpoznaj otwarte usługi"),
      LabObjective(id: "flag", title: "Znajdź flagę w serwisie WWW"),
    ],
    flags: [
      LabFlag(
        id: "user",
        value: "CIPHER{SCOUT_READY}",
        requiredObjectiveIDs: ["availability", "services", "flag"]
      )
    ],
    suggestedCommands: [
      "ping 192.0.2.11",
      "nmap -sC -sV 192.0.2.11",
      "curl http://192.0.2.11",
    ],
    defenseSummary: "Inwentaryzuj wystawione usługi, wyłączaj zbędne porty i nie publikuj diagnostycznych punktów końcowych."
  )

  private static let logHunter = LabDefinition(
    id: "log-hunter",
    title: "Log Hunter",
    targetAddress: "192.0.2.20",
    allowedPrograms: ["find", "cat"],
    rules: [
      LabRule(
        command: .find(arguments: ["/logs", "-name", "*.log"]),
        output: "/logs/auth.log\n/logs/system.log",
        discovery: "Odnaleziono dwa źródła logów",
        objectiveID: "locate"
      ),
      LabRule(
        command: .cat(path: "/logs/auth.log"),
        output: "09:12 LOGIN_OK user=demo source=192.0.2.5\n09:14 LOGIN_ALERT user=admin source=198.51.100.77\n09:15 CIPHER{ANOMALY_0914}",
        discovery: "Nietypowe logowanie administratora o 09:14",
        objectiveID: "anomaly"
      ),
    ],
    objectives: [
      LabObjective(id: "locate", title: "Odszukaj pliki logów"),
      LabObjective(id: "anomaly", title: "Znajdź podejrzane zdarzenie"),
    ],
    flags: [
      LabFlag(
        id: "incident", value: "CIPHER{ANOMALY_0914}",
        requiredObjectiveIDs: ["locate", "anomaly"]
      )
    ],
    suggestedCommands: ["find /logs -name *.log", "cat /logs/auth.log"],
    defenseSummary: "Alert koreluj z użytkownikiem, źródłem i czasem. Zachowaj materiał dowodowy przed blokowaniem sesji."
  )

  private static let incidentLockdown = LabDefinition(
    id: "incident-lockdown",
    title: "Incident Lockdown",
    targetAddress: "192.0.2.21",
    allowedPrograms: ["cat", "id"],
    rules: [
      LabRule(
        command: .cat(path: "/incident/timeline.txt"),
        output: "10:01 new_device\n10:03 token_reuse\n10:04 privilege_change",
        discovery: "Sekwencja wskazuje przejęcie sesji",
        objectiveID: "timeline"
      ),
      LabRule(
        command: .id,
        output: "analyst uid=1001 groups=read-only\nCIPHER{PRESERVE_THEN_CONTAIN}",
        discovery: "Analityk ma bezpieczny dostęp tylko do odczytu",
        objectiveID: "contain"
      ),
    ],
    objectives: [
      LabObjective(id: "timeline", title: "Ustal kolejność zdarzeń"),
      LabObjective(id: "contain", title: "Potwierdź bezpieczną rolę analityka"),
    ],
    flags: [
      LabFlag(
        id: "incident", value: "CIPHER{PRESERVE_THEN_CONTAIN}",
        requiredObjectiveIDs: ["timeline", "contain"]
      )
    ],
    suggestedCommands: ["cat /incident/timeline.txt", "id"],
    defenseSummary: "Najpierw zachowaj ślady i zakres zdarzenia, następnie unieważnij sesję oraz ogranicz konto."
  )

  private static let forgottenFTP = LabDefinition(
    id: "forgotten-ftp",
    title: "Forgotten FTP",
    targetAddress: "192.0.2.30",
    allowedPrograms: ["nmap", "ftp", "ls", "cat"],
    rules: [
      LabRule(
        command: .nmap(options: ["-sC", "-sV"], target: "192.0.2.30"),
        output: "21/tcp open ftp HarborFTP 1.2\nftp-anon: Anonymous FTP login allowed",
        discovery: "Serwer FTP pozwala na anonimowe wejście",
        objectiveID: "service"
      ),
      LabRule(
        command: .ftp(target: "192.0.2.30"),
        output: "Connected to training FTP as anonymous.",
        discovery: "Uzyskano kontrolowany dostęp anonimowy",
        objectiveID: "access"
      ),
      LabRule(
        command: .ls(path: nil),
        output: "notice.txt\npublic/",
        discovery: "Odnaleziono plik notice.txt"
      ),
      LabRule(
        command: .cat(path: "notice.txt"),
        output: "Remove anonymous access after migration.\nCIPHER{ANON_SHARE_FOUND}",
        discovery: "Flaga znajdowała się w publicznym pliku",
        objectiveID: "flag"
      ),
    ],
    objectives: [
      LabObjective(id: "service", title: "Rozpoznaj usługę FTP"),
      LabObjective(id: "access", title: "Sprawdź dostęp anonimowy"),
      LabObjective(id: "flag", title: "Odczytaj pozostawioną notatkę"),
    ],
    flags: [
      LabFlag(
        id: "user", value: "CIPHER{ANON_SHARE_FOUND}",
        requiredObjectiveIDs: ["service", "access", "flag"]
      )
    ],
    suggestedCommands: ["nmap -sC -sV 192.0.2.30", "ftp 192.0.2.30", "ls"],
    defenseSummary: "Wyłącz anonimowy dostęp, usuń stare pliki i ogranicz usługę do wymaganych użytkowników oraz sieci."
  )

  private static let permissionTrail = LabDefinition(
    id: "permission-trail",
    title: "Permission Trail",
    targetAddress: "192.0.2.31",
    allowedPrograms: ["ssh", "whoami", "id", "sudo", "cat"],
    rules: [
      LabRule(
        command: .ssh(destination: "trainee@192.0.2.31"),
        output: "Connected to permission-lab as trainee.",
        discovery: "Sesja użytkownika trainee jest aktywna",
        objectiveID: "access"
      ),
      LabRule(command: .whoami, output: "trainee", discovery: "Bieżący użytkownik: trainee"),
      LabRule(
        command: .cat(path: "/home/trainee/user.txt"),
        output: "CIPHER{USER_ACCESS}",
        discovery: "Zdobyto flagę użytkownika",
        objectiveID: "user"
      ),
      LabRule(
        command: .sudoList,
        output: "(root) NOPASSWD: /usr/bin/cat /root/root.txt",
        discovery: "Reguła sudo pozwala odczytać wskazany plik jako root",
        objectiveID: "sudo"
      ),
      LabRule(
        command: .cat(path: "/root/root.txt"),
        output: "CIPHER{ROOT_RULE_REVIEW}",
        discovery: "Zdobyto flagę administratora",
        objectiveID: "root"
      ),
    ],
    objectives: [
      LabObjective(id: "access", title: "Wejdź na przygotowane konto"),
      LabObjective(id: "user", title: "Zdobądź flagę użytkownika"),
      LabObjective(id: "sudo", title: "Sprawdź dozwolone reguły sudo"),
      LabObjective(id: "root", title: "Zdobądź flagę administratora"),
    ],
    flags: [
      LabFlag(
        id: "user", value: "CIPHER{USER_ACCESS}",
        requiredObjectiveIDs: ["access", "user"]
      ),
      LabFlag(
        id: "root", value: "CIPHER{ROOT_RULE_REVIEW}",
        requiredObjectiveIDs: ["access", "user", "sudo", "root"]
      ),
    ],
    suggestedCommands: ["ssh trainee@192.0.2.31", "whoami", "cat /home/trainee/user.txt"],
    defenseSummary: "Reguły sudo powinny zapewniać minimalne uprawnienia. Nawet pozornie wąska komenda może ujawniać chronione dane."
  )

  private static let hiddenWeb = LabDefinition(
    id: "hidden-web",
    title: "Hidden Web",
    targetAddress: "192.0.2.40",
    allowedPrograms: ["nmap", "curl"],
    rules: [
      LabRule(
        command: .nmap(options: ["-sC", "-sV"], target: "192.0.2.40"),
        output: "PORT   STATE SERVICE VERSION\n80/tcp open  http    Lantern 2.4",
        discovery: "Serwer Lantern działa na porcie 80",
        objectiveID: "service"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.40"),
        output: "HTTP/1.1 200 OK\nServer: Lantern/2.4\n\nWelcome. Well-behaved robots read the rules.",
        discovery: "Strona sugeruje sprawdzenie reguł dla robotów"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.40/robots.txt"),
        output: "User-agent: *\nDisallow: /backup/",
        discovery: "Plik robots.txt ujawnia katalog /backup/",
        objectiveID: "clue"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.40/backup/note.txt"),
        output: "Training backup only\nCIPHER{ROBOTS_ARE_CLUES}",
        discovery: "Odnaleziona flaga w publicznej kopii zapasowej",
        objectiveID: "flag"
      ),
    ],
    objectives: [
      LabObjective(id: "service", title: "Rozpoznaj usługę WWW"),
      LabObjective(id: "clue", title: "Odszukaj wskazówkę administratora"),
      LabObjective(id: "flag", title: "Znajdź flagę w ujawnionym pliku"),
    ],
    flags: [
      LabFlag(
        id: "user",
        value: "CIPHER{ROBOTS_ARE_CLUES}",
        requiredObjectiveIDs: ["service", "clue", "flag"]
      )
    ],
    suggestedCommands: [
      "nmap -sC -sV 192.0.2.40",
      "curl http://192.0.2.40",
      "curl http://192.0.2.40/robots.txt",
    ],
    defenseSummary: "Nie umieszczaj kopii zapasowych w publicznym katalogu. robots.txt nie jest mechanizmem kontroli dostępu."
  )

  private static let unsafeAPI = LabDefinition(
    id: "unsafe-api",
    title: "Unsafe API",
    targetAddress: "192.0.2.41",
    allowedPrograms: ["curl", "cat"],
    rules: [
      LabRule(
        command: .cat(path: "request.txt"),
        output: "GET /api/profile HTTP/1.1\nHost: 192.0.2.41\nAuthorization: demo-session",
        discovery: "Przygotowano kontrolowane żądanie API",
        objectiveID: "request"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.41/api/profile"),
        output: "HTTP/1.1 200 OK\nAccess-Control-Allow-Origin: *\nX-Debug-Mode: enabled",
        discovery: "API ujawnia tryb debugowania i zbyt szeroki CORS",
        objectiveID: "headers"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.41/api/debug"),
        output: "debug_note=CIPHER{DEBUG_IS_DATA}",
        discovery: "Endpoint debugowania ujawnił flagę",
        objectiveID: "flag"
      ),
    ],
    objectives: [
      LabObjective(id: "request", title: "Odczytaj przygotowane żądanie"),
      LabObjective(id: "headers", title: "Oceń nagłówki odpowiedzi"),
      LabObjective(id: "flag", title: "Sprawdź ujawniony endpoint debug"),
    ],
    flags: [
      LabFlag(
        id: "api", value: "CIPHER{DEBUG_IS_DATA}",
        requiredObjectiveIDs: ["request", "headers", "flag"]
      )
    ],
    suggestedCommands: ["cat request.txt", "curl http://192.0.2.41/api/profile"],
    defenseSummary: "Wyłącz tryb debugowania w wydaniu, ogranicz CORS do zaufanych źródeł i nie zwracaj sekretów diagnostycznych."
  )

  private static let iPhoneVault = LabDefinition(
    id: "iphone-vault",
    title: "iPhone Vault",
    targetAddress: "192.0.2.50",
    allowedPrograms: ["ls", "find", "cat"],
    rules: [
      LabRule(
        command: .ls(path: "/app"),
        output: "Documents/\nLibrary/\nPreferences/",
        discovery: "Kontener aplikacji zawiera trzy obszary danych",
        objectiveID: "container"
      ),
      LabRule(
        command: .find(arguments: ["/app", "-name", "*.plist"]),
        output: "/app/Preferences/demo.plist",
        discovery: "Odnaleziono plik preferencji",
        objectiveID: "locate"
      ),
      LabRule(
        command: .cat(path: "/app/Preferences/demo.plist"),
        output: "theme=dark\nsession_token=plain-text\nCIPHER{MOVE_SECRETS_TO_KEYCHAIN}",
        discovery: "Sekret zapisano w zwykłych preferencjach",
        objectiveID: "flag"
      ),
    ],
    objectives: [
      LabObjective(id: "container", title: "Obejrzyj fikcyjny kontener aplikacji"),
      LabObjective(id: "locate", title: "Znajdź plik preferencji"),
      LabObjective(id: "flag", title: "Wskaż niewłaściwie zapisany sekret"),
    ],
    flags: [
      LabFlag(
        id: "mobile", value: "CIPHER{MOVE_SECRETS_TO_KEYCHAIN}",
        requiredObjectiveIDs: ["container", "locate", "flag"]
      )
    ],
    suggestedCommands: ["ls /app", "find /app -name *.plist", "cat /app/Preferences/demo.plist"],
    defenseSummary: "Tokeny i małe dane uwierzytelniające zapisuj w Keychain, a preferencje pozostaw dla niesekretnych ustawień."
  )

  private static let mobileTrafficInspector = LabDefinition(
    id: "mobile-traffic-inspector",
    title: "Mobile Traffic Inspector",
    targetAddress: "192.0.2.51",
    allowedPrograms: ["cat", "curl", "nmap"],
    rules: [
      LabRule(
        command: .cat(path: "mobile-request.txt"),
        output: "POST http://192.0.2.51/login\nContent-Type: application/json",
        discovery: "Aplikacja używa nieszyfrowanego HTTP",
        objectiveID: "request"
      ),
      LabRule(
        command: .nmap(options: ["-sC", "-sV"], target: "192.0.2.51"),
        output: "80/tcp open http TrainingAPI 1.0\n443/tcp closed https",
        discovery: "API nie udostępnia TLS",
        objectiveID: "transport"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.51/security-note"),
        output: "migration_required=https\nCIPHER{TLS_BEFORE_LOGIN}",
        discovery: "Notatka potwierdza wymaganą migrację do HTTPS",
        objectiveID: "flag"
      ),
    ],
    objectives: [
      LabObjective(id: "request", title: "Sprawdź schemat żądania logowania"),
      LabObjective(id: "transport", title: "Zweryfikuj dostępne protokoły"),
      LabObjective(id: "flag", title: "Odnajdź zalecenie migracyjne"),
    ],
    flags: [
      LabFlag(
        id: "transport", value: "CIPHER{TLS_BEFORE_LOGIN}",
        requiredObjectiveIDs: ["request", "transport", "flag"]
      )
    ],
    suggestedCommands: ["cat mobile-request.txt", "nmap -sC -sV 192.0.2.51"],
    defenseSummary: "Dane logowania przesyłaj wyłącznie przez poprawnie zweryfikowane TLS i stosuj App Transport Security."
  )
}
