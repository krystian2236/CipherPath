import Testing

@testable import CipherPath

@Suite("Lab command parser")
struct LabCommandParserTests {
  @Test("Recognizes the safe starter command set")
  func recognizesSafeCommands() {
    #expect(LabCommandParser.parse("krg -help") == .command(.help))
    #expect(LabCommandParser.parse("help").isRejected)
    #expect(!LabCommandParser.parse("run").isRejected)
    #expect(!LabCommandParser.parse("ip").isRejected)
    #expect(
      LabCommandParser.parse("ping 10.10.0.12")
        == .command(.ping(target: "10.10.0.12"))
    )
    #expect(
      LabCommandParser.parse("nmap -sC -sV 10.10.0.12")
        == .command(.nmap(options: ["-sC", "-sV"], target: "10.10.0.12"))
    )
    #expect(
      LabCommandParser.parse("curl http://10.10.0.12/robots.txt")
        == .command(.curl(url: "http://10.10.0.12/robots.txt"))
    )
    #expect(LabCommandParser.parse("cat user.txt") == .command(.cat(path: "user.txt")))
    #expect(
      LabCommandParser.parse("ls -la /case/notes")
        == .command(.lsAll(path: "/case/notes"))
    )
    #expect(!LabCommandParser.parse("sha256sum /evidence/app.bin").isRejected)
  }

  @Test("Normalizes harmless whitespace")
  func normalizesWhitespace() {
    #expect(
      LabCommandParser.parse("  nmap   -sC  -sV   10.10.0.12  ")
        == .command(.nmap(options: ["-sC", "-sV"], target: "10.10.0.12"))
    )
  }

  @Test("Rejects empty input, shell operators, and unknown programs")
  func rejectsUnsafeOrUnknownInput() {
    #expect(LabCommandParser.parse("   ").isRejected)
    #expect(LabCommandParser.parse("ping 10.10.0.12; whoami").isRejected)
    #expect(LabCommandParser.parse("cat user.txt | head").isRejected)
    #expect(LabCommandParser.parse("ping 10.10.0.12 && id").isRejected)
    #expect(LabCommandParser.parse("cat user.txt > copy.txt").isRejected)
    #expect(LabCommandParser.parse("python exploit.py").isRejected)
  }
}

@Suite("Offline lab engine")
struct LabEngineTests {
  private let definition = LabDefinition(
    id: "network-scout",
    title: "Network Scout",
    targetAddress: "10.10.0.12",
    allowedPrograms: ["ping", "nmap"],
    rules: [
      LabRule(
        command: .ping(target: "10.10.0.12"),
        output: "3 packets transmitted, 3 received",
        discovery: "Host odpowiada",
        objectiveID: "availability"
      ),
      LabRule(
        command: .nmap(options: ["-sC", "-sV"], target: "10.10.0.12"),
        output: "22/tcp open ssh\n80/tcp open http\nCIPHER{SCOUT_READY}",
        discovery: "Porty 22 i 80",
        objectiveID: "services"
      ),
    ],
    objectives: [
      LabObjective(id: "availability", title: "Sprawdź dostępność hosta"),
      LabObjective(id: "services", title: "Rozpoznaj usługi"),
    ],
    flags: [
      LabFlag(
        id: "user",
        value: "CIPHER{SCOUT_READY}",
        answer: "Scout gotowy",
        requiredObjectiveIDs: ["availability", "services"]
      )
    ],
    suggestedCommands: ["ping 10.10.0.12", "nmap -sC -sV 10.10.0.12"],
    defenseSummary: "Otwarty port nie oznacza automatycznie podatności."
  )

  @Test("Starts the offline lab from the terminal and reveals its assigned address")
  func startsFromTerminalAndReportsOfflineAddress() {
    var session = LabSession(definitionID: definition.id)

    let stoppedHelp = LabEngine.execute("krg -help", definition: definition, session: &session)
    let run = LabEngine.execute("run", definition: definition, session: &session)
    let help = LabEngine.execute("krg -help", definition: definition, session: &session)
    let ip = LabEngine.execute("ip", definition: definition, session: &session)

    #expect(stoppedHelp.status == .machineStopped)
    #expect(run.status == .success)
    #expect(session.isRunning)
    #expect(run.output == "Jeśli chcesz uzyskać pomoc, wpisz krg -help.")
    #expect(help.status == .success)
    #expect(help.output.contains("krg -help"))
    #expect(help.output.contains("ip"))
    #expect(ip.status == .success)
    #expect(ip.output == "lab0: 10.10.0.12\nnetwork: offline simulation")
    #expect(session.history.map(\.command) == ["krg -help", "ip"])
  }

  @Test("Requires the virtual machine to be started")
  func requiresStartedSession() {
    var session = LabSession(definitionID: definition.id)

    let result = LabEngine.execute(
      "ping 10.10.0.12", definition: definition, session: &session
    )

    #expect(result.status == .machineStopped)
    #expect(session.history.isEmpty)
  }

  @Test("Returns deterministic fixtures and records discoveries")
  func executesConfiguredRulesDeterministically() {
    var firstSession = LabSession(definitionID: definition.id)
    var secondSession = LabSession(definitionID: definition.id)
    LabEngine.start(session: &firstSession)
    LabEngine.start(session: &secondSession)

    let firstPing = LabEngine.execute(
      "ping 10.10.0.12", definition: definition, session: &firstSession
    )
    let secondPing = LabEngine.execute(
      "ping 10.10.0.12", definition: definition, session: &secondSession
    )
    let scan = LabEngine.execute(
      "nmap -sC -sV 10.10.0.12", definition: definition, session: &firstSession
    )

    #expect(firstPing == secondPing)
    #expect(firstPing.output == "3 packets transmitted, 3 received")
    #expect(
      scan.output
        == "22/tcp open ssh\n80/tcp open http\n[✓] ❯ Odpowiedź: Scout gotowy"
    )
    #expect(scan.revealedAnswer == "Scout gotowy")
    #expect(!scan.output.contains("CIPHER{"))
    #expect(firstSession.discoveries == ["Host odpowiada", "Porty 22 i 80"])
    #expect(firstSession.completedObjectiveIDs == ["availability", "services"])
    #expect(firstSession.history.count == 2)
  }

  @Test("Rejects another target and commands outside the mission allowlist")
  func rejectsTargetsAndProgramsOutsideDefinition() {
    var session = LabSession(definitionID: definition.id)
    LabEngine.start(session: &session)

    let otherTarget = LabEngine.execute(
      "ping 8.8.8.8", definition: definition, session: &session
    )
    let unavailableProgram = LabEngine.execute(
      "cat user.txt", definition: definition, session: &session
    )

    #expect(otherTarget.status == .targetRejected)
    #expect(unavailableProgram.status == .programRejected)
    #expect(session.history.isEmpty)
  }

  @Test("Unlocks a readable answer only after its objectives")
  func validatesAnswerPrerequisites() {
    var session = LabSession(definitionID: definition.id)
    LabEngine.start(session: &session)

    #expect(
      LabEngine.submit(
        answer: "Scout gotowy", definition: definition, session: &session
      ) == .locked(requiredObjectiveIDs: ["availability", "services"])
    )
    _ = LabEngine.execute("ping 10.10.0.12", definition: definition, session: &session)
    #expect(
      LabEngine.submit(
        answer: "Scout gotowy", definition: definition, session: &session
      ) == .locked(requiredObjectiveIDs: ["services"])
    )
    _ = LabEngine.execute(
      "nmap -sC -sV 10.10.0.12", definition: definition, session: &session
    )
    #expect(
      LabEngine.submit(answer: "Błędna odpowiedź", definition: definition, session: &session)
        == .incorrect
    )
    #expect(
      LabEngine.submit(
        answer: "  scout GOTOWY  ", definition: definition, session: &session
      ) == .accepted(flagID: "user")
    )
    #expect(
      LabEngine.submit(
        answer: "Scout gotowy", definition: definition, session: &session
      ) == .alreadyCaptured(flagID: "user")
    )
    #expect(session.capturedFlagIDs == ["user"])
  }

  @Test("Help lists only mission programs and clear removes terminal history")
  func handlesBuiltInTerminalCommands() {
    var session = LabSession(definitionID: definition.id)
    LabEngine.start(session: &session)

    let help = LabEngine.execute("krg -help", definition: definition, session: &session)
    _ = LabEngine.execute("ping 10.10.0.12", definition: definition, session: &session)
    let clear = LabEngine.execute("clear", definition: definition, session: &session)

    #expect(help.status == .success)
    #expect(help.output.contains("krg -help —"))
    #expect(help.output.contains("ip —"))
    #expect(help.output.contains("Programy misji: nmap, ping"))
    #expect(clear.status == .success)
    #expect(session.history.isEmpty)
  }

  @Test("Assistance purchase messages explain charges and missing points")
  func assistancePurchaseMessagesAreReadable() {
    #expect(
      AssistancePurchaseMessage(result: .purchased, purchase: .hint).text
        == "Podpowiedź odblokowana za 20 pkt."
    )
    #expect(
      AssistancePurchaseMessage(result: .alreadyUnlocked, purchase: .solution).text
        == "Ta pomoc jest już odblokowana."
    )
    #expect(
      AssistancePurchaseMessage(result: .insufficient(missing: 10), purchase: .hint).text
        == "Brakuje 10 pkt, aby odblokować tę pomoc."
    )
  }

  @Test("Mission points summary shows reward spending and net change")
  func missionPointsSummaryShowsNetChange() {
    let summary = MissionPointsSummary(reward: 100, spent: 20)

    #expect(summary.net == 80)
    #expect(summary.text == "100 − 20 = 80 pkt")
  }
}
