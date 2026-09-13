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

      Section("Tryb") {
        Picker("Sposób gry", selection: $mode) {
          Text("Prowadzony").tag(LabMode.guided)
          Text("Przygodowy").tag(LabMode.adventure)
            .disabled(!progressStore.canStartLab(lessonID: lesson.id, mode: .adventure))
        }
        .pickerStyle(.segmented)
        .onChange(of: mode) { _, newMode in
          if !progressStore.canStartLab(lessonID: lesson.id, mode: newMode) {
            mode = .guided
          }
          resetSession()
        }

        if distribution == .appStore,
           !progressStore.canStartLab(lessonID: lesson.id, mode: .adventure) {
          Label("Tryb przygodowy odblokuje się po ukończeniu trybu prowadzonego.", systemImage: "lock.fill")
            .font(.caption)
            .foregroundStyle(.secondary)
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
              revealTextHint = true
              _ = progressStore.recordAssistance(
                lessonID: lesson.id,
                mode: mode,
                level: .hint
              )
            }
            .disabled(revealTextHint)

            Button("Pokaż polecenia") {
              revealCommands = true
              _ = progressStore.recordAssistance(
                lessonID: lesson.id,
                mode: mode,
                level: .solution
              )
            }
            .disabled(revealCommands)
          }
          .buttonStyle(.bordered)
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
        }
      }
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
    if progressStore.completeLab(lessonID: lesson.id, mode: mode) {
      completionSummary = LabCompletionSummary(
        reward: reward,
        assistance: assistance,
        elapsedSeconds: max(0, Date().timeIntervalSince(startedAt))
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
    startedAt = Date()
    completionSummary = nil
  }
}

private struct LabCompletionSummary {
  let reward: LabReward
  let assistance: LabAssistanceLevel
  let elapsedSeconds: TimeInterval

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
