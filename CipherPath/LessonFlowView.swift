import SwiftUI

struct MissionBriefingView: View {
  let lesson: LearningLesson
  @ObservedObject var progressStore: LearningProgressStore

  private var briefing: MissionBriefing { .forLesson(lesson) }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        DevLocationLabel(location: .briefing)
        VStack(alignment: .leading, spacing: 10) {
          Label(lesson.path.title.uppercased(), systemImage: lesson.path.iconName)
            .font(.caption.bold())
            .foregroundStyle(lesson.path.tint)
          Text(lesson.title)
            .font(.largeTitle.bold())
          Text(briefing.story)
            .font(.body)
            .foregroundStyle(.secondary)
        }

        HStack(spacing: 12) {
          briefingBadge(icon: "clock.fill", text: "\(briefing.estimatedMinutes) min")
          briefingBadge(icon: "gauge.with.dots.needle.33percent", text: briefing.difficulty.rawValue)
          briefingBadge(icon: "wifi.slash", text: "Offline")
        }

        briefingSection("Twoja misja", icon: "scope") {
          Text(briefing.objective)
        }

        briefingSection("Czego się nauczysz", icon: "brain.head.profile") {
          ForEach(briefing.learningOutcomes, id: \.self) { outcome in
            Label(outcome, systemImage: "checkmark.circle.fill")
              .foregroundStyle(.secondary)
          }
        }

        Label(
          "Misja działa wyłącznie na wbudowanych, fikcyjnych danych. Nie atakuje żadnego prawdziwego systemu.",
          systemImage: "lock.shield.fill"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(14)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))

        NavigationLink {
          LessonFlowView(lesson: lesson, progressStore: progressStore)
        } label: {
          Label(
            progressStore.isCompleted(lessonID: lesson.id) ? "Zagraj ponownie" : "Rozpocznij misję",
            systemImage: "play.fill"
          )
          .fontWeight(.semibold)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 13)
        }
        .buttonStyle(.borderedProminent)
        .tint(lesson.path.tint)
      }
      .padding(20)
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle("Odprawa")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func briefingBadge(icon: String, text: String) -> some View {
    Label(text, systemImage: icon)
      .font(.caption.bold())
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .background(.secondary.opacity(0.12), in: Capsule())
  }

  private func briefingSection<Content: View>(
    _ title: String,
    icon: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Label(title, systemImage: icon).font(.headline)
      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(.background, in: RoundedRectangle(cornerRadius: 18))
  }
}

struct LessonMissionContent: Equatable, Sendable {
  let legalNotice: String
  let learnText: String
  let checkPrompt: String
  let offlineEvidence: String
  let expectedFlag: String
  let explanation: String

  func accepts(flag: String) -> Bool {
    flag.trimmingCharacters(in: .whitespacesAndNewlines)
      .caseInsensitiveCompare(expectedFlag) == .orderedSame
  }

  static func availableContent(for lesson: LearningLesson) -> LessonMissionContent? {
    guard lesson.availability == .available else { return nil }
    return content(for: lesson)
  }

  static func content(for lesson: LearningLesson) -> LessonMissionContent {
    let legal = "Ćwiczenie korzysta wyłącznie z wbudowanych, fikcyjnych danych. Nie testuj systemów bez zgody właściciela."

    switch lesson.id {
    case "fundamentals-digital-safety":
      return LessonMissionContent(
        legalNotice: legal,
        learnText: "Legalny test zawsze ma właściciela, pisemną zgodę, określony cel i granice czasowe.",
        checkPrompt: "Sprawdź, czy scenariusz zawiera zgodę i jasno ograniczony zakres.",
        offlineEvidence: "LAB: własny iPhone testowy\nZGODA: potwierdzona\nZAKRES: aplikacja demo\nCZAS: 30 minut",
        expectedFlag: "CIPHER{SCOPE_APPROVED}",
        explanation: "Zgoda i zakres chronią właściciela oraz testera. Czynność poza zakresem nie jest częścią legalnego laboratorium."
      )
    case "fundamentals-read-port-scan":
      return LessonMissionContent(
        legalNotice: legal,
        learnText: "Otwarty port wskazuje usługę nasłuchującą, ale sam nie dowodzi podatności.",
        checkPrompt: "Odszukaj bezpieczną usługę WWW korzystającą z TLS.",
        offlineEvidence: "22/tcp open ssh\n80/tcp closed http\n443/tcp open https",
        expectedFlag: "CIPHER{OPEN_PORT_443}",
        explanation: "Port 443 zwykle obsługuje HTTPS. Wynik jest punktem do defensywnej weryfikacji konfiguracji, nie zgodą na atak."
      )
    case "blue-team-find-log-event":
      return LessonMissionContent(
        legalNotice: legal,
        learnText: "Blue Team szuka odstępstw od normalnego zachowania i łączy je z kontekstem.",
        checkPrompt: "Znajdź wpis oznaczony jako alert logowania.",
        offlineEvidence: "09:10 LOGIN_OK user=demo\n09:14 LOGIN_ALERT user=demo source=unknown\n09:18 LOGOUT user=demo",
        expectedFlag: "CIPHER{LOGIN_ALERT}",
        explanation: "Pojedynczy alert wymaga potwierdzenia. Następny krok obronny to sprawdzenie źródła i historii konta."
      )
    case "blue-team-suspicious-login":
      return LessonMissionContent(
        legalNotice: legal,
        learnText: "Nietypowa lokalizacja lub pora może podnieść ryzyko logowania, ale wymaga kontekstu.",
        checkPrompt: "Wskaż zdarzenie odbiegające od przygotowanej bazy zachowania.",
        offlineEvidence: "08:02 Warsaw device=A OK\n08:05 Warsaw device=A OK\n08:07 Unknown device=Z UNUSUAL_LOCATION",
        expectedFlag: "CIPHER{UNUSUAL_LOCATION}",
        explanation: "Zmiana miejsca i urządzenia w krótkim czasie jest sygnałem do weryfikacji sesji oraz MFA."
      )
    case "red-team-scope-first":
      return LessonMissionContent(
        legalNotice: legal,
        learnText: "Red Team zaczyna od zasad zaangażowania, a nie od narzędzi.",
        checkPrompt: "Znajdź najważniejszą kontrolę przed rozpoczęciem testu.",
        offlineEvidence: "CEL: aplikacja demo\nDOZWOLONE: analiza offline\nZABRONIONE: dane osób trzecich\nREGUŁA: SCOPE_FIRST",
        expectedFlag: "CIPHER{SCOPE_FIRST}",
        explanation: "Zakres określa dozwolone cele i techniki. Gdy czegoś nie obejmuje, tester zatrzymuje się i pyta właściciela."
      )
    case "red-team-threat-thinking":
      return LessonMissionContent(
        legalNotice: legal,
        learnText: "Myślenie ofensywne służy przewidywaniu ryzyka i projektowaniu skuteczniejszej ochrony.",
        checkPrompt: "Znajdź słaby punkt w fikcyjnym formularzu.",
        offlineEvidence: "FORM: komentarz\nLIMIT: brak\nWALIDACJA: WEAK_VALIDATION\nOBRONA: sprawdzaj dane po stronie serwera",
        expectedFlag: "CIPHER{WEAK_VALIDATION}",
        explanation: "Walidacja po stronie serwera ogranicza nieoczekiwane dane. Test pozostaje analizą przygotowanego przykładu."
      )
    case "web-http-anatomy":
      return LessonMissionContent(
        legalNotice: legal,
        learnText: "Odpowiedź HTTP składa się między innymi z kodu stanu, nagłówków i treści.",
        checkPrompt: "Odczytaj kod udanej odpowiedzi z wbudowanego przykładu.",
        offlineEvidence: "HTTP/1.1 200 OK\nContent-Type: application/json\nCache-Control: no-store",
        expectedFlag: "CIPHER{STATUS_200}",
        explanation: "Kod 200 oznacza poprawną obsługę żądania. Nagłówki opisują format i zasady przechowywania odpowiedzi."
      )
    case "web-spot-input-risk":
      return LessonMissionContent(
        legalNotice: legal,
        learnText: "Każde dane wejściowe należy traktować jako niezaufane i walidować zgodnie z oczekiwanym formatem.",
        checkPrompt: "Wybierz brakującą kontrolę w demonstracyjnym formularzu.",
        offlineEvidence: "input: dowolny tekst\nclient_check: true\nserver_check: false\nremediation: VALIDATE_INPUT",
        expectedFlag: "CIPHER{VALIDATE_INPUT}",
        explanation: "Kontrola wyłącznie w aplikacji klienckiej nie wystarcza. Serwer musi niezależnie zweryfikować dane."
      )
    case "mobile-review-permissions":
      return LessonMissionContent(
        legalNotice: legal,
        learnText: "Aplikacja powinna prosić tylko o uprawnienia potrzebne do jasno opisanej funkcji.",
        checkPrompt: "Odczytaj zasadę ograniczającą dostęp aplikacji.",
        offlineEvidence: "camera: potrzebna\nlocation: zbędna\ncontacts: zbędne\nzasada: MINIMUM_ACCESS",
        expectedFlag: "CIPHER{MINIMUM_ACCESS}",
        explanation: "Minimalne uprawnienia ograniczają skutki błędu i lepiej chronią prywatność użytkownika."
      )
    case "mobile-protect-local-data":
      return LessonMissionContent(
        legalNotice: legal,
        learnText: "Sekrety aplikacji nie powinny trafiać do zwykłych preferencji ani jawnych plików.",
        checkPrompt: "Wybierz systemowe miejsce dla małego sekretu aplikacji.",
        offlineEvidence: "UserDefaults: ustawienia\nDocuments: pliki użytkownika\nKEYCHAIN: dane uwierzytelniające",
        expectedFlag: "CIPHER{KEYCHAIN}",
        explanation: "Keychain zapewnia systemową ochronę małych sekretów. CipherPath nie zapisuje w lekcji żadnych prawdziwych danych logowania."
      )
    default:
      return LessonMissionContent(
        legalNotice: legal,
        learnText: lesson.summary,
        checkPrompt: "Przeanalizuj wyłącznie przygotowany materiał offline.",
        offlineEvidence: "SAFE_OFFLINE_SIMULATION",
        expectedFlag: "CIPHER{SAFE_LAB}",
        explanation: "Materiał służy nauce obrony w kontrolowanym środowisku."
      )
    }
  }
}

struct LessonFlowView: View {
  let lesson: LearningLesson
  @ObservedObject var progressStore: LearningProgressStore
  @State private var flagInput = ""
  @State private var flagError = false

  private var content: LessonMissionContent {
    LessonMissionContent.content(for: lesson)
  }

  var body: some View {
    Group {
      if let definition = StarterLabs.definition(for: lesson) {
        LabTerminalView(
          definition: definition,
          lesson: lesson,
          progressStore: progressStore
        )
      } else {
        classicMission
      }
    }
    .navigationTitle(lesson.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private var classicMission: some View {
    List {
      Section {
        Label(content.legalNotice, systemImage: "lock.shield.fill")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Section("Postęp") {
        HStack {
          ForEach(lesson.stages, id: \.self) { stage in
            VStack(spacing: 5) {
              Image(systemName: stageIcon(stage))
                .foregroundStyle(stageColor(stage))
              Text(stage.title).font(.caption2).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
          }
        }
      }

      if let stage = progressStore.currentStage(for: lesson) {
        Section(stage.title) { stageView(stage) }
      } else {
        Section {
          ContentUnavailableView(
            "Misja ukończona",
            systemImage: "flag.checkered.circle.fill",
            description: Text("Postęp został zapisany lokalnie na tym urządzeniu.")
          )
        }
      }
    }
  }

  @ViewBuilder
  private func stageView(_ stage: LessonStage) -> some View {
    switch stage {
    case .learn:
      Text(content.learnText)
      advanceButton("Przejdź do sprawdzenia", stage: stage)
    case .check:
      Text(content.checkPrompt)
      Text(content.offlineEvidence)
        .font(.system(.body, design: .monospaced))
        .textSelection(.enabled)
      advanceButton("Dane sprawdzone", stage: stage)
    case .findFlag:
      Text("Wpisz flagę odnalezioną w materiale powyżej.")
      TextField("CIPHER{...}", text: $flagInput)
        .textInputAutocapitalization(.characters)
        .autocorrectionDisabled()
      if flagError {
        Label("Flaga nie pasuje. Sprawdź materiał jeszcze raz.", systemImage: "exclamationmark.triangle.fill")
          .font(.footnote).foregroundStyle(.orange)
      }
      Button("Sprawdź flagę") {
        if content.accepts(flag: flagInput) {
          flagError = false
          progressStore.complete(stage: stage, lessonID: lesson.id)
        } else {
          flagError = true
        }
      }
      .buttonStyle(.borderedProminent)
    case .explanation:
      Text(content.explanation)
      advanceButton("Zakończ misję", stage: stage)
    }
  }

  private func advanceButton(_ title: String, stage: LessonStage) -> some View {
    Button(title) { progressStore.complete(stage: stage, lessonID: lesson.id) }
      .buttonStyle(.borderedProminent)
  }

  private func stageIcon(_ stage: LessonStage) -> String {
    if progressStore.progress.completedStages[lesson.id, default: []].contains(stage) {
      return "checkmark.circle.fill"
    }
    return progressStore.currentStage(for: lesson) == stage ? "circle.inset.filled" : "circle"
  }

  private func stageColor(_ stage: LessonStage) -> Color {
    progressStore.currentStage(for: lesson) == stage ? .cyan : .secondary
  }
}
