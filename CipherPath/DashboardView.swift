import SwiftUI

struct FutureFeaturePreview: Identifiable, Equatable, Sendable {
  let id: String
  let title: String
  let subtitle: String
  let icon: String
  let isEnabled: Bool
}

enum FutureFeatureCatalog {
  static let previews = [
    FutureFeaturePreview(id: "points", title: "Punkty", subtitle: "Zdobywaj je za ukończone ćwiczenia", icon: "sparkles", isEnabled: true),
    FutureFeaturePreview(id: "store", title: "Northbyte Lab Pro", subtitle: "Jednorazowe odblokowanie w przygotowaniu", icon: "lock.fill", isEnabled: false),
  ]
}

struct DashboardView: View {
  @Binding var selectedTab: AppTab
  @ObservedObject var progressStore: LearningProgressStore
  @ObservedObject var scanner: NetworkScanner
  @ObservedObject var knownDeviceStore: KnownDeviceStore

  private var availableLessons: [LearningLesson] {
    StarterCurriculum.lessons.filter { ContentAccessPolicy.current.access(for: $0) == .included }
  }

  private var completedLessons: Int {
    availableLessons.filter { progressStore.isCompleted(lessonID: $0.id) }.count
  }

  private var completedStages: Int {
    availableLessons.reduce(0) { partialResult, lesson in
      partialResult + progressStore.progress.completedStages[lesson.id, default: []].count
    }
  }

  private var totalStages: Int {
    availableLessons.reduce(0) { $0 + $1.stages.count }
  }

  private var tutorialLesson: LearningLesson {
    availableLessons.first { $0.id == "fundamentals-digital-safety" }
      ?? availableLessons.first
      ?? StarterCurriculum.lessons[0]
  }

  private var taskLessons: [LearningLesson] {
    availableLessons.filter { $0.id != tutorialLesson.id }
  }

  private var tutorialIsComplete: Bool {
    progressStore.isCompleted(lessonID: tutorialLesson.id)
  }

  private var hasStartedTasks: Bool {
    taskLessons.contains { !progressStore.progress.completedStages[$0.id, default: []].isEmpty }
  }

  private var currentTask: LearningLesson? {
    if let lastLesson = progressStore.continueLesson,
       taskLessons.contains(where: { $0.id == lastLesson.id }),
       progressStore.currentStage(for: lastLesson) != nil {
      return lastLesson
    }
    return taskLessons.first { progressStore.currentStage(for: $0) != nil }
  }

  private var firstUnfinishedTask: LearningLesson? {
    taskLessons.first { !progressStore.isCompleted(lessonID: $0.id) }
  }

  private var primaryLesson: LearningLesson {
    if hasStartedTasks {
      return currentTask ?? firstUnfinishedTask ?? tutorialLesson
    }
    return tutorialIsComplete ? (firstUnfinishedTask ?? tutorialLesson) : tutorialLesson
  }

  private var primaryStageTitle: String? {
    progressStore.currentStage(for: primaryLesson)?.title
  }

  private var progressFraction: Double {
    guard totalStages > 0 else { return 0 }
    return Double(completedStages) / Double(totalStages)
  }

  private var accessSummary: String {
    switch ContentAccessPolicy.current.tier {
    case .free:
      "Free: pierwsza lekcja każdej ścieżki jest dostępna"
    case .testFlightDemo:
      "Demo: dwie pierwsze lekcje każdej ścieżki są dostępne"
    case .pro:
      "Pro: pełny katalog jest dostępny w trybie deweloperskim"
    case .subscription:
      "Subskrypcja: pełny katalog jest dostępny"
    }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          header
          AppReleaseIdentityCard()
          progressSummary
          primaryActionCard
          recentCard
        }
        .padding(18)
        .padding(.bottom, 32)
      }
      .background(Color(red: 0.025, green: 0.045, blue: 0.075).ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
    }
    .preferredColorScheme(.dark)
  }

  private var header: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Cipher") + Text("Path").foregroundStyle(.indigo)
          .font(.largeTitle.bold())
        Text("Ucz się bezpieczeństwa krok po kroku")
          .foregroundStyle(.secondary)
      }

      Spacer()

      HStack(spacing: 8) {
        NavigationLink {
          GlobalSearchView(selectedTab: $selectedTab, progressStore: progressStore)
        } label: {
          Image(systemName: "magnifyingglass")
            .font(.headline.weight(.semibold))
            .foregroundStyle(.cyan)
            .frame(width: 42, height: 42)
            .background(.cyan.opacity(0.12), in: Circle())
        }
        .accessibilityLabel("Szukaj w Northbyte Lab")

        NavigationLink {
          AppSettingsView(progressStore: progressStore)
        } label: {
          Image(systemName: "gearshape.fill")
            .font(.headline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: 42, height: 42)
            .background(.white.opacity(0.08), in: Circle())
        }
        .accessibilityLabel("Ustawienia")
      }
    }
  }

  private var progressSummary: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Label("Postęp nauki", systemImage: "arrow.right")
          .font(.headline)
          .foregroundStyle(.cyan)
        Spacer()
        Text("\(completedLessons) / \(availableLessons.count) lekcji")
          .font(.caption.bold())
          .foregroundStyle(.secondary)
      }
      ProgressView(value: progressFraction)
        .tint(.cyan)
        .accessibilityLabel("Postęp nauki")
        .accessibilityValue("\(completedStages) z \(totalStages) etapów")
      Text(accessSummary)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.cyan.opacity(0.25)))
  }

  private var primaryActionCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(primaryActionTitle, systemImage: primaryActionIcon)
        .font(.title3.bold())
        .foregroundStyle(.indigo)
      Text(primaryLesson.title).font(.title3.bold())
      Text(primaryActionDescription)
        .font(.subheadline)
        .foregroundStyle(.secondary)
      if let primaryStageTitle {
        Label("Aktualny etap: \(primaryStageTitle)", systemImage: "arrow.right.circle")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      NavigationLink {
        LessonFlowView(lesson: primaryLesson, progressStore: progressStore)
      } label: {
        Label(primaryActionButtonTitle, systemImage: "arrow.right.circle.fill")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .tint(.indigo)
    }
    .padding(16)
    .background(.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.indigo.opacity(0.3)))
  }

  private var primaryActionTitle: String {
    if !tutorialIsComplete { return "Samouczek" }
    return hasStartedTasks ? "Kontynuuj" : "Pierwsze zadanie"
  }

  private var primaryActionIcon: String {
    !tutorialIsComplete ? "sparkles" : "arrow.right.circle.fill"
  }

  private var primaryActionDescription: String {
    if !tutorialIsComplete {
      return "Poznaj bezpieczne granice ćwiczeń i przejdź pierwszą lokalną symulację."
    }
    return primaryLesson.summary
  }

  private var primaryActionButtonTitle: String {
    if !tutorialIsComplete {
      return progressStore.currentStage(for: tutorialLesson) == nil ? "Rozpocznij samouczek" : "Kontynuuj samouczek"
    }
    return hasStartedTasks ? "Kontynuuj" : "Rozpocznij zadanie"
  }

  private var recentCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Ostatnie", systemImage: "clock.arrow.circlepath")
        .font(.title3.bold())
        .foregroundStyle(.orange)
      if recentItems.isEmpty {
        Text("Ukończ etap lub zadanie, aby zobaczyć je tutaj.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        ForEach(recentItems) { item in
          HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.icon)
              .foregroundStyle(item.tint)
              .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
              Text(item.title).font(.subheadline.weight(.semibold))
              Text(item.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
              Text(item.date, format: .dateTime.day().month().hour().minute())
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer()
          }
        }
      }
    }
    .padding(14)
    .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
  }

  private var recentItems: [DashboardTimelineItem] {
    progressStore.recentActivities.map {
      DashboardTimelineItem(
        id: "activity-\($0.id)",
        title: $0.title,
        subtitle: $0.kind == .labCompleted ? "Practice" : "Lekcja",
        date: $0.date,
        icon: $0.kind == .labCompleted ? "target" : "book.fill",
        tint: $0.kind == .labCompleted ? .orange : .cyan
      )
    }
    .sorted { $0.date > $1.date }
    .prefix(4)
    .map { $0 }
  }

}

private struct DashboardTimelineItem: Identifiable {
  let id: String
  let title: String
  let subtitle: String
  let date: Date
  let icon: String
  let tint: Color
}

extension LearningPath {
  var shortTitle: String {
    switch self {
    case .webSecurity: "Web"
    case .mobileSecurity: "Mobile"
    case .networkAnalysis: "Sieci"
    case .cloudSecurity: "Cloud"
    case .privacyEngineering: "Prywatność"
    default: title
    }
  }

  var iconName: String {
    switch self {
    case .fundamentals: "book.fill"
    case .blueTeam: "shield.fill"
    case .redTeam: "xmark.shield.fill"
    case .webSecurity: "globe"
    case .mobileSecurity: "iphone"
    case .terminal: "terminal"
    case .networkAnalysis: "network"
    case .cloudSecurity: "cloud.fill"
    case .cryptography: "key.fill"
    case .privacyEngineering: "hand.raised.fill"
    }
  }

  var tint: Color {
    switch self {
    case .fundamentals: .mint
    case .blueTeam: .blue
    case .redTeam: .red
    case .webSecurity: .purple
    case .mobileSecurity: .cyan
    case .terminal: .orange
    case .networkAnalysis: .indigo
    case .cloudSecurity: .teal
    case .cryptography: .yellow
    case .privacyEngineering: .pink
    }
  }
}
