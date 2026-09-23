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
    securityEvidence,
    logHunter,
    incidentLockdown,
    fileIntegrity,
    networkBaseline,
    incidentNotes,
    forgottenFTP,
    permissionTrail,
    ownedLabRecon,
    riskChain,
    defensiveReport,
    hiddenWeb,
    unsafeAPI,
    sessionBasics,
    accessControl,
    securityHeaders,
    iPhoneVault,
    mobileTrafficInspector,
    secureTransport,
    appPrivacy,
    releaseReview,
    dnsResolution,
    leastPrivilege,
    suspiciousMessage,
    alertPrioritization,
    threatModeling,
    controlledReport,
    secureCookies,
    secureAPI,
    secureLogging,
    dataFlowPrivacy,
  ] + generatedLabs

  private static let generatedLabs: [LabDefinition] = {
    StarterCurriculum.lessons
      .filter { $0.id.contains("-generated-") }
      .enumerated()
      .map { index, lesson in generatedLab(for: lesson, index: index) }
  }()

  static func definition(for lesson: LearningLesson) -> LabDefinition? {
    definition(for: lesson.id)
  }

  static func definition(for lessonID: String) -> LabDefinition? {
    if lessonID.contains("-generated-"),
       let lesson = StarterCurriculum.lessons.first(where: { $0.id == lessonID }),
       let index = StarterCurriculum.lessons.filter({ $0.id.contains("-generated-") }).firstIndex(of: lesson) {
      return generatedLab(for: lesson, index: index)
    }

    return switch lessonID {
    case "fundamentals-digital-safety": portDetective
    case "fundamentals-read-port-scan": networkScout
    case "fundamentals-network-addresses": privateAddresses
    case "fundamentals-terminal-basics": terminalBasics
    case "fundamentals-security-evidence": securityEvidence
    case "fundamentals-dns-resolution": dnsResolution
    case "fundamentals-least-privilege": leastPrivilege
    case "blue-team-find-log-event": logHunter
    case "blue-team-suspicious-login": incidentLockdown
    case "blue-team-file-integrity": fileIntegrity
    case "blue-team-network-baseline": networkBaseline
    case "blue-team-incident-notes": incidentNotes
    case "blue-team-suspicious-message": suspiciousMessage
    case "blue-team-alert-prioritization": alertPrioritization
    case "red-team-scope-first": forgottenFTP
    case "red-team-threat-thinking": permissionTrail
    case "red-team-owned-lab-recon": ownedLabRecon
    case "red-team-risk-chain": riskChain
    case "red-team-defensive-report": defensiveReport
    case "red-team-threat-modeling": threatModeling
    case "red-team-controlled-report": controlledReport
    case "web-http-anatomy": hiddenWeb
    case "web-spot-input-risk": unsafeAPI
    case "web-session-basics": sessionBasics
    case "web-access-control": accessControl
    case "web-security-headers": securityHeaders
    case "web-secure-cookies": secureCookies
    case "web-secure-api": secureAPI
    case "mobile-review-permissions": iPhoneVault
    case "mobile-protect-local-data": mobileTrafficInspector
    case "mobile-transport-security": secureTransport
    case "mobile-app-privacy": appPrivacy
    case "mobile-release-review": releaseReview
    case "mobile-secure-logging": secureLogging
    case "mobile-data-flow-privacy": dataFlowPrivacy
    default: nil
    }
  }

  private static func generatedLab(for lesson: LearningLesson, index: Int) -> LabDefinition {
    let targetAddress = "192.0.2.\(100 + index)"
    let objectiveID = "review"
    let flagValue = "CIPHER{\(lesson.id.replacingOccurrences(of: "-", with: "_").uppercased())}"
    return LabDefinition(
      id: "lab-\(lesson.id)",
      title: lesson.title,
      targetAddress: targetAddress,
      allowedPrograms: ["cat"],
      rules: [
        LabRule(
          command: .cat(path: "/lesson/briefing.txt"),
          output: "topic=\(lesson.summary)\\nanswer=\(flagValue)",
          discovery: "Przeanalizowano przygotowany materiał",
          objectiveID: objectiveID
        )
      ],
      objectives: [
        LabObjective(id: objectiveID, title: "Przeanalizuj materiał lekcji")
      ],
      flags: [
        LabFlag(
          id: "review",
          value: flagValue,
          answer: "Materiał przeanalizowany",
          requiredObjectiveIDs: [objectiveID]
        )
      ],
      suggestedCommands: ["cat /lesson/briefing.txt"],
      defenseSummary: "Ćwiczenie działa wyłącznie na fikcyjnych danych offline i kończy się defensywną rekomendacją."
    )
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
        command: .ls(path: "/"),
        output: "training/",
        discovery: "Odnaleziono katalog training"
      ),
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
        command: .cat(path: "/training/briefing.txt"),
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
    suggestedCommands: ["ls", "cd training", "ls", "cat briefing.txt"],
    defenseSummary: "Przed wykonaniem polecenia sprawdź katalog i pliki. Rozpoczynaj od operacji tylko do odczytu i unikaj pracy na sekretach."
  )

  private static let securityEvidence = LabDefinition(
    id: "security-evidence",
    title: "Dowody i notatki",
    targetAddress: "192.0.2.14",
    allowedPrograms: ["find", "ls", "cat", "sha256sum"],
    rules: [
      LabRule(
        command: .ls(path: "/case"),
        output: "notes\nsource",
        discovery: "Odnaleziono katalogi notes i source"
      ),
      LabRule(
        command: .ls(path: "/case/source"),
        output: "auth.log",
        discovery: "Odnaleziono źródłowy plik auth.log"
      ),
      LabRule(
        command: .ls(path: "/case/notes"),
        output: "(brak widocznych plików)",
        discovery: "Zwykłe listowanie nie pokazało zawartości katalogu notes"
      ),
      LabRule(
        command: .lsAll(path: "/case/notes"),
        output: ".\n..\n.template.txt",
        discovery: "Odnaleziono ukryty szablon notatki",
        objectiveID: "inventory"
      ),
      LabRule(
        command: .find(arguments: ["/case", "-type", "f"]),
        output: "/case/source/auth.log\n/case/notes/.template.txt",
        discovery: "Odnaleziono oryginalny log i pusty szablon notatki",
        objectiveID: "inventory"
      ),
      LabRule(
        command: .sha256sum(path: "/case/source/auth.log"),
        output: "7dfb4cf67742f5d225ae876c95c98a83  /case/source/auth.log",
        discovery: "Zapisano sumę kontrolną materiału źródłowego",
        objectiveID: "integrity"
      ),
      LabRule(
        command: .cat(path: "/case/notes/.template.txt"),
        output: "time=11:42\nsource=auth.log\nobservation=failed login burst\nsecrets=do not copy\nCIPHER{NOTE_FACTS_NOT_SECRETS}",
        discovery: "Notatka zawiera fakty i odwołanie do dowodu, ale nie sekrety",
        objectiveID: "notes"
      ),
    ],
    objectives: [
      LabObjective(id: "inventory", title: "Znajdź materiał źródłowy i szablon"),
      LabObjective(id: "integrity", title: "Ustal sumę kontrolną dowodu"),
      LabObjective(id: "notes", title: "Odczytaj bezpieczny format notatki"),
    ],
    flags: [
      LabFlag(
        id: "evidence", value: "CIPHER{NOTE_FACTS_NOT_SECRETS}",
        answer: "Notuj fakty i odwołania, ale nie sekrety",
        requiredObjectiveIDs: ["inventory", "integrity", "notes"]
      )
    ],
    suggestedCommands: [
      "ls /case",
      "ls /case/source",
      "ls /case/notes",
      "ls -la /case/notes",
      "sha256sum /case/source/auth.log",
      "cat /case/notes/.template.txt",
    ],
    defenseSummary: "Zachowuj oryginał dowodu, zapisuj jego sumę kontrolną i dokumentuj fakty. Nie kopiuj haseł, tokenów ani kluczy do notatek."
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

  private static let incidentNotes = LabDefinition(
    id: "incident-notes",
    title: "Pierwsza reakcja na incydent",
    targetAddress: "192.0.2.24",
    allowedPrograms: ["find", "cat", "id"],
    rules: [
      LabRule(
        command: .find(arguments: ["/incident", "-type", "f"]),
        output: "/incident/alert.txt\n/incident/playbook.txt\n/incident/evidence/session.log",
        discovery: "Dostępne są alert, playbook i zapis podejrzanej sesji",
        objectiveID: "collect"
      ),
      LabRule(
        command: .cat(path: "/incident/playbook.txt"),
        output: "1 preserve evidence\n2 validate scope\n3 isolate after preserve\n4 recover and review",
        discovery: "Playbook wymaga zabezpieczenia śladów przed izolacją",
        objectiveID: "sequence"
      ),
      LabRule(
        command: .id,
        output: "responder uid=1002 groups=evidence-readonly\nCIPHER{PRESERVE_VALIDATE_CONTAIN}",
        discovery: "Rola respondera ma wyłącznie dostęp do odczytu materiału",
        objectiveID: "role"
      ),
    ],
    objectives: [
      LabObjective(id: "collect", title: "Zidentyfikuj dostępny materiał"),
      LabObjective(id: "sequence", title: "Ustal kolejność pierwszej reakcji"),
      LabObjective(id: "role", title: "Potwierdź bezpieczne uprawnienia analityka"),
    ],
    flags: [
      LabFlag(
        id: "response", value: "CIPHER{PRESERVE_VALIDATE_CONTAIN}",
        answer: "Zachowaj ślady, potwierdź zakres, potem izoluj",
        requiredObjectiveIDs: ["collect", "sequence", "role"]
      )
    ],
    suggestedCommands: [
      "find /incident -type f",
      "cat /incident/playbook.txt",
      "id",
    ],
    defenseSummary: "Pierwsza reakcja powinna zachować dowody, potwierdzić zakres i dopiero potem ograniczyć zagrożenie. Każdy krok zapisuj z czasem."
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
        command: .ssh(destination: "192.0.2.31"),
        output: "Konto szkoleniowe: trainee@192.0.2.31\nPołącz się ponownie z podaną nazwą użytkownika.",
        discovery: "Odnaleziono nazwę kontrolowanego konta szkoleniowego"
      ),
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

  private static let defensiveReport = LabDefinition(
    id: "defensive-report",
    title: "Raport z rekomendacją",
    targetAddress: "192.0.2.34",
    allowedPrograms: ["nmap", "curl", "cat"],
    rules: [
      LabRule(
        command: .nmap(options: ["-sV"], target: "192.0.2.34"),
        output: "8080/tcp open http TrainingConsole 1.1",
        discovery: "Konsola szkoleniowa jest wystawiona na porcie 8080",
        objectiveID: "evidence"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.34:8080"),
        output: "HTTP/1.1 200 OK\nTrainingConsole\nstatus=/status",
        discovery: "Konsola wskazuje ścieżkę statusu"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.34:8080/status"),
        output: "HTTP/1.1 200 OK\nauth=disabled\ndata=deployment-status",
        discovery: "Status wdrożenia jest dostępny bez uwierzytelnienia",
        objectiveID: "impact"
      ),
      LabRule(
        command: .cat(path: "/report/remediation.txt"),
        output: "evidence=8080 open\nimpact=deployment data exposed\nfix=require authentication and restrict network\nCIPHER{EVIDENCE_IMPACT_FIX}",
        discovery: "Raport łączy dowód, wpływ i możliwą do wdrożenia naprawę",
        objectiveID: "recommendation"
      ),
    ],
    objectives: [
      LabObjective(id: "evidence", title: "Zbierz powtarzalny dowód"),
      LabObjective(id: "impact", title: "Opisz rzeczywisty wpływ"),
      LabObjective(id: "recommendation", title: "Dobierz konkretną naprawę"),
    ],
    flags: [
      LabFlag(
        id: "report", value: "CIPHER{EVIDENCE_IMPACT_FIX}",
        answer: "Raport łączy dowód, wpływ i naprawę",
        requiredObjectiveIDs: ["evidence", "impact", "recommendation"]
      )
    ],
    suggestedCommands: [
      "nmap -sV 192.0.2.34",
      "curl http://192.0.2.34:8080/status",
      "cat /report/remediation.txt",
    ],
    defenseSummary: "Dobry raport oddziela dowód od oceny wpływu i zawiera możliwą do sprawdzenia naprawę: uwierzytelnienie oraz ograniczenie dostępu sieciowego."
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
        output: "HTTP/1.1 200 OK\nServer: Lantern/2.4\n\nWelcome. Robot rules: /robots.txt",
        discovery: "Strona sugeruje sprawdzenie reguł dla robotów"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.40/robots.txt"),
        output: "User-agent: *\nDisallow: /backup/",
        discovery: "Plik robots.txt ujawnia katalog /backup/",
        objectiveID: "clue"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.40/backup/"),
        output: "Index of /backup/\nnote.txt",
        discovery: "Katalog kopii zapasowej ujawnia plik note.txt"
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
        output: "HTTP/1.1 200 OK\nAccess-Control-Allow-Origin: *\nX-Debug-Mode: enabled\nDebug endpoint: /api/debug",
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
        command: .curl(url: "http://192.0.2.42"),
        output: "Training Session API\nEndpoints: /login, /security-review",
        discovery: "Strona startowa wskazuje endpointy sesji"
      ),
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

  private static let accessControl = LabDefinition(
    id: "access-control",
    title: "Kontrola dostępu",
    targetAddress: "192.0.2.43",
    allowedPrograms: ["curl"],
    rules: [
      LabRule(
        command: .curl(url: "http://192.0.2.43"),
        output: "Access Lab\nEndpoints: /access-matrix, /as-viewer/records/admin, /security-review",
        discovery: "Strona startowa wskazuje zasoby kontroli dostępu"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.43/access-matrix"),
        output: "resource=/records/admin\nadmin=allow\nviewer=deny",
        discovery: "Macierz wymaga odrzucenia roli viewer dla danych administratora",
        objectiveID: "policy"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.43/as-viewer/records/admin"),
        output: "HTTP/1.1 200 OK\nviewer=200 admin-record",
        discovery: "Serwer błędnie udostępnia rekord administratora roli viewer",
        objectiveID: "verify"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.43/security-review"),
        output: "expected=403 Forbidden\ncontrol=authorize every object request\nCIPHER{DENY_VIEWER_ADMIN_OBJECT}",
        discovery: "Kontrola powinna zwracać 403 i sprawdzać każdy obiekt",
        objectiveID: "remediation"
      ),
    ],
    objectives: [
      LabObjective(id: "policy", title: "Odczytaj oczekiwaną macierz dostępu"),
      LabObjective(id: "verify", title: "Sprawdź odpowiedź dla roli viewer"),
      LabObjective(id: "remediation", title: "Ustal właściwą kontrolę serwera"),
    ],
    flags: [
      LabFlag(
        id: "access", value: "CIPHER{DENY_VIEWER_ADMIN_OBJECT}",
        answer: "Rola viewer nie może odczytać obiektu administratora",
        requiredObjectiveIDs: ["policy", "verify", "remediation"]
      )
    ],
    suggestedCommands: [
      "curl http://192.0.2.43/access-matrix",
      "curl http://192.0.2.43/as-viewer/records/admin",
      "curl http://192.0.2.43/security-review",
    ],
    defenseSummary: "Autoryzację sprawdzaj po stronie serwera dla każdego żądania i obiektu. Ukrycie przycisku w interfejsie nie zastępuje kontroli dostępu."
  )

  private static let securityHeaders = LabDefinition(
    id: "security-headers",
    title: "Nagłówki ochronne",
    targetAddress: "192.0.2.44",
    allowedPrograms: ["curl"],
    rules: [
      LabRule(
        command: .curl(url: "http://192.0.2.44"),
        output: "HTTP/1.1 200 OK\nContent-Type: text/html\nContent-Security-Policy: missing\nStrict-Transport-Security: missing\nX-Content-Type-Options: missing\nReview paths: /security-policy, /security-review",
        discovery: "Odpowiedź nie zawiera trzech oczekiwanych nagłówków ochronnych",
        objectiveID: "inspect"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.44/security-policy"),
        output: "require_https=true\ncsp=default-src 'self'\nx_content_type_options=nosniff",
        discovery: "Polityka opisuje wymagane zabezpieczenia odpowiedzi",
        objectiveID: "policy"
      ),
      LabRule(
        command: .curl(url: "http://192.0.2.44/security-review"),
        output: "fix=HTTPS,HSTS,CSP,nosniff\nCIPHER{HEADERS_REDUCE_BROWSER_RISK}",
        discovery: "Przegląd łączy wymuszenie HTTPS z ochroną przeglądarki",
        objectiveID: "remediation"
      ),
    ],
    objectives: [
      LabObjective(id: "inspect", title: "Sprawdź nagłówki odpowiedzi"),
      LabObjective(id: "policy", title: "Porównaj je z polityką aplikacji"),
      LabObjective(id: "remediation", title: "Dobierz brakujące zabezpieczenia"),
    ],
    flags: [
      LabFlag(
        id: "headers", value: "CIPHER{HEADERS_REDUCE_BROWSER_RISK}",
        answer: "Nagłówki ochronne ograniczają ryzyko w przeglądarce",
        requiredObjectiveIDs: ["inspect", "policy", "remediation"]
      )
    ],
    suggestedCommands: [
      "curl http://192.0.2.44",
      "curl http://192.0.2.44/security-policy",
      "curl http://192.0.2.44/security-review",
    ],
    defenseSummary: "Wymuszaj HTTPS, dodaj HSTS, restrykcyjne CSP i nosniff. Nagłówki wspierają ochronę, ale nie zastępują walidacji i autoryzacji serwera."
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
        output: "80/tcp open http TrainingAPI 1.0\n443/tcp closed https\nDocumentation: /security-note",
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
        output: "NSAppTransportSecurity\nNSAllowsArbitraryLoads=true\nprofile_endpoint=http://192.0.2.52/profile",
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

  private static let appPrivacy = LabDefinition(
    id: "app-privacy",
    title: "Prywatność aplikacji",
    targetAddress: "192.0.2.53",
    allowedPrograms: ["find", "cat"],
    rules: [
      LabRule(
        command: .find(arguments: ["/privacy", "-type", "f"]),
        output: "/privacy/data-usage.txt\n/privacy/PrivacyInfo.xcprivacy",
        discovery: "Odnaleziono opis użycia danych oraz manifest prywatności",
        objectiveID: "inventory"
      ),
      LabRule(
        command: .cat(path: "/privacy/data-usage.txt"),
        output: "device_id=local diagnostics\nlocation=unused\ncontacts=unused\ntracking=false",
        discovery: "Aplikacja używa wyłącznie lokalnego identyfikatora diagnostycznego",
        objectiveID: "usage"
      ),
      LabRule(
        command: .cat(path: "/privacy/PrivacyInfo.xcprivacy"),
        output: "collected_data=device_id\npurpose=app_functionality\nlinked=false\ntracking=false\nCIPHER{DECLARE_ONLY_USED_DATA}",
        discovery: "Manifest odpowiada faktycznemu użyciu danych",
        objectiveID: "declaration"
      ),
    ],
    objectives: [
      LabObjective(id: "inventory", title: "Znajdź opis danych i manifest prywatności"),
      LabObjective(id: "usage", title: "Ustal faktyczne użycie danych"),
      LabObjective(id: "declaration", title: "Porównaj użycie z deklaracją"),
    ],
    flags: [
      LabFlag(
        id: "privacy", value: "CIPHER{DECLARE_ONLY_USED_DATA}",
        answer: "Deklaruj wyłącznie faktycznie używane dane",
        requiredObjectiveIDs: ["inventory", "usage", "declaration"]
      )
    ],
    suggestedCommands: [
      "find /privacy -type f",
      "cat /privacy/data-usage.txt",
      "cat /privacy/PrivacyInfo.xcprivacy",
    ],
    defenseSummary: "Inwentaryzuj dane przed wydaniem, usuwaj zbędne zbieranie i utrzymuj manifest prywatności zgodny z rzeczywistym działaniem aplikacji."
  )

  private static let releaseReview = LabDefinition(
    id: "release-review",
    title: "Kontrola przed wydaniem",
    targetAddress: "192.0.2.54",
    allowedPrograms: ["find", "cat", "sha256sum"],
    rules: [
      LabRule(
        command: .find(arguments: ["/release", "-type", "f"]),
        output: "/release/NorthbyteLab.ipa\n/release/checklist.txt\n/release/expected.sha256",
        discovery: "Pakiet, lista kontrolna i zaufana suma są gotowe do przeglądu",
        objectiveID: "inventory"
      ),
      LabRule(
        command: .sha256sum(path: "/release/NorthbyteLab.ipa"),
        output: "6f1ed002ab5595859014ebf0951522d9  /release/NorthbyteLab.ipa",
        discovery: "Suma pakietu odpowiada wartości przygotowanej do wydania",
        objectiveID: "integrity"
      ),
      LabRule(
        command: .cat(path: "/release/checklist.txt"),
        output: "privacy_manifest=pass\npermissions=minimum\ntracking=none\nsecrets=none\nbundle_integrity=pass\nCIPHER{RELEASE_CHECKS_COMPLETE}",
        discovery: "Lista kontroli potwierdza prywatność, minimalne uprawnienia i brak sekretów",
        objectiveID: "checklist"
      ),
    ],
    objectives: [
      LabObjective(id: "inventory", title: "Znajdź komplet artefaktów wydania"),
      LabObjective(id: "integrity", title: "Sprawdź integralność paczki"),
      LabObjective(id: "checklist", title: "Zweryfikuj listę kontroli wydania"),
    ],
    flags: [
      LabFlag(
        id: "release", value: "CIPHER{RELEASE_CHECKS_COMPLETE}",
        answer: "Wydanie spełnia kompletną listę kontroli",
        requiredObjectiveIDs: ["inventory", "integrity", "checklist"]
      )
    ],
    suggestedCommands: [
      "find /release -type f",
      "sha256sum /release/NorthbyteLab.ipa",
      "cat /release/checklist.txt",
    ],
    defenseSummary: "Przed wydaniem sprawdź prywatność, uprawnienia, sekrety, podpis i integralność paczki. Wynik zapisuj jako powtarzalną listę kontrolną."
  )

  private static let dnsResolution = LabDefinition(
    id: "dns-resolution", title: "DNS i rozwiązywanie nazw", targetAddress: "192.0.2.60", allowedPrograms: ["cat"],
    rules: [
      LabRule(command: .cat(path: "/dns/a-record.txt"), output: "A app.training.test 192.0.2.60", discovery: "Odczytano rekord A", objectiveID: "a-record"),
      LabRule(command: .cat(path: "/dns/private.txt"), output: "192.168.10.24 = private address", discovery: "Adres należy do zakresu prywatnego", objectiveID: "private-address"),
      LabRule(command: .cat(path: "/dns/cname.txt"), output: "portal.training.test CNAME legacy.training.test", discovery: "Znaleziono alias CNAME", objectiveID: "cname"),
      LabRule(command: .cat(path: "/dns/config.txt"), output: "public-api.training.test A 10.0.0.7", discovery: "Publiczna nazwa wskazuje na prywatny adres", objectiveID: "bad-config"),
      LabRule(command: .cat(path: "/dns/recommendation.txt"), output: "split-horizon DNS; remove private address from public zone; review CNAME CIPHER{DNS_REVIEW_COMPLETE}", discovery: "Rekomendacja ogranicza ujawnienie topologii", objectiveID: "recommendation"),
    ],
    objectives: [
      LabObjective(id: "a-record", title: "Odczytaj rekord A"),
      LabObjective(id: "private-address", title: "Rozpoznaj prywatny adres"),
      LabObjective(id: "cname", title: "Przeanalizuj rekord CNAME"),
      LabObjective(id: "bad-config", title: "Wykryj błędną konfigurację"),
      LabObjective(id: "recommendation", title: "Wybierz bezpieczną rekomendację"),
    ],
    flags: [LabFlag(id: "dns", value: "CIPHER{DNS_REVIEW_COMPLETE}", answer: "Ukryj prywatne adresy w publicznej strefie i kontroluj aliasy", requiredObjectiveIDs: ["a-record", "private-address", "cname", "bad-config", "recommendation"])],
    suggestedCommands: ["cat /dns/a-record.txt", "cat /dns/private.txt", "cat /dns/cname.txt", "cat /dns/config.txt", "cat /dns/recommendation.txt"],
    defenseSummary: "Publiczne rekordy DNS nie powinny ujawniać prywatnej topologii. Weryfikuj aliasy i rozdziel strefy publiczne od wewnętrznych."
  )

  private static let leastPrivilege = LabDefinition(
    id: "least-privilege", title: "Najmniejsze uprawnienia", targetAddress: "192.0.2.61", allowedPrograms: ["cat"],
    rules: [
      LabRule(command: .cat(path: "/permissions/owner.txt"), output: "owner=deploy group=app mode=0640", discovery: "Właścicielem jest konto wdrożeniowe", objectiveID: "owner"),
      LabRule(command: .cat(path: "/permissions/mode.txt"), output: "backup.sh mode=0666 world-writable", discovery: "Plik może modyfikować każdy użytkownik", objectiveID: "wide-mode"),
      LabRule(command: .cat(path: "/permissions/access.txt"), output: "service: read; deploy: read/write; others: none", discovery: "Dostęp można ograniczyć do roli usługi i wdrożenia", objectiveID: "access"),
      LabRule(command: .cat(path: "/permissions/admin.txt"), output: "shared-admin used by four operators", discovery: "Wspólne konto utrudnia rozliczalność", objectiveID: "admin-risk"),
      LabRule(command: .cat(path: "/permissions/fix.txt"), output: "chown deploy:app backup.sh; chmod 0640 backup.sh; individual accounts CIPHER{LEAST_PRIVILEGE_APPLIED}", discovery: "Poprawka przywraca zasadę najmniejszych uprawnień", objectiveID: "fix"),
    ],
    objectives: [
      LabObjective(id: "owner", title: "Przeanalizuj właściciela pliku"),
      LabObjective(id: "wide-mode", title: "Rozpoznaj zbyt szerokie uprawnienia"),
      LabObjective(id: "access", title: "Wybierz właściwy poziom dostępu"),
      LabObjective(id: "admin-risk", title: "Wskaż ryzyko konta administratora"),
      LabObjective(id: "fix", title: "Przygotuj poprawkę"),
    ],
    flags: [LabFlag(id: "permissions", value: "CIPHER{LEAST_PRIVILEGE_APPLIED}", answer: "Ogranicz zapis i zastąp wspólne konto indywidualnymi kontami", requiredObjectiveIDs: ["owner", "wide-mode", "access", "admin-risk", "fix"])],
    suggestedCommands: ["cat /permissions/owner.txt", "cat /permissions/mode.txt", "cat /permissions/access.txt", "cat /permissions/admin.txt", "cat /permissions/fix.txt"],
    defenseSummary: "Nadaj tylko niezbędny dostęp, używaj indywidualnych kont i regularnie przeglądaj właścicieli oraz tryby plików."
  )

  private static let suspiciousMessage = LabDefinition(
    id: "suspicious-message", title: "Analiza podejrzanej wiadomości", targetAddress: "192.0.2.62", allowedPrograms: ["cat"],
    rules: [
      LabRule(command: .cat(path: "/message/headers.txt"), output: "From: payroll@payrolI.training.test\nReply-To: review@external.test", discovery: "Nagłówki pokazują rozbieżność nadawcy i odpowiedzi", objectiveID: "headers"),
      LabRule(command: .cat(path: "/message/domain.txt"), output: "payrolI.training.test != payroll.training.test", discovery: "Domena używa podobnego znaku zamiast właściwej nazwy", objectiveID: "domain"),
      LabRule(command: .cat(path: "/message/urgency.txt"), output: "PAY NOW within 10 minutes or account will close", discovery: "Wiadomość wywiera presję czasu", objectiveID: "urgency"),
      LabRule(command: .cat(path: "/message/risk.txt"), output: "risk=high; credential theft likely", discovery: "Klasyfikacja ryzyka jest wysoka", objectiveID: "risk"),
      LabRule(command: .cat(path: "/message/response.txt"), output: "do not click; report; verify through known channel CIPHER{PHISHING_TRIAGE_COMPLETE}", discovery: "Bezpieczna reakcja nie używa linku z wiadomości", objectiveID: "response"),
    ],
    objectives: [
      LabObjective(id: "headers", title: "Odczytaj nagłówki"),
      LabObjective(id: "domain", title: "Rozpoznaj fałszywą domenę"),
      LabObjective(id: "urgency", title: "Wykryj pilną manipulację"),
      LabObjective(id: "risk", title: "Sklasyfikuj ryzyko"),
      LabObjective(id: "response", title: "Wybierz bezpieczną reakcję"),
    ],
    flags: [LabFlag(id: "message", value: "CIPHER{PHISHING_TRIAGE_COMPLETE}", answer: "Nie klikaj, zgłoś wiadomość i zweryfikuj ją znanym kanałem", requiredObjectiveIDs: ["headers", "domain", "urgency", "risk", "response"])],
    suggestedCommands: ["cat /message/headers.txt", "cat /message/domain.txt", "cat /message/urgency.txt", "cat /message/risk.txt", "cat /message/response.txt"],
    defenseSummary: "Traktuj rozbieżne domeny i presję czasu jako sygnały ostrzegawcze. Weryfikuj prośby niezależnym, znanym kanałem."
  )

  private static let alertPrioritization = LabDefinition(
    id: "alert-prioritization", title: "Priorytetyzacja alertów", targetAddress: "192.0.2.63", allowedPrograms: ["cat"],
    rules: [
      LabRule(command: .cat(path: "/alerts/info.txt"), output: "INFO backup completed successfully", discovery: "To zdarzenie informacyjne, nie incydent", objectiveID: "classification"),
      LabRule(command: .cat(path: "/alerts/correlation.txt"), output: "08:10 failed login; 08:11 new admin token; 08:12 export started", discovery: "Zdarzenia tworzą jeden łańcuch", objectiveID: "correlation"),
      LabRule(command: .cat(path: "/alerts/severity.txt"), output: "severity=critical; privileged account and data export", discovery: "Incydent wymaga najwyższego priorytetu", objectiveID: "severity"),
      LabRule(command: .cat(path: "/alerts/first-action.txt"), output: "preserve evidence; contain token; notify owner", discovery: "Pierwsze działanie chroni dowody i ogranicza dostęp", objectiveID: "first-action"),
      LabRule(command: .cat(path: "/alerts/summary.txt"), output: "Possible token misuse led to a privileged export; evidence preserved CIPHER{ALERT_TRIAGE_COMPLETE}", discovery: "Podsumowanie jest krótkie i oparte na faktach", objectiveID: "summary"),
    ],
    objectives: [
      LabObjective(id: "classification", title: "Odróżnij informację od incydentu"),
      LabObjective(id: "correlation", title: "Połącz kilka zdarzeń"),
      LabObjective(id: "severity", title: "Wyznacz poziom ważności"),
      LabObjective(id: "first-action", title: "Wybierz pierwsze działanie"),
      LabObjective(id: "summary", title: "Przygotuj krótkie podsumowanie"),
    ],
    flags: [LabFlag(id: "alerts", value: "CIPHER{ALERT_TRIAGE_COMPLETE}", answer: "Połącz zdarzenia, zachowaj dowody i ogranicz token", requiredObjectiveIDs: ["classification", "correlation", "severity", "first-action", "summary"])],
    suggestedCommands: ["cat /alerts/info.txt", "cat /alerts/correlation.txt", "cat /alerts/severity.txt", "cat /alerts/first-action.txt", "cat /alerts/summary.txt"],
    defenseSummary: "Łącz powiązane sygnały, oceniaj wpływ i zaczynaj od zachowania dowodów oraz ograniczenia aktywnego zagrożenia."
  )

  private static let threatModeling = LabDefinition(
    id: "threat-modeling", title: "Modelowanie zagrożeń", targetAddress: "192.0.2.64", allowedPrograms: ["cat"],
    rules: [
      LabRule(command: .cat(path: "/model/assets.txt"), output: "assets=customer records; signing key; admin console", discovery: "Zidentyfikowano zasoby o różnej wartości", objectiveID: "assets"),
      LabRule(command: .cat(path: "/model/actor.txt"), output: "actor=external opportunist with stolen credentials", discovery: "Aktor wykorzystuje przejęte dane logowania", objectiveID: "actor"),
      LabRule(command: .cat(path: "/model/entry-point.txt"), output: "entry=public login endpoint", discovery: "Punktem wejścia jest publiczny endpoint logowania", objectiveID: "entry"),
      LabRule(command: .cat(path: "/model/impact.txt"), output: "impact=record disclosure and unauthorized signing", discovery: "Skutek obejmuje ujawnienie i nadużycie podpisu", objectiveID: "impact"),
      LabRule(command: .cat(path: "/model/control.txt"), output: "controls=MFA; least privilege; key isolation; monitoring CIPHER{THREAT_MODEL_COMPLETE}", discovery: "Kontrole ograniczają prawdopodobieństwo i wpływ", objectiveID: "control"),
    ],
    objectives: [
      LabObjective(id: "assets", title: "Zidentyfikuj zasoby"),
      LabObjective(id: "actor", title: "Wskaż aktora zagrożenia"),
      LabObjective(id: "entry", title: "Znajdź punkt wejścia"),
      LabObjective(id: "impact", title: "Określ skutek"),
      LabObjective(id: "control", title: "Wybierz kontrolę obronną"),
    ],
    flags: [LabFlag(id: "model", value: "CIPHER{THREAT_MODEL_COMPLETE}", answer: "Chroń zasoby kontrolami dopasowanymi do punktu wejścia i wpływu", requiredObjectiveIDs: ["assets", "actor", "entry", "impact", "control"])],
    suggestedCommands: ["cat /model/assets.txt", "cat /model/actor.txt", "cat /model/entry-point.txt", "cat /model/impact.txt", "cat /model/control.txt"],
    defenseSummary: "Modeluj zasoby, aktorów, punkty wejścia i skutki, a następnie dobieraj kontrole do konkretnego ryzyka."
  )

  private static let controlledReport = LabDefinition(
    id: "controlled-report", title: "Raport z kontrolowanego testu", targetAddress: "192.0.2.65", allowedPrograms: ["cat"],
    rules: [
      LabRule(command: .cat(path: "/report/scope.txt"), output: "scope=training-api; window=09:00-10:00; no production", discovery: "Zakres nie obejmuje produkcji", objectiveID: "scope"),
      LabRule(command: .cat(path: "/report/facts.txt"), output: "fact=demo endpoint returned 403 for viewer and 200 for owner", discovery: "Fakt jest oddzielony od interpretacji", objectiveID: "facts"),
      LabRule(command: .cat(path: "/report/impact.txt"), output: "impact=unauthorized record visibility if role check regresses", discovery: "Wpływ opisuje warunek i skutek", objectiveID: "impact"),
      LabRule(command: .cat(path: "/report/fix.txt"), output: "fix=enforce server-side role check; add regression test", discovery: "Rekomendacja jest konkretna i defensywna", objectiveID: "fix"),
      LabRule(command: .cat(path: "/report/owner.txt"), output: "owner=API team; reviewer=security; due=next sprint CIPHER{CONTROLLED_REPORT_COMPLETE}", discovery: "Raport ma właściciela i termin", objectiveID: "owner"),
    ],
    objectives: [
      LabObjective(id: "scope", title: "Opisz zakres"),
      LabObjective(id: "facts", title: "Oddziel fakty od założeń"),
      LabObjective(id: "impact", title: "Oceń wpływ"),
      LabObjective(id: "fix", title: "Zarekomenduj naprawę"),
      LabObjective(id: "owner", title: "Przygotuj raport dla właściciela"),
    ],
    flags: [LabFlag(id: "report", value: "CIPHER{CONTROLLED_REPORT_COMPLETE}", answer: "Raportuj zakres, dowody, wpływ i właściciela naprawy", requiredObjectiveIDs: ["scope", "facts", "impact", "fix", "owner"])],
    suggestedCommands: ["cat /report/scope.txt", "cat /report/facts.txt", "cat /report/impact.txt", "cat /report/fix.txt", "cat /report/owner.txt"],
    defenseSummary: "Dobry raport ogranicza zakres, rozdziela fakty od założeń, opisuje wpływ i kończy się właścicielem naprawy."
  )

  private static let secureCookies = LabDefinition(
    id: "secure-cookies", title: "Bezpieczne sesje i cookies", targetAddress: "192.0.2.66", allowedPrograms: ["cat"],
    rules: [
      LabRule(command: .cat(path: "/cookies/flags.txt"), output: "session=abc; Secure=missing; HttpOnly=missing; SameSite=Lax", discovery: "Odczytano wszystkie flagi sesji", objectiveID: "flags"),
      LabRule(command: .cat(path: "/cookies/secure.txt"), output: "Secure missing: cookie may travel over HTTP", discovery: "Brak Secure zwiększa ryzyko przechwycenia", objectiveID: "secure"),
      LabRule(command: .cat(path: "/cookies/httponly.txt"), output: "HttpOnly missing: scripts can read session", discovery: "Brak HttpOnly ułatwia odczyt przez skrypt", objectiveID: "httponly"),
      LabRule(command: .cat(path: "/cookies/samesite.txt"), output: "SameSite=Lax; acceptable for standard navigation; review cross-site flows", discovery: "SameSite wymaga oceny przepływu aplikacji", objectiveID: "samesite"),
      LabRule(command: .cat(path: "/cookies/config.txt"), output: "Secure; HttpOnly; SameSite=Lax; short expiry; rotate on login CIPHER{SESSION_FLAGS_REVIEWED}", discovery: "Konfiguracja ogranicza kradzież i replay sesji", objectiveID: "config"),
    ],
    objectives: [
      LabObjective(id: "flags", title: "Odczytaj flagi cookie"),
      LabObjective(id: "secure", title: "Rozpoznaj brak Secure"),
      LabObjective(id: "httponly", title: "Rozpoznaj brak HttpOnly"),
      LabObjective(id: "samesite", title: "Oceń SameSite"),
      LabObjective(id: "config", title: "Wybierz poprawną konfigurację"),
    ],
    flags: [LabFlag(id: "cookies", value: "CIPHER{SESSION_FLAGS_REVIEWED}", answer: "Włącz Secure i HttpOnly oraz dobierz SameSite do przepływu", requiredObjectiveIDs: ["flags", "secure", "httponly", "samesite", "config"])],
    suggestedCommands: ["cat /cookies/flags.txt", "cat /cookies/secure.txt", "cat /cookies/httponly.txt", "cat /cookies/samesite.txt", "cat /cookies/config.txt"],
    defenseSummary: "Sesje powinny używać Secure, HttpOnly i właściwego SameSite, z krótkim czasem życia oraz rotacją po logowaniu."
  )

  private static let secureAPI = LabDefinition(
    id: "secure-api", title: "Bezpieczne API", targetAddress: "192.0.2.67", allowedPrograms: ["cat"],
    rules: [
      LabRule(command: .cat(path: "/api/authz.txt"), output: "GET /records/42 -> 200 for viewer; owner check missing", discovery: "Endpoint nie sprawdza uprawnienia do konkretnego rekordu", objectiveID: "authz"),
      LabRule(command: .cat(path: "/api/authn.txt"), output: "authentication=valid token; authorization=not evaluated", discovery: "Uwierzytelnienie nie oznacza autoryzacji", objectiveID: "authn"),
      LabRule(command: .cat(path: "/api/data.txt"), output: "response includes email, phone, internal_notes", discovery: "Odpowiedź zwraca nadmiarowe pola", objectiveID: "data"),
      LabRule(command: .cat(path: "/api/rate-limit.txt"), output: "no limit; 10,000 requests per minute accepted", discovery: "Brakuje limitowania żądań", objectiveID: "rate-limit"),
      LabRule(command: .cat(path: "/api/fix.txt"), output: "authorize resource owner; return minimal fields; rate limit and audit CIPHER{API_CONTROLS_COMPLETE}", discovery: "Poprawka łączy kontrolę dostępu, minimalizację i limit", objectiveID: "fix"),
    ],
    objectives: [
      LabObjective(id: "authz", title: "Rozpoznaj brak autoryzacji"),
      LabObjective(id: "authn", title: "Odróżnij uwierzytelnienie od uprawnień"),
      LabObjective(id: "data", title: "Wykryj nadmiarowe dane"),
      LabObjective(id: "rate-limit", title: "Wybierz limitowanie żądań"),
      LabObjective(id: "fix", title: "Zaproponuj poprawkę"),
    ],
    flags: [LabFlag(id: "api", value: "CIPHER{API_CONTROLS_COMPLETE}", answer: "Sprawdzaj właściciela zasobu, zwracaj minimum i limituj żądania", requiredObjectiveIDs: ["authz", "authn", "data", "rate-limit", "fix"])],
    suggestedCommands: ["cat /api/authz.txt", "cat /api/authn.txt", "cat /api/data.txt", "cat /api/rate-limit.txt", "cat /api/fix.txt"],
    defenseSummary: "API musi egzekwować autoryzację po stronie serwera, zwracać minimalny zakres danych i ograniczać nadużycia."
  )

  private static let secureLogging = LabDefinition(
    id: "secure-logging", title: "Bezpieczne logowanie aplikacji", targetAddress: "192.0.2.68", allowedPrograms: ["cat"],
    rules: [
      LabRule(command: .cat(path: "/logs/app.log"), output: "login user=alex token=sk_test_12345 password=present", discovery: "Log zawiera sekret i hasło", objectiveID: "secret"),
      LabRule(command: .cat(path: "/logs/classification.txt"), output: "diagnostic=timing; sensitive=token,password,session_cookie", discovery: "Dane diagnostyczne trzeba oddzielić od wrażliwych", objectiveID: "classification"),
      LabRule(command: .cat(path: "/logs/level.txt"), output: "release level=warning; redact identifiers; no secrets", discovery: "Poziom warning ogranicza szczegóły w wydaniu", objectiveID: "level"),
      LabRule(command: .cat(path: "/logs/debug.txt"), output: "debug build enabled verbose network tracing", discovery: "Debug build może ujawniać dane i konfigurację", objectiveID: "debug"),
      LabRule(command: .cat(path: "/logs/release.txt"), output: "secrets=none; redaction=on; debug=off; review=approved CIPHER{SAFE_LOGGING_RELEASE}", discovery: "Checklista wydania blokuje sekrety w logach", objectiveID: "release"),
    ],
    objectives: [
      LabObjective(id: "secret", title: "Znajdź sekret w logu"),
      LabObjective(id: "classification", title: "Odróżnij dane diagnostyczne od wrażliwych"),
      LabObjective(id: "level", title: "Wybierz bezpieczny poziom logowania"),
      LabObjective(id: "debug", title: "Wskaż ryzyko debug builda"),
      LabObjective(id: "release", title: "Przejdź checklistę przed wydaniem"),
    ],
    flags: [LabFlag(id: "logging", value: "CIPHER{SAFE_LOGGING_RELEASE}", answer: "Usuń sekrety, redaguj dane i wyłącz debug przed wydaniem", requiredObjectiveIDs: ["secret", "classification", "level", "debug", "release"])],
    suggestedCommands: ["cat /logs/app.log", "cat /logs/classification.txt", "cat /logs/level.txt", "cat /logs/debug.txt", "cat /logs/release.txt"],
    defenseSummary: "Logi powinny pomagać diagnozować problemy bez przechowywania sekretów. Redaguj dane i wyłącz debug w wydaniu."
  )

  private static let dataFlowPrivacy = LabDefinition(
    id: "data-flow-privacy", title: "Przepływ danych i prywatność", targetAddress: "192.0.2.69", allowedPrograms: ["cat"],
    rules: [
      LabRule(command: .cat(path: "/privacy/data.txt"), output: "data=email; precise_location; device_id; crash_count", discovery: "Zidentyfikowano dane osobowe i techniczne", objectiveID: "personal-data"),
      LabRule(command: .cat(path: "/privacy/purpose.txt"), output: "purpose=account recovery needs email; crash report needs crash_count", discovery: "Cel powinien uzasadniać konkretny typ danych", objectiveID: "purpose"),
      LabRule(command: .cat(path: "/privacy/permission.txt"), output: "location permission requested but feature never reads location", discovery: "Uprawnienie lokalizacji jest zbędne", objectiveID: "permission"),
      LabRule(command: .cat(path: "/privacy/minimum.txt"), output: "collect coarse region only; hash device identifier; retain briefly", discovery: "Minimalny zakres zmniejsza ryzyko", objectiveID: "minimum"),
      LabRule(command: .cat(path: "/privacy/decision.txt"), output: "remove location permission; document purpose; offer opt-out CIPHER{PRIVACY_BY_DESIGN_COMPLETE}", discovery: "Decyzja realizuje privacy-by-design", objectiveID: "decision"),
    ],
    objectives: [
      LabObjective(id: "personal-data", title: "Wskaż dane osobowe"),
      LabObjective(id: "purpose", title: "Określ cel użycia"),
      LabObjective(id: "permission", title: "Wykryj zbędne uprawnienie"),
      LabObjective(id: "minimum", title: "Wybierz minimalny zakres danych"),
      LabObjective(id: "decision", title: "Podejmij decyzję privacy-by-design"),
    ],
    flags: [LabFlag(id: "privacy-flow", value: "CIPHER{PRIVACY_BY_DESIGN_COMPLETE}", answer: "Zbieraj minimum, uzasadnij cel i usuń zbędne uprawnienie", requiredObjectiveIDs: ["personal-data", "purpose", "permission", "minimum", "decision"])],
    suggestedCommands: ["cat /privacy/data.txt", "cat /privacy/purpose.txt", "cat /privacy/permission.txt", "cat /privacy/minimum.txt", "cat /privacy/decision.txt"],
    defenseSummary: "Projektuj przepływ danych od celu i minimalizacji. Każde uprawnienie powinno mieć rzeczywiste, opisane uzasadnienie."
  )
}
