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
    privateAddresses,
    terminalBasics,
    logHunter,
    incidentLockdown,
    fileIntegrity,
    networkBaseline,
    forgottenFTP,
    permissionTrail,
    ownedLabRecon,
    riskChain,
    hiddenWeb,
    unsafeAPI,
    sessionBasics,
    iPhoneVault,
    mobileTrafficInspector,
    secureTransport,
  ]

  static func definition(for lesson: LearningLesson) -> LabDefinition? {
    definition(for: lesson.id)
  }

  static func definition(for lessonID: String) -> LabDefinition? {
    switch lessonID {
    case "fundamentals-digital-safety": portDetective
    case "fundamentals-read-port-scan": networkScout
    case "fundamentals-network-addresses": privateAddresses
    case "fundamentals-terminal-basics": terminalBasics
    case "blue-team-find-log-event": logHunter
    case "blue-team-suspicious-login": incidentLockdown
    case "blue-team-file-integrity": fileIntegrity
    case "blue-team-network-baseline": networkBaseline
    case "red-team-scope-first": forgottenFTP
    case "red-team-threat-thinking": permissionTrail
    case "red-team-owned-lab-recon": ownedLabRecon
    case "red-team-risk-chain": riskChain
    case "web-http-anatomy": hiddenWeb
    case "web-spot-input-risk": unsafeAPI
    case "web-session-basics": sessionBasics
    case "mobile-review-permissions": iPhoneVault
    case "mobile-protect-local-data": mobileTrafficInspector
    case "mobile-transport-security": secureTransport
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
        answer: "Brak ping nie dowodzi wyłączenia hosta",
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
        discovery: "Odnaleziona odpowiedź użytkownika",
        objectiveID: "flag"
      ),
    ],
    objectives: [
      LabObjective(id: "availability", title: "Sprawdź, czy host odpowiada"),
      LabObjective(id: "services", title: "Rozpoznaj otwarte usługi"),
      LabObjective(id: "flag", title: "Znajdź odpowiedź w serwisie WWW"),
    ],
    flags: [
      LabFlag(
        id: "user",
        value: "CIPHER{SCOUT_READY}",
        answer: "Scout gotowy",
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

  private static let privateAddresses = LabDefinition(
    id: "private-addresses",
    title: "Adresy i sieci prywatne",
    targetAddress: "192.0.2.12",
    allowedPrograms: ["cat"],
    rules: [
      LabRule(
        command: .cat(path: "/network/candidates.txt"),
        output: "A 10.24.8.0/24\nB 172.20.0.0/16\nC 192.168.50.0/24\nD 203.0.113.0/24",
        discovery: "Trzy z czterech zakresów należą do przestrzeni prywatnej",
        objectiveID: "candidates"
      ),
      LabRule(
        command: .cat(path: "/network/rfc1918.txt"),
        output: "10.0.0.0/8\n172.16.0.0/12\n192.168.0.0/16\nCIPHER{RFC1918_PRIVATE}",
        discovery: "Odnaleziono trzy zakresy prywatne RFC1918",
        objectiveID: "classify"
      ),
    ],
    objectives: [
      LabObjective(id: "candidates", title: "Odczytaj przygotowane zakresy"),
      LabObjective(id: "classify", title: "Porównaj je z zakresami RFC1918"),
    ],
    flags: [
      LabFlag(
        id: "network", value: "CIPHER{RFC1918_PRIVATE}",
        answer: "Zakresy RFC1918 są prywatne",
        requiredObjectiveIDs: ["candidates", "classify"]
      )
    ],
    suggestedCommands: [
      "cat /network/candidates.txt",
      "cat /network/rfc1918.txt",
    ],
    defenseSummary: "Przed testem rozróżnij adresy prywatne, dokumentacyjne i publiczne. Skanuj wyłącznie zakres wskazany przez właściciela laboratorium."
  )

  private static let terminalBasics = LabDefinition(
    id: "terminal-basics",
    title: "Terminal bez tajemnic",
    targetAddress: "192.0.2.13",
    allowedPrograms: ["ls", "cd", "cat"],
    rules: [
      LabRule(
        command: .ls(path: "/training"),
        output: "briefing.txt\nevidence/",
        discovery: "Katalog szkoleniowy zawiera instrukcję i materiał do analizy",
        objectiveID: "list"
      ),
      LabRule(
        command: .cd(path: "/training"),
        output: "Current directory: /training",
        discovery: "Zmieniono katalog roboczy bez modyfikowania plików",
        objectiveID: "navigate"
      ),
      LabRule(
        command: .cat(path: "briefing.txt"),
        output: "ls=list files\ncd=change directory\ncat=read file\nCIPHER{READ_BEFORE_ACTION}",
        discovery: "Odczytano znaczenie trzech podstawowych poleceń",
        objectiveID: "read"
      ),
    ],
    objectives: [
      LabObjective(id: "list", title: "Wyświetl zawartość katalogu szkoleniowego"),
      LabObjective(id: "navigate", title: "Przejdź do wskazanego katalogu"),
      LabObjective(id: "read", title: "Odczytaj briefing i znajdź odpowiedź"),
    ],
    flags: [
      LabFlag(
        id: "terminal", value: "CIPHER{READ_BEFORE_ACTION}",
        answer: "Najpierw odczytaj, potem działaj",
        requiredObjectiveIDs: ["list", "navigate", "read"]
      )
    ],
    suggestedCommands: ["ls /training", "cd /training", "cat briefing.txt"],
    defenseSummary: "Przed wykonaniem polecenia sprawdź katalog i pliki. Rozpoczynaj od operacji tylko do odczytu i unikaj pracy na sekretach."
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
        answer: "Anomalia o 09:14",
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
        answer: "Najpierw zachowaj ślady, potem ogranicz incydent",
        requiredObjectiveIDs: ["timeline", "contain"]
      )
    ],
    suggestedCommands: ["cat /incident/timeline.txt", "id"],
    defenseSummary: "Najpierw zachowaj ślady i zakres zdarzenia, następnie unieważnij sesję oraz ogranicz konto."
  )

  private static let fileIntegrity = LabDefinition(
    id: "file-integrity",
    title: "Integralność plików",
    targetAddress: "192.0.2.22",
    allowedPrograms: ["find", "cat", "sha256sum"],
    rules: [
      LabRule(
        command: .find(arguments: ["/evidence", "-type", "f"]),
        output: "/evidence/manifest.txt\n/evidence/app.bin",
        discovery: "Odnaleziono manifest i badany plik",
        objectiveID: "locate"
      ),
      LabRule(
        command: .cat(path: "/evidence/manifest.txt"),
        output: "app.bin expected=9f86d081884c7d659a2feaa0c55ad015",
        discovery: "Manifest zawiera oczekiwaną sumę pliku",
        objectiveID: "baseline"
      ),
      LabRule(
        command: .sha256sum(path: "/evidence/app.bin"),
        output: "b5c1fb2efc6d6b4674c2fdcc48ce01b4  /evidence/app.bin\nCIPHER{FILE_CHANGED}",
        discovery: "Rzeczywista suma różni się od wartości w manifeście",
        objectiveID: "verify"
      ),
    ],
    objectives: [
      LabObjective(id: "locate", title: "Znajdź pliki dowodowe"),
      LabObjective(id: "baseline", title: "Odczytaj zaufaną sumę kontrolną"),
      LabObjective(id: "verify", title: "Porównaj sumę badanego pliku"),
    ],
    flags: [
      LabFlag(
        id: "integrity", value: "CIPHER{FILE_CHANGED}",
        answer: "Plik aplikacji został zmieniony",
        requiredObjectiveIDs: ["locate", "baseline", "verify"]
      )
    ],
    suggestedCommands: [
      "find /evidence -type f",
      "cat /evidence/manifest.txt",
      "sha256sum /evidence/app.bin",
    ],
    defenseSummary: "Porównuj pliki z sumami pochodzącymi z zaufanego źródła. Zabezpiecz materiał dowodowy przed naprawą lub ponownym wdrożeniem."
  )

  private static let networkBaseline = LabDefinition(
    id: "network-baseline",
    title: "Profil normalnego ruchu",
    targetAddress: "192.0.2.23",
    allowedPrograms: ["cat", "nmap"],
    rules: [
      LabRule(
        command: .cat(path: "/traffic/baseline.txt"),
        output: "expected=22/tcp,443/tcp\nwindow=08:00-18:00",
        discovery: "Profil bazowy obejmuje SSH i HTTPS w godzinach pracy",
        objectiveID: "baseline"
      ),
      LabRule(
        command: .nmap(options: ["-sV"], target: "192.0.2.23"),
        output: "22/tcp open ssh\n443/tcp open https\n8443/tcp open https-alt\nunexpected=8443/tcp",
        discovery: "Port 8443 nie występuje w profilu bazowym",
        objectiveID: "compare"
      ),
      LabRule(
        command: .cat(path: "/traffic/change-log.txt"),
        output: "8443/tcp owner=unknown approval=missing\nCIPHER{BASELINE_REVEALS_CHANGE}",
        discovery: "Brak właściciela i zatwierdzenia dla nowej usługi",
        objectiveID: "explain"
      ),
    ],
    objectives: [
      LabObjective(id: "baseline", title: "Odczytaj profil normalnego ruchu"),
      LabObjective(id: "compare", title: "Porównaj bieżące usługi z bazą"),
      LabObjective(id: "explain", title: "Ustal, dlaczego różnica wymaga analizy"),
    ],
    flags: [
      LabFlag(
        id: "baseline", value: "CIPHER{BASELINE_REVEALS_CHANGE}",
        answer: "Profil bazowy ujawnia niezatwierdzoną zmianę",
        requiredObjectiveIDs: ["baseline", "compare", "explain"]
      )
    ],
    suggestedCommands: [
      "cat /traffic/baseline.txt",
      "nmap -sV 192.0.2.23",
      "cat /traffic/change-log.txt",
    ],
    defenseSummary: "Utrzymuj zatwierdzony profil usług i wyjaśniaj każdą różnicę. Sama anomalia jest sygnałem do analizy, a nie automatycznym dowodem ataku."
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
        discovery: "Odpowiedź znajdowała się w publicznym pliku",
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
        answer: "Znaleziono anonimowy udział",
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
        discovery: "Odnaleziono odpowiedź użytkownika",
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
        discovery: "Odnaleziono odpowiedź administratora",
        objectiveID: "root"
      ),
    ],
    objectives: [
      LabObjective(id: "access", title: "Wejdź na przygotowane konto"),
      LabObjective(id: "user", title: "Odnajdź odpowiedź użytkownika"),
      LabObjective(id: "sudo", title: "Sprawdź dozwolone reguły sudo"),
      LabObjective(id: "root", title: "Odnajdź odpowiedź administratora"),
    ],
    flags: [
      LabFlag(
        id: "user", value: "CIPHER{USER_ACCESS}",
        answer: "Dostęp użytkownika zdobyty",
        requiredObjectiveIDs: ["access", "user"]
      ),
      LabFlag(
        id: "root", value: "CIPHER{ROOT_RULE_REVIEW}",
        answer: "Reguła administratora wymaga przeglądu",
        requiredObjectiveIDs: ["access", "user", "sudo", "root"]
      ),
    ],
    suggestedCommands: ["ssh trainee@192.0.2.31", "whoami", "cat /home/trainee/user.txt"],
    defenseSummary: "Reguły sudo powinny zapewniać minimalne uprawnienia. Nawet pozornie wąska komenda może ujawniać chronione dane."
  )

  private static let ownedLabRecon = LabDefinition(
    id: "owned-lab-recon",
    title: "Rozpoznanie własnego labu",
    targetAddress: "192.0.2.32",
    allowedPrograms: ["nmap", "smbclient", "ls", "cat"],
    rules: [
      LabRule(
        command: .nmap(options: ["-sC", "-sV"], target: "192.0.2.32"),
        output: "445/tcp open microsoft-ds TrainingSMB 1.0",
        discovery: "Kontrolowany host udostępnia usługę SMB",
        objectiveID: "service"
      ),
      LabRule(
        command: .smbclient(arguments: ["-L", "//192.0.2.32", "-N"]),
        output: "Sharename  Type\naudit      Disk\nIPC$       IPC",
        discovery: "Lista udziałów ujawnia udział audit bez logowania",
        objectiveID: "shares"
      ),
      LabRule(
        command: .smbclient(arguments: ["//192.0.2.32/audit", "-N"]),
        output: "Anonymous session established in offline training lab.",
        discovery: "Otwarto kontrolowany udział audit"
      ),
      LabRule(
        command: .ls(path: nil),
        output: "scope.txt\nreadme.txt",
        discovery: "W udziale znajduje się plik scope.txt"
      ),
      LabRule(
        command: .cat(path: "scope.txt"),
        output: "owner=training\nauthorized=true\nCIPHER{ANONYMOUS_AUDIT_SHARE}",
        discovery: "Potwierdzono anonimowy dostęp do udziału szkoleniowego",
        objectiveID: "evidence"
      ),
    ],
    objectives: [
      LabObjective(id: "service", title: "Rozpoznaj usługę w dozwolonym zakresie"),
      LabObjective(id: "shares", title: "Wyświetl udziały bez uwierzytelnienia"),
      LabObjective(id: "evidence", title: "Znajdź potwierdzenie błędnej konfiguracji"),
    ],
    flags: [
      LabFlag(
        id: "recon", value: "CIPHER{ANONYMOUS_AUDIT_SHARE}",
        answer: "Udział audit jest dostępny anonimowo",
        requiredObjectiveIDs: ["service", "shares", "evidence"]
      )
    ],
    suggestedCommands: [
      "nmap -sC -sV 192.0.2.32",
      "smbclient -L //192.0.2.32 -N",
      "smbclient //192.0.2.32/audit -N",
    ],
    defenseSummary: "Wyłącz dostęp anonimowy, ogranicz udziały do wymaganych kont i sieci oraz regularnie przeglądaj opublikowane zasoby."
  )

  private static let riskChain = LabDefinition(
    id: "risk-chain",
    title: "Łańcuch ryzyka",
    targetAddress: "192.0.2.33",
    allowedPrograms: ["nmap", "curl", "cat"],
    rules: [
      LabRule(
        command: .nmap(options: ["-sC", "-sV"], target: "192.0.2.33"),
        output: "80/tcp open http TrainingPortal 1.0\n8080/tcp open http-alt AdminPreview 0.8",
        discovery: "Kontrolowany host ujawnia dodatkowy panel podglądu",
        objectiveID: "exposure"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.33:8080"),
        output: "HTTP/1.1 200 OK\nX-Debug: enabled\nHint: review /notes/deploy.txt",
        discovery: "Panel działa bez logowania i ujawnia ścieżkę notatki",
        objectiveID: "clue"
      ),
      LabRule(
        command: .cat(path: "/notes/deploy.txt"),
        output: "public panel + debug header + deployment note\nCIPHER{THREE_LINKS_ONE_RISK}",
        discovery: "Trzy kontrolowane słabości tworzą jedną ścieżkę ryzyka",
        objectiveID: "chain"
      ),
    ],
    objectives: [
      LabObjective(id: "exposure", title: "Znajdź dodatkową wystawioną usługę"),
      LabObjective(id: "clue", title: "Odczytaj wskazówkę z panelu"),
      LabObjective(id: "chain", title: "Połącz obserwacje w łańcuch ryzyka"),
    ],
    flags: [
      LabFlag(
        id: "chain", value: "CIPHER{THREE_LINKS_ONE_RISK}",
        answer: "Trzy słabości tworzą jedną ścieżkę ryzyka",
        requiredObjectiveIDs: ["exposure", "clue", "chain"]
      )
    ],
    suggestedCommands: [
      "nmap -sC -sV 192.0.2.33",
      "curl http://192.0.2.33:8080",
      "cat /notes/deploy.txt",
    ],
    defenseSummary: "Oceniaj łączny wpływ drobnych błędów. Ogranicz panel administracyjny, wyłącz diagnostykę i nie publikuj notatek wdrożeniowych."
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
        discovery: "Odnaleziona odpowiedź w publicznej kopii zapasowej",
        objectiveID: "flag"
      ),
    ],
    objectives: [
      LabObjective(id: "service", title: "Rozpoznaj usługę WWW"),
      LabObjective(id: "clue", title: "Odszukaj wskazówkę administratora"),
      LabObjective(id: "flag", title: "Znajdź odpowiedź w ujawnionym pliku"),
    ],
    flags: [
      LabFlag(
        id: "user",
        value: "CIPHER{ROBOTS_ARE_CLUES}",
        answer: "Robots.txt ujawnia wskazówki",
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
        discovery: "Endpoint debugowania ujawnił odpowiedź",
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
        answer: "Dane debugowania są wrażliwe",
        requiredObjectiveIDs: ["request", "headers", "flag"]
      )
    ],
    suggestedCommands: ["cat request.txt", "curl http://192.0.2.41/api/profile"],
    defenseSummary: "Wyłącz tryb debugowania w wydaniu, ogranicz CORS do zaufanych źródeł i nie zwracaj sekretów diagnostycznych."
  )

  private static let sessionBasics = LabDefinition(
    id: "session-basics",
    title: "Sesja i ciasteczka",
    targetAddress: "192.0.2.42",
    allowedPrograms: ["curl"],
    rules: [
      LabRule(
        command: .curl(url: "http://192.0.2.42/login"),
        output: "HTTP/1.1 200 OK\nSet-Cookie: session=training; Path=/\n\nLogin accepted",
        discovery: "Ciasteczko sesji nie ma atrybutów Secure ani HttpOnly",
        objectiveID: "inspect"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.42/security-review"),
        output: "required_cookie_flags=Secure,HttpOnly,SameSite\nCIPHER{HARDEN_SESSION_COOKIE}",
        discovery: "Przegląd wskazuje wymagane zabezpieczenia ciasteczka",
        objectiveID: "remediation"
      ),
    ],
    objectives: [
      LabObjective(id: "inspect", title: "Sprawdź nagłówek Set-Cookie"),
      LabObjective(id: "remediation", title: "Ustal wymagane zabezpieczenia sesji"),
    ],
    flags: [
      LabFlag(
        id: "session", value: "CIPHER{HARDEN_SESSION_COOKIE}",
        answer: "Ciasteczko sesji wymaga Secure i HttpOnly",
        requiredObjectiveIDs: ["inspect", "remediation"]
      )
    ],
    suggestedCommands: [
      "curl http://192.0.2.42/login",
      "curl http://192.0.2.42/security-review",
    ],
    defenseSummary: "Ciasteczka sesyjne ustawiaj z Secure, HttpOnly i właściwym SameSite, a logowanie udostępniaj wyłącznie przez HTTPS."
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
        answer: "Przenieś sekrety do Keychain",
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
        answer: "TLS przed logowaniem",
        requiredObjectiveIDs: ["request", "transport", "flag"]
      )
    ],
    suggestedCommands: ["cat mobile-request.txt", "nmap -sC -sV 192.0.2.51"],
    defenseSummary: "Dane logowania przesyłaj wyłącznie przez poprawnie zweryfikowane TLS i stosuj App Transport Security."
  )

  private static let secureTransport = LabDefinition(
    id: "secure-transport",
    title: "Bezpieczna transmisja",
    targetAddress: "192.0.2.52",
    allowedPrograms: ["cat", "curl"],
    rules: [
      LabRule(
        command: .cat(path: "/app/Info.plist"),
        output: "NSAppTransportSecurity\nNSAllowsArbitraryLoads=true",
        discovery: "Aplikacja zezwala na dowolne nieszyfrowane połączenia",
        objectiveID: "configuration"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.52/profile"),
        output: "HTTP/1.1 200 OK\ntransport=cleartext\ncontent=training-profile",
        discovery: "Dane profilu przechodzą przez zwykły HTTP",
        objectiveID: "observe"
      ),
      LabRule(
        command: .cat(path: "/app/security-review.txt"),
        output: "require=https\nats_exception=remove\nCIPHER{ATS_BLOCKS_CLEARTEXT}",
        discovery: "Przegląd wymaga HTTPS i usunięcia szerokiego wyjątku ATS",
        objectiveID: "remediation"
      ),
    ],
    objectives: [
      LabObjective(id: "configuration", title: "Sprawdź konfigurację transportu aplikacji"),
      LabObjective(id: "observe", title: "Potwierdź użycie nieszyfrowanego HTTP"),
      LabObjective(id: "remediation", title: "Wskaż bezpieczną konfigurację"),
    ],
    flags: [
      LabFlag(
        id: "transport", value: "CIPHER{ATS_BLOCKS_CLEARTEXT}",
        answer: "ATS powinien blokować nieszyfrowany ruch",
        requiredObjectiveIDs: ["configuration", "observe", "remediation"]
      )
    ],
    suggestedCommands: [
      "cat /app/Info.plist",
      "curl http://192.0.2.52/profile",
      "cat /app/security-review.txt",
    ],
    defenseSummary: "Usuń szeroki wyjątek ATS, używaj HTTPS i poprawnie weryfikuj certyfikat serwera. Wyjątki ograniczaj do udokumentowanego minimum."
  )
}
