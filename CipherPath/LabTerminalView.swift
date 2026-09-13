import SwiftUI

struct LabTerminalView: View {
  let definition: LabDefinition
  let lesson: LearningLesson
  @ObservedObject var progressStore: LearningProgressStore

  @State private var session: LabSession
  @State private var commandInput = ""
  @State private var feedback: String?
  @State private var flagInput = ""
  @State private var flagMessage: String?
  @State private var mode: LabMode = .guided
  @State private var revealAdventureHints = false

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

        if !progressStore.canStartLab(lessonID: lesson.id, mode: .adventure) {
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

        if mode == .guided || revealAdventureHints {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
              ForEach(definition.suggestedCommands, id: \.self) { command in
                Button(command) {
                  commandInput = command
                  _ = progressStore.recordHint(lessonID: lesson.id, mode: mode)
                }
                  .buttonStyle(.bordered)
                  .font(.system(.caption, design: .monospaced))
              }
            }
          }
        } else {
          Button("Pokaż podpowiedzi") {
            revealAdventureHints = true
            _ = progressStore.recordHint(lessonID: lesson.id, mode: mode)
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

      Section("Flaga") {
        TextField("CIPHER{...}", text: $flagInput)
          .font(.system(.body, design: .monospaced))
          .textInputAutocapitalization(.characters)
          .autocorrectionDisabled()

        Button("Prześlij flagę", action: submitFlag)
          .buttonStyle(.borderedProminent)
          .disabled(!session.isRunning || flagInput.isEmpty)

        if let flagMessage {
          Text(flagMessage)
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

  private func runCommand() {
    let input = commandInput.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !input.isEmpty else { return }
    let result = LabEngine.execute(input, definition: definition, session: &session)
    feedback = result.status == .success ? nil : result.output
    if result.status == .success {
      _ = progressStore.saveCheckpoint(lessonID: lesson.id, mode: mode, session: session)
    }
    commandInput = ""
  }

  private func submitFlag() {
    switch LabEngine.submit(flag: flagInput, definition: definition, session: &session) {
    case .incorrect:
      flagMessage = "Flaga nie pasuje. Przeanalizuj wyniki jeszcze raz."
    case .locked:
      flagMessage = "Najpierw wykonaj cele prowadzące do tej flagi."
    case .accepted:
      flagMessage = "Flaga zdobyta."
      flagInput = ""
      _ = progressStore.saveCheckpoint(lessonID: lesson.id, mode: mode, session: session)
    case .alreadyCaptured:
      flagMessage = "Ta flaga została już zdobyta."
    }
  }

  private func finishMission() {
    if progressStore.completeLab(lessonID: lesson.id, mode: mode) {
      flagMessage = mode == .guided
        ? "Misja ukończona. Odblokowano tryb przygodowy i 100 XP."
        : "Tryb przygodowy ukończony. Zdobywasz 150 XP."
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
    flagInput = ""
    flagMessage = nil
    revealAdventureHints = false
  }
}
