import SwiftUI

struct LabTerminalView: View {
  let definition: LabDefinition
  let lesson: LearningLesson
  @ObservedObject var progressStore: LearningProgressStore

  @State private var session: LabSession
  @State private var commandInput = ""
  @State private var feedback: String?
  @State private var answerInput = ""
  @State private var answerMessage: String?
  @State private var mode: LabMode = .guided
  @State private var revealTextHint = false
  @State private var revealCommands = false
  @State private var startedAt = Date()
  @State private var completionSummary: LabCompletionSummary?
  @State private var pendingPurchase: PointsPurchase?
  @State private var purchaseMessage: String?

  private let distribution = AppDistributionMode.currentBuild

  init(
    definition: LabDefinition,
    lesson: LearningLesson,
    progressStore: LearningProgressStore
  ) {
    self.definition = definition
    self.lesson = lesson
    self.progressStore = progressStore
    _session = State(
      initialValue: progressStore.restoredLabSession(
        lessonID: lesson.id,
        mode: .guided,
        definitionID: definition.id
      )
    )
  }

  var body: some View {
    List {
      Section {
        Label(
          "To całkowicie lokalna symulacja. Polecenia nie opuszczają aplikacji.",
          systemImage: "lock.shield.fill"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
      }

      if distribution.showsAdventureMode {
        Section("Tryb") {
          Picker("Sposób gry", selection: $mode) {
            Text("Prowadzony").tag(LabMode.guided)
            Text("Przygodowy").tag(LabMode.adventure)
          }
          .pickerStyle(.segmented)
          .onChange(of: mode) { _, _ in
            resetSession()
          }
        }
      }

      Section("Wirtualna maszyna") {
        HStack {
          VStack(alignment: .leading, spacing: 3) {
            Text(definition.title).font(.headline)
            Text("Cel: \(definition.targetAddress)")
              .font(.system(.subheadline, design: .monospaced))
          }
          Spacer()
          Label(session.isRunning ? "Aktywna" : "Wyłączona", systemImage: statusIcon)
            .font(.caption.bold())
            .foregroundStyle(session.isRunning ? .green : .secondary)
        }

        if !session.isRunning {
          Button("Uruchom maszynę") {
            LabEngine.start(session: &session)
            startedAt = Date()
          }
          .buttonStyle(.borderedProminent)
        }
      }

      if mode == .guided {
        Section("Cele") {
        ForEach(definition.objectives, id: \.id) { objective in
          Label(
            objective.title,
            systemImage: session.completedObjectiveIDs.contains(objective.id) ? "checkmark.circle.fill" : "circle"
          )
          .foregroundStyle(session.completedObjectiveIDs.contains(objective.id) ? .green : .primary)
        }
      }
      }

      Section("Terminal") {
        terminalOutput

        HStack(alignment: .bottom) {
          TextField("Wpisz polecenie", text: $commandInput, axis: .vertical)
            .font(.system(.body, design: .monospaced))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onSubmit(runCommand)

          Button(action: runCommand) {
            Image(systemName: "arrow.up.circle.fill")
              .font(.title2)
          }
          .disabled(!session.isRunning || commandInput.trimmingCharacters(in: .whitespaces).isEmpty)
          .accessibilityLabel("Wykonaj polecenie")
        }

        if let feedback {
          Label(feedback, systemImage: "exclamationmark.shield.fill")
            .font(.footnote)
            .foregroundStyle(.orange)
        }

        if distribution == .developer || revealCommands {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
              ForEach(definition.suggestedCommands, id: \.self) { command in
                Button(command) {
                  commandInput = command
                }
                  .buttonStyle(.bordered)
                  .font(.system(.caption, design: .monospaced))
              }
            }
          }
        }

        if distribution == .appStore {
          if revealTextHint {
            Label(textHint, systemImage: "lightbulb.fill")
              .font(.footnote)
              .foregroundStyle(.orange)
          }

          HStack {
            Button("Podpowiedź") {
              pendingPurchase = .hint
            }
            .disabled(revealTextHint)

            Button("Pokaż polecenia") {
              pendingPurchase = .solution
            }
            .disabled(revealCommands)
          }
          .buttonStyle(.bordered)

          if let purchaseMessage {
            Text(purchaseMessage)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
      }

      if !session.discoveries.isEmpty {
        Section("Notatnik odkryć") {
          ForEach(session.discoveries, id: \.self) { discovery in
            Label(discovery, systemImage: "checkmark.circle")
          }
        }
      }

      Section("Odpowiedź") {
        TextField("Odnaleziona odpowiedź", text: $answerInput)
          .textInputAutocapitalization(.sentences)
          .autocorrectionDisabled()

        Button("Zatwierdź odpowiedź", action: submitAnswer)
          .buttonStyle(.borderedProminent)
          .disabled(!session.isRunning || answerInput.isEmpty)

        if distribution == .developer {
          Button("Wstaw rozwiązanie deweloperskie") {
            answerInput = nextAnswer
          }
          .buttonStyle(.bordered)
          .disabled(!session.isRunning || nextAnswer.isEmpty)
        }

        if let answerMessage {
          Text(answerMessage)
            .font(.footnote)
            .foregroundStyle(allFlagsCaptured ? .green : .orange)
        }
      }

      if allFlagsCaptured {
        Section("Jak się bronić") {
          Text(definition.defenseSummary)
          Button("Zakończ misję", action: finishMission)
            .buttonStyle(.borderedProminent)
        }
      }

      if let completionSummary {
        Section("Wynik misji") {
          Label("\(completionSummary.reward.xp) XP", systemImage: "bolt.fill")
          Label(completionSummary.reward.grade.rawValue, systemImage: completionSummary.medalIcon)
          Label(completionSummary.elapsedText, systemImage: "clock.fill")
          Text(completionSummary.assistanceText)
            .font(.footnote)
            .foregroundStyle(.secondary)
          if distribution == .appStore {
            Label(completionSummary.points.text, systemImage: "sparkles")
          }
        }
      }
    }
    .onAppear(perform: restoreAssistanceVisibility)
    .confirmationDialog(
      purchaseDialogTitle,
      isPresented: purchaseConfirmationPresented,
      titleVisibility: .visible
    ) {
      if let pendingPurchase {
        Button("Odblokuj za \(pendingPurchase.cost) pkt") {
          unlock(pendingPurchase)
        }
      }
      Button("Anuluj", role: .cancel) {}
    } message: {
      Text("Po potwierdzeniu punkty zostaną odjęte od Twojego salda.")
    }
  }

  private var terminalOutput: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 10) {
        Text(session.isRunning ? "$ Wirtualny host uruchomiony. Wpisz help." : "$ Oczekiwanie na uruchomienie maszyny…")
          .foregroundStyle(.green)

        ForEach(Array(session.history.enumerated()), id: \.offset) { _, entry in
          VStack(alignment: .leading, spacing: 3) {
            Text("$ \(entry.command)").foregroundStyle(.cyan)
            Text(entry.output).foregroundStyle(.white)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(minHeight: 180, maxHeight: 300)
    .padding(12)
    .font(.system(.caption, design: .monospaced))
    .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
    .accessibilityLabel("Historia terminala")
  }

  private var statusIcon: String {
    session.isRunning ? "bolt.horizontal.circle.fill" : "stop.circle"
  }

  private var purchaseDialogTitle: String {
    guard let pendingPurchase else { return "Odblokować pomoc?" }
    return pendingPurchase == .hint ? "Odblokować podpowiedź?" : "Odblokować rozwiązanie?"
  }

  private var purchaseConfirmationPresented: Binding<Bool> {
    Binding(
      get: { pendingPurchase != nil },
      set: { if !$0 { pendingPurchase = nil } }
    )
  }

  private var allFlagsCaptured: Bool {
    session.capturedFlagIDs.count == definition.flags.count
  }

  private var textHint: String {
    if let objective = definition.objectives.first(where: {
      !session.completedObjectiveIDs.contains($0.id)
    }) {
      return "Skup się na celu: \(objective.title)"
    }
    return "Sprawdź odkrycia i dopasuj odpowiedź do wykonanych celów."
  }

  private var nextAnswer: String {
    definition.flags.first(where: { !session.capturedFlagIDs.contains($0.id) })?.answer ?? ""
  }

  private func runCommand() {
    let input = commandInput.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !input.isEmpty else { return }
    let result = LabEngine.execute(input, definition: definition, session: &session)
    feedback = result.status == .success ? nil : result.output
    if result.status == .success {
      if let revealedAnswer = result.revealedAnswer {
        if distribution == .developer {
          answerInput = revealedAnswer
          answerMessage = "Tryb deweloperski: odpowiedź została wpisana automatycznie."
        } else {
          answerMessage = "Odpowiedź jest widoczna w terminalu. Przepisz ją poniżej."
        }
      }
      _ = progressStore.saveCheckpoint(lessonID: lesson.id, mode: mode, session: session)
    }
    commandInput = ""
  }

  private func submitAnswer() {
    switch LabEngine.submit(answer: answerInput, definition: definition, session: &session) {
    case .incorrect:
      answerMessage = "Odpowiedź nie pasuje. Przeanalizuj wyniki jeszcze raz."
    case .locked:
      answerMessage = "Najpierw wykonaj cele prowadzące do tej odpowiedzi."
    case .accepted:
      answerMessage = "Odpowiedź poprawna."
      answerInput = ""
      _ = progressStore.saveCheckpoint(lessonID: lesson.id, mode: mode, session: session)
    case .alreadyCaptured:
      answerMessage = "Ta odpowiedź została już zaliczona."
    }
  }

  private func finishMission() {
    let reward = progressStore.reward(lessonID: lesson.id, mode: mode)
    let assistance = progressStore.labProgress(for: lesson.id).assistanceByMode[mode] ?? .none
    let spent = pointsSpentForCurrentMission
    if progressStore.completeLab(lessonID: lesson.id, mode: mode, distribution: distribution) {
      completionSummary = LabCompletionSummary(
        reward: reward,
        assistance: assistance,
        elapsedSeconds: max(0, Date().timeIntervalSince(startedAt)),
        points: MissionPointsSummary(
          reward: distribution == .appStore ? 100 : 0,
          spent: spent
        )
      )
      answerMessage = "Misja ukończona. Zdobywasz \(reward.xp) XP i medal: \(reward.grade.rawValue)."
    }
  }

  private func resetSession() {
    session = progressStore.restoredLabSession(
      lessonID: lesson.id,
      mode: mode,
      definitionID: definition.id
    )
    commandInput = ""
    feedback = nil
    answerInput = ""
    answerMessage = nil
    revealTextHint = false
    revealCommands = distribution == .developer
    purchaseMessage = nil
    pendingPurchase = nil
    startedAt = Date()
    completionSummary = nil
    restoreAssistanceVisibility()
  }

  private var pointsSpentForCurrentMission: Int {
    -progressStore.progress.pointsWallet.transactions
      .filter { transaction in
        transaction.lessonID == lesson.id
          && transaction.mode == mode
          && (transaction.kind == .hint || transaction.kind == .solution)
      }
      .reduce(0) { $0 + $1.amount }
  }

  private func unlock(_ purchase: PointsPurchase) {
    let result = progressStore.purchaseAssistance(
      lessonID: lesson.id,
      mode: mode,
      purchase: purchase,
      distribution: distribution
    )
    purchaseMessage = AssistancePurchaseMessage(result: result, purchase: purchase).text
    guard result == .purchased || result == .alreadyUnlocked else { return }
    if purchase == .hint {
      revealTextHint = true
    } else {
      revealCommands = true
    }
  }

  private func restoreAssistanceVisibility() {
    let assistance = progressStore.labProgress(for: lesson.id).assistanceByMode[mode] ?? .none
    revealTextHint = distribution == .appStore && assistance >= .hint
    revealCommands = distribution == .developer || assistance >= .solution
  }
}

private struct LabCompletionSummary {
  let reward: LabReward
  let assistance: LabAssistanceLevel
  let elapsedSeconds: TimeInterval
  let points: MissionPointsSummary

  var elapsedText: String {
    let seconds = Int(elapsedSeconds.rounded())
    return "\(seconds / 60) min \(seconds % 60) s"
  }

  var assistanceText: String {
    switch assistance {
    case .none: "Rozwiązanie samodzielne — pełna punktacja."
    case .hint: "Użyto podpowiedzi tekstowej."
    case .solution: "Użyto gotowego polecenia lub rozwiązania."
    }
  }

  var medalIcon: String {
    switch reward.grade {
    case .gold: "medal.fill"
    case .silver: "shield.lefthalf.filled"
    case .bronze: "seal.fill"
    }
  }
}
