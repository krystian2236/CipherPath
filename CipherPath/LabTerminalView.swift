import SwiftUI
import UIKit

struct LabTerminalView: View {
  let definition: LabDefinition
  let lesson: LearningLesson
  @ObservedObject var progressStore: LearningProgressStore
  let onFinish: (() -> Void)?
  @Environment(\.dismiss) private var dismiss

  @State private var session: LabSession
  @State private var commandInput = ""
  @State private var commandCursorOffset = 0
  @State private var commandHistory: [String] = []
  @State private var commandHistoryIndex: Int?
  @State private var padDirection: TerminalPadDirection?
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
  @State private var isCommandFieldFocused = false
  @State private var hasEnteredKRG = false
  @State private var displayState: LessonDisplayState
  @State private var launchedLessonID: String?

  private let distribution = AppDistributionMode.currentBuild
  private let terminalBottomID = "terminal-bottom"

  init(
    definition: LabDefinition,
    lesson: LearningLesson,
    progressStore: LearningProgressStore,
    onFinish: (() -> Void)? = nil
  ) {
    self.definition = definition
    self.lesson = lesson
    self.progressStore = progressStore
    self.onFinish = onFinish
    var initialSession = progressStore.restoredLabSession(
        lessonID: lesson.id,
        mode: .guided,
        definitionID: definition.id
      )
    if progressStore.hasTerminalUnlock(.run), progressStore.hasTerminalUnlock(.krg) {
      initialSession.isRunning = true
    }
    _session = State(initialValue: initialSession)
    _commandInput = State(initialValue: "")
    _hasEnteredKRG = State(initialValue: initialSession.isRunning)
    _displayState = State(initialValue:
      progressStore.labProgress(for: lesson.id).completedModes.contains(.guided)
        ? .completed
        : (initialSession.isRunning ? .active : .start)
    )
  }

  var body: some View {
    Group {
      switch displayState {
      case .start:
        startLesson
      case .active, .incorrect:
        activeTask
      case .hints:
        hintsTask
      case .stepComplete:
        stepComplete
      case .completed:
        completedLesson
      }
    }
    .onAppear(perform: restoreAssistanceVisibility)
    .navigationDestination(item: $launchedLessonID) { lessonID in
      if let nextLesson = StarterCurriculum.lessons.first(where: { $0.id == lessonID }) {
        LessonFlowView(lesson: nextLesson, progressStore: progressStore, onFinish: onFinish)
      } else {
        ContentUnavailableView("Lekcja niedostępna", systemImage: "book.closed")
      }
    }
    .toolbar { lessonToolbar }
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

  private var startLesson: some View {
    let briefing = MissionBriefing.forLesson(lesson)
    return ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text(lesson.title).font(.largeTitle.bold())
        Text(briefing.objective).font(.title3)
        VStack(alignment: .leading, spacing: 8) {
          Label("Czego się nauczysz", systemImage: "brain.head.profile")
            .font(.headline)
          ForEach(briefing.learningOutcomes.prefix(2), id: \.self) {
            Label($0, systemImage: "checkmark.circle.fill")
              .foregroundStyle(.secondary)
          }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        Label(
          "To całkowicie lokalna symulacja. Polecenia nie opuszczają aplikacji.",
          systemImage: "lock.shield.fill"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        Button("Rozpocznij zadanie", action: beginTask)
          .buttonStyle(.borderedProminent)
          .tint(lesson.path.tint)
          .frame(maxWidth: .infinity)
      }
      .padding(20)
    }
  }

  private var activeTask: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        taskProgress
        if case .incorrect = displayState {
          feedbackBanner
        }
        Text("Zadanie").font(.headline)
        Text(currentObjectiveTitle).foregroundStyle(.secondary)
        terminalOutput
        answerEntry
        Button("Potrzebuję podpowiedzi") {
          displayState = LessonDisplayState.transition(from: displayState, on: .requestHint)
          revealFirstHintIfNeeded()
        }
        .buttonStyle(.bordered)
      }
      .padding(20)
    }
  }

  private var hintsTask: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        taskProgress
        Text("Podpowiedzi").font(.headline)
        Text("Podpowiedź \(hintLevel) z 2").font(.caption.bold()).foregroundStyle(.secondary)
        Label(textHint, systemImage: "lightbulb.fill")
          .foregroundStyle(.orange)
        if hintLevel >= 2 {
          Label(concreteHint, systemImage: "lightbulb.max.fill")
            .foregroundStyle(.orange)
        }
        terminalOutput
        answerEntry
        if hintLevel < 2 {
          Button("Pokaż bardziej konkretną podpowiedź") {
            displayState = LessonDisplayState.transition(from: displayState, on: .revealNextHint)
          }
          .buttonStyle(.bordered)
        } else if !revealCommands {
          Button("Pokaż rozwiązanie") { pendingPurchase = .solution }
            .buttonStyle(.bordered)
        }
        if revealCommands { solutionCommands }
        if let purchaseMessage {
          Text(purchaseMessage).font(.footnote).foregroundStyle(.secondary)
        }
        Button("Wróć do zadania") {
          displayState = LessonDisplayState.transition(from: displayState, on: .returnToTask)
        }
        .buttonStyle(.bordered)
      }
      .padding(20)
    }
  }

  private var stepComplete: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Label("Krok ukończony", systemImage: "checkmark.circle.fill")
          .font(.title.bold()).foregroundStyle(.green)
        summarySection("Co zrobiłeś", text: completedObjectiveSummary)
        summarySection("Czego się nauczyłeś", text: MissionBriefing.forLesson(lesson).learningOutcomes.prefix(2).joined(separator: " "))
        summarySection("Dlaczego to ważne", text: definition.defenseSummary)
        Button("Zakończ lekcję", action: finishMission)
          .buttonStyle(.borderedProminent)
          .tint(lesson.path.tint)
      }
      .padding(20)
    }
  }

  private var completedLesson: some View {
    let reward = completionSummary?.reward ?? progressStore.reward(lessonID: lesson.id, mode: mode)
    return ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Label("Lekcja ukończona", systemImage: "flag.checkered.circle.fill")
          .font(.title.bold()).foregroundStyle(.green)
        Label("\(reward.xp) XP", systemImage: "bolt.fill")
        if distribution == .appStore {
          Label("\(completionSummary?.points.net ?? 100) pkt", systemImage: "sparkles")
        }
        summarySection("Postęp ścieżki", text: pathProgressText)
        if let achievement = unlockedAchievement {
          Label("Osiągnięcie: \(achievement.title)", systemImage: "rosette")
            .foregroundStyle(.orange)
        }
        summarySection("Co już potrafisz", text: definition.defenseSummary)
        if let nextLesson {
          NavigationLink {
            MissionBriefingView(lesson: nextLesson, progressStore: progressStore)
          } label: {
            Label("Następna lekcja", systemImage: "arrow.right.circle.fill")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .tint(lesson.path.tint)
        } else {
          Button("Wróć do ścieżki", action: leaveLesson)
            .buttonStyle(.borderedProminent)
            .tint(lesson.path.tint)
        }
        HStack {
          Button("Powtórz", action: resetSession).buttonStyle(.bordered)
          NavigationLink("Notatki") { LessonNotesView(lesson: lesson, progressStore: progressStore) }
            .buttonStyle(.bordered)
          Button("Zakładka") { progressStore.toggleBookmark(lessonID: lesson.id) }
            .buttonStyle(.bordered)
        }
      }
      .padding(20)
    }
  }

  private var taskProgress: some View {
    HStack {
      Text("\(min(session.completedObjectiveIDs.count + 1, max(definition.objectives.count, 1))) z \(max(definition.objectives.count, 1))")
        .font(.caption.bold())
      ProgressView(value: Double(session.completedObjectiveIDs.count), total: Double(max(definition.objectives.count, 1)))
        .tint(lesson.path.tint)
    }
  }

  private var feedbackBanner: some View {
    Label(feedback ?? answerMessage ?? "To nie prowadzi do celu. Sprawdź wynik i spróbuj ponownie.", systemImage: "exclamationmark.circle.fill")
      .font(.footnote)
      .foregroundStyle(.orange)
      .padding(12)
      .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
  }

  private var answerEntry: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Odpowiedź").font(.headline)
      HStack(spacing: 10) {
        TextField("CIPHER{...}", text: $answerInput)
          .textInputAutocapitalization(.characters)
          .autocorrectionDisabled()
          .padding(.horizontal, 14)
          .frame(minHeight: 48)
          .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
          .accessibilityLabel("Flaga odpowiedzi")
        Button(action: submitAnswer) {
          Image(systemName: "flag.checkered.circle.fill").frame(width: 48, height: 48)
        }
        .buttonStyle(.borderedProminent)
        .clipShape(Circle())
        .accessibilityLabel("Zatwierdź flagę")
        .disabled(!session.isRunning || answerInput.isEmpty)
      }
      if let answerMessage, displayState != .incorrect {
        Text(answerMessage).font(.footnote).foregroundStyle(.secondary)
      }
    }
  }

  private var solutionCommands: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Rozwiązanie").font(.headline)
      ForEach(definition.suggestedCommands, id: \.self) { command in
        Button(command) {
          commandInput = command
          commandCursorOffset = command.utf16.count
          isCommandFieldFocused = true
        }
        .buttonStyle(.bordered)
        .font(.system(.caption, design: .monospaced))
      }
    }
  }

  @ToolbarContentBuilder
  private var lessonToolbar: some ToolbarContent {
    ToolbarItemGroup(placement: .topBarTrailing) {
      NavigationLink {
        LessonNotesView(lesson: lesson, progressStore: progressStore)
      } label: {
        Image(systemName: progressStore.note(for: lesson.id).isEmpty ? "note.text" : "note.text.badge.plus")
      }
      Button { progressStore.toggleBookmark(lessonID: lesson.id) } label: {
        Image(systemName: progressStore.isBookmarked(lessonID: lesson.id) ? "bookmark.fill" : "bookmark")
      }
      if distribution.showsAdventureMode {
        Menu {
          Picker("Sposób gry", selection: $mode) {
            Text("Prowadzony").tag(LabMode.guided)
            Text("Bez podpowiedzi").tag(LabMode.adventure)
          }
        } label: { Image(systemName: "ellipsis.circle") }
        .onChange(of: mode) { _, _ in resetSession() }
      }
    }
  }

  private var hintLevel: Int {
    if case .hints(let revealed) = displayState { return min(revealed, 2) }
    return 0
  }

  private var currentObjectiveTitle: String {
    definition.objectives.first(where: { !session.completedObjectiveIDs.contains($0.id) })?.title
      ?? "Zbierz dowód i wpisz odpowiedź."
  }

  private var concreteHint: String {
    "Wykonaj działanie związane z celem: \(currentObjectiveTitle)"
  }

  private var completedObjectiveSummary: String {
    session.discoveries.last ?? "Wykonałeś zadanie w lokalnym terminalu i potwierdziłeś odpowiedź."
  }

  private var pathProgressText: String {
    let lessons = StarterCurriculum.lessons(in: lesson.path).filter { $0.availability == .available }
    let completed = lessons.filter { progressStore.isCompleted(lessonID: $0.id) }.count
    return "\(completed) z \(lessons.count) lekcji ukończonych"
  }

  private var nextLesson: LearningLesson? {
    StarterCurriculum.lessons(in: lesson.path).first {
      $0.availability == .available && $0.order == lesson.order + 1
    }
  }

  private var unlockedAchievement: AchievementProgress? {
    AchievementCatalog.evaluateAll(progressStore.progress).first { $0.isUnlocked }
  }

  private func summarySection(_ title: String, text: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).font(.headline)
      Text(text).foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(.background, in: RoundedRectangle(cornerRadius: 16))
  }

  private var terminalOutput: some View {
    VStack(alignment: .leading, spacing: 4) {
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 6) {
            ForEach(Array(session.history.enumerated()), id: \.offset) { _, entry in
              VStack(alignment: .leading, spacing: 3) {
                Text("╭─ krg  \(terminalPath)").foregroundStyle(.cyan)
                Text("╰─[\(entry.command)] ❯").foregroundStyle(.cyan)
                Text(entry.output).foregroundStyle(.white)
              }
            }

            if let feedback {
              Text(feedback)
                .foregroundStyle(.orange)
            }

            Color.clear
              .frame(height: 1)
              .id(terminalBottomID)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: session.isRunning) { _, _ in
          scrollTerminalToBottom(proxy)
        }
        .onChange(of: session.history.count) { _, _ in
          scrollTerminalToBottom(proxy)
        }
        .onChange(of: feedback) { _, _ in
          scrollTerminalToBottom(proxy)
        }
      }

      if session.isRunning {
        Text("╭─ krg  \(terminalPath)")
          .foregroundStyle(.cyan)
        terminalPrompt(prefix: "╰─[")
      } else {
        startTerminalButton
      }
    }
    .frame(maxHeight: 300)
    .padding(12)
    .font(.system(.caption, design: .monospaced))
    .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
    .accessibilityElement(children: .contain)
  }

  private var purchaseDialogTitle: String {
    guard let pendingPurchase else { return "Odblokować pomoc?" }
    return pendingPurchase == .hint ? "Odblokować podpowiedź?" : "Odblokować rozwiązanie?"
  }

  private var terminalPath: String {
    session.currentDirectory == "/" ? "~" : "~\(session.currentDirectory)"
  }

  private func terminalPrompt(prefix: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 0) {
        Text(prefix).foregroundStyle(.cyan)
        commandField
        Text("]").foregroundStyle(.cyan)
      }
      cursorControls
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
  }

  private var commandField: some View {
    TerminalTextField(
      text: $commandInput,
      cursorOffset: $commandCursorOffset,
      isFocused: $isCommandFieldFocused,
      placeholder: hasEnteredKRG ? "help" : "krg",
      onSubmit: runCommand
    )
    .frame(minHeight: 36)
    .accessibilityLabel("Polecenie terminala")
  }

  private var cursorControls: some View {
    Image(systemName: "arrow.up.left.and.arrow.down.right.circle.fill")
      .font(.title2)
      .foregroundStyle(.cyan)
      .frame(width: 52, height: 52)
      .background(.cyan.opacity(0.14), in: Circle())
      .contentShape(Circle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            let direction = TerminalPadDirection.direction(for: value.translation)
            guard direction != padDirection else { return }
            padDirection = direction
            apply(direction)
          }
          .onEnded { value in
            if TerminalPadDirection.direction(for: value.translation) == nil {
              runCommand()
            }
            padDirection = nil
          }
      )
      .accessibilityElement()
      .accessibilityLabel("Sterowanie terminalem")
      .accessibilityHint("Przytrzymaj i przesuń palec w lewo, prawo, górę lub dół")
  }

  private func apply(_ direction: TerminalPadDirection?) {
    guard let direction else { return }
    switch direction {
    case .left:
      moveCursor(by: -1)
    case .right:
      moveCursor(by: 1)
    case .up:
      selectHistory(offset: -1)
    case .down:
      selectHistory(offset: 1)
    }
  }

  private var startTerminalButton: some View {
    Button(action: startTerminal) {
      Label("Uruchom terminal", systemImage: "play.fill")
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
    .buttonStyle(.borderedProminent)
    .tint(.green)
    .accessibilityLabel("Uruchom terminal")
  }

  private func startTerminal() {
    LabEngine.start(session: &session)
    session.history.removeAll()
    commandInput = ""
    commandCursorOffset = 0
    feedback = nil
    hasEnteredKRG = false
    isCommandFieldFocused = true
  }

  private func beginTask() {
    progressStore.beginLesson(lessonID: lesson.id)
    displayState = LessonDisplayState.transition(from: displayState, on: .begin)
    startTerminal()
  }

  private func revealFirstHintIfNeeded() {
    guard !revealTextHint else { return }
    if distribution == .appStore {
      pendingPurchase = .hint
    } else {
      unlock(.hint)
    }
  }

  private func scrollTerminalToBottom(_ proxy: ScrollViewProxy) {
    Task { @MainActor in
      await Task.yield()
      withAnimation(.easeOut(duration: 0.2)) {
        proxy.scrollTo(terminalBottomID, anchor: .bottom)
      }
    }
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

    guard hasEnteredKRG else {
      guard input.caseInsensitiveCompare("krg") == .orderedSame else {
        feedback = "Najpierw wpisz krg."
        isCommandFieldFocused = true
        return
      }
      hasEnteredKRG = true
      session.history.append(LabTerminalEntry(command: input, output: "Terminal krg gotowy."))
      commandInput = ""
      commandCursorOffset = 0
      feedback = nil
      isCommandFieldFocused = true
      return
    }

    if commandHistory.last != input {
      commandHistory.append(input)
    }
    commandHistoryIndex = nil
    let wasRunning = session.isRunning
    let result = LabEngine.execute(input, definition: definition, session: &session)
    if !wasRunning && session.isRunning {
      startedAt = Date()
    }
    feedback = result.status == .success ? nil : result.output
    if result.status == .success {
      if case .incorrect = displayState {
        displayState = .active
      }
    } else {
      displayState = LessonDisplayState.transition(from: displayState, on: .incorrectAnswer)
    }
    if result.status == .success {
      if input.caseInsensitiveCompare("KRG-ORBIT") == .orderedSame {
        progressStore.unlockTerminal(.run)
      } else if input.caseInsensitiveCompare("KRG-VAULT") == .orderedSame {
        progressStore.unlockTerminal(.krg)
      }
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
    commandCursorOffset = 0
    Task { @MainActor in
      isCommandFieldFocused = true
    }
  }

  private func moveCursor(by offset: Int) {
    commandCursorOffset = max(
      0,
      min(commandInput.utf16.count, commandCursorOffset + offset)
    )
    isCommandFieldFocused = true
  }

  private func selectHistory(offset: Int) {
    guard !commandHistory.isEmpty else { return }
    let nextIndex: Int
    if let commandHistoryIndex {
      nextIndex = max(0, min(commandHistory.count - 1, commandHistoryIndex + offset))
    } else {
      nextIndex = offset < 0 ? commandHistory.count - 1 : 0
    }
    commandHistoryIndex = nextIndex
    commandInput = commandHistory[nextIndex]
    commandCursorOffset = commandInput.utf16.count
    isCommandFieldFocused = true
  }

  private func submitAnswer() {
    switch LabEngine.submit(answer: answerInput, definition: definition, session: &session) {
    case .incorrect:
      answerMessage = "Odpowiedź nie pasuje. Przeanalizuj wyniki jeszcze raz."
      displayState = LessonDisplayState.transition(from: displayState, on: .incorrectAnswer)
    case .locked:
      answerMessage = "Najpierw wykonaj cele prowadzące do tej odpowiedzi."
      displayState = LessonDisplayState.transition(from: displayState, on: .incorrectAnswer)
    case .accepted:
      answerMessage = "Odpowiedź poprawna."
      answerInput = ""
      _ = progressStore.saveCheckpoint(lessonID: lesson.id, mode: mode, session: session)
      if allFlagsCaptured {
        displayState = LessonDisplayState.transition(from: displayState, on: .correctAnswer)
      }
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
      if lesson.id == "fundamentals-digital-safety", mode == .guided {
        launchedLessonID = nextLesson?.id
      }
    }
    if progressStore.labProgress(for: lesson.id).completedModes.contains(mode) {
      displayState = LessonDisplayState.transition(from: .stepComplete, on: .finishLesson)
    }
  }

  private func resetSession() {
    session = progressStore.restoredLabSession(
      lessonID: lesson.id,
      mode: mode,
      definitionID: definition.id
    )
    if progressStore.hasTerminalUnlock(.run), progressStore.hasTerminalUnlock(.krg) {
      session.isRunning = true
      hasEnteredKRG = true
    } else {
      hasEnteredKRG = false
    }
    commandInput = ""
    commandCursorOffset = 0
    commandHistoryIndex = nil
    feedback = nil
    answerInput = ""
    answerMessage = nil
    revealTextHint = false
    revealCommands = distribution == .developer && mode.showsGuidance
    purchaseMessage = nil
    pendingPurchase = nil
    startedAt = Date()
    completionSummary = nil
    restoreAssistanceVisibility()
    displayState = .start
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
      displayState = .hints(revealed: 3)
    }
  }

  private func leaveLesson() {
    if let onFinish {
      onFinish()
    } else {
      dismiss()
    }
  }

  private func restoreAssistanceVisibility() {
    let assistance = progressStore.labProgress(for: lesson.id).assistanceByMode[mode] ?? .none
    revealTextHint = distribution == .appStore && assistance >= .hint
    revealCommands = (distribution == .developer && mode.showsGuidance) || assistance >= .solution
  }
}

private enum TerminalPadDirection: Equatable {
  case left
  case right
  case up
  case down

  static func direction(for translation: CGSize) -> Self? {
    let horizontal = abs(translation.width)
    let vertical = abs(translation.height)
    guard max(horizontal, vertical) >= 16 else { return nil }

    if horizontal >= vertical {
      return translation.width < 0 ? .left : .right
    }
    return translation.height < 0 ? .up : .down
  }
}

private struct TerminalTextField: UIViewRepresentable {
  @Binding var text: String
  @Binding var cursorOffset: Int
  @Binding var isFocused: Bool
  let placeholder: String
  let onSubmit: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func makeUIView(context: Context) -> UITextField {
    let textField = UITextField()
    textField.delegate = context.coordinator
    textField.addTarget(
      context.coordinator,
      action: #selector(Coordinator.textChanged(_:)),
      for: .editingChanged
    )
    textField.returnKeyType = .send
    textField.autocapitalizationType = .none
    textField.autocorrectionType = .no
    textField.textColor = .white
    textField.tintColor = .cyan
    textField.accessibilityLabel = "Polecenie terminala"
    return textField
  }

  func updateUIView(_ textField: UITextField, context: Context) {
    context.coordinator.parent = self
    textField.placeholder = placeholder

    if textField.text != text {
      textField.text = text
    }

    if isFocused && !textField.isFirstResponder {
      textField.becomeFirstResponder()
    } else if !isFocused && textField.isFirstResponder {
      textField.resignFirstResponder()
    }

    guard textField.isFirstResponder,
          let start = textField.position(
            from: textField.beginningOfDocument,
            offset: max(0, min(cursorOffset, text.utf16.count))
          )
    else { return }

    let currentOffset = textField.offset(
      from: textField.beginningOfDocument,
      to: textField.selectedTextRange?.start ?? textField.beginningOfDocument
    )
    if currentOffset != cursorOffset {
      textField.selectedTextRange = textField.textRange(from: start, to: start)
    }
  }

  final class Coordinator: NSObject, UITextFieldDelegate {
    var parent: TerminalTextField

    init(_ parent: TerminalTextField) {
      self.parent = parent
    }

    @objc func textChanged(_ textField: UITextField) {
      parent.text = textField.text ?? ""
      parent.cursorOffset = textField.offset(
        from: textField.beginningOfDocument,
        to: textField.selectedTextRange?.start ?? textField.beginningOfDocument
      )
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      parent.onSubmit()
      return false
    }
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
