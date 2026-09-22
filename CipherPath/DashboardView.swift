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
    FutureFeaturePreview(id: "store", title: "CipherPath Pro", subtitle: "Jednorazowe odblokowanie w przygotowaniu", icon: "lock.fill", isEnabled: false),
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

  private var nextLesson: LearningLesson? {
    if let current = activeLesson {
      return current
    }
    return availableLessons.first { !progressStore.isCompleted(lessonID: $0.id) }
  }

  private var activeLesson: LearningLesson? {
    guard let lesson = progressStore.continueLesson,
          progressStore.currentStage(for: lesson) != nil else {
      return nil
    }
    return lesson
  }

  private var currentPathIsComplete: Bool {
    guard let lesson = progressStore.continueLesson else { return false }
    let pathLessons = StarterCurriculum.lessons(in: lesson.path).filter {
      ContentAccessPolicy.current.access(for: $0) == .included
    }
    return !pathLessons.isEmpty && pathLessons.allSatisfy {
      progressStore.isCompleted(lessonID: $0.id)
    }
  }

  private var featuredLesson: LearningLesson {
    nextLesson ?? availableLessons.first ?? StarterCurriculum.lessons[0]
  }

  private var featuredStageTitle: String {
    progressStore.currentStage(for: featuredLesson)?.title ?? "Ukończono"
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
          readinessCard
          nextStepCard
          quickActionsCard
          progressTimelineCard
          navigationCards
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
        .accessibilityLabel("Szukaj w CipherPath")

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

  private var readinessCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label("Learning Readiness", systemImage: "checkmark.shield.fill")
        .font(.headline)
        .foregroundStyle(.cyan)
      Text("\(completedLessons) / \(availableLessons.count) tematów ukończonych")
        .font(.title2.bold())
      Text("Postęp nauki, nie pełny audyt urządzenia.")
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(accessSummary)
        .font(.caption2)
        .foregroundStyle(.cyan)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.cyan.opacity(0.25)))
  }

  private var quickActionsCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Szybkie akcje", systemImage: "bolt.fill")
        .font(.title3.bold())
        .foregroundStyle(.orange)

      HStack(spacing: 8) {
        NavigationLink {
          LessonFlowView(lesson: featuredLesson, progressStore: progressStore)
        } label: {
          quickActionLabel(
            activeLesson == nil ? "Rozpocznij" : "Kontynuuj",
            systemImage: "book.fill",
            tint: .indigo
          )
        }
        .keyboardShortcut("l", modifiers: .command)

        Button {
          selectedTab = .practice
        } label: {
          quickActionLabel("Practice", systemImage: "wrench.and.screwdriver.fill", tint: .orange)
        }
        .keyboardShortcut("p", modifiers: .command)

        Button {
          selectedTab = .security
        } label: {
          quickActionLabel("Security", systemImage: "lock.shield.fill", tint: .cyan)
        }
        .buttonStyle(.plain)
        .keyboardShortcut("s", modifiers: .command)
      }
    }
    .padding(14)
    .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
  }

  private func quickActionLabel(_ title: String, systemImage: String, tint: Color) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: systemImage)
        .font(.title3)
        .foregroundStyle(tint)
      Text(title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.leading)
    }
    .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
    .padding(12)
    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
  }

  private var nextStepCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Następny krok", systemImage: "arrow.forward.circle.fill")
        .font(.title3.bold())
        .foregroundStyle(.indigo)
      if currentPathIsComplete {
        Text("Ścieżka ukończona").font(.headline)
        Text("Przejdź do kontrolowanego ćwiczenia i utrwal zdobytą wiedzę.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Button {
          selectedTab = .practice
        } label: {
          Label("Przejdź do Practice", systemImage: "wrench.and.screwdriver.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
      } else {
        Text(activeLesson == nil ? "Rozpocznij naukę" : "Kontynuuj naukę")
          .font(.headline)
        Text(featuredLesson.title).font(.title3.bold())
        Text(featuredLesson.summary)
          .font(.subheadline)
          .foregroundStyle(.secondary)
        if activeLesson != nil {
          Label("Następny etap: \(featuredStageTitle)", systemImage: "arrow.right.circle")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        NavigationLink {
          LessonFlowView(lesson: featuredLesson, progressStore: progressStore)
        } label: {
          Label(
            activeLesson == nil ? "Rozpocznij rekomendowaną lekcję" : "Kontynuuj lekcję",
            systemImage: "arrow.right.circle.fill"
          )
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.indigo)
      }
    }
    .padding(16)
    .background(.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.indigo.opacity(0.3)))
  }

  private var progressTimelineCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Label("Twój postęp", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
          .font(.title3.bold())
        Spacer()
        Button("Progress") { selectedTab = .progress }
          .font(.caption.bold())
      }
      if timelineItems.isEmpty {
        Text("Ukończ pierwszy etap, aby zobaczyć tutaj swoją historię.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        ForEach(timelineItems) { item in
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

  private var timelineItems: [DashboardTimelineItem] {
    var items = progressStore.recentActivities.map {
      DashboardTimelineItem(
        id: "activity-\($0.id)",
        title: $0.title,
        subtitle: $0.kind == .labCompleted ? "Practice" : "Lekcja",
        date: $0.date,
        icon: $0.kind == .labCompleted ? "target" : "book.fill",
        tint: $0.kind == .labCompleted ? .orange : .cyan
      )
    }
    items += progressStore.practiceHistory.map {
      DashboardTimelineItem(
        id: "practice-\($0.id)",
        title: $0.labTitle,
        subtitle: "Practice • \($0.mode.title) • +\($0.xp) XP",
        date: $0.date,
        icon: "wrench.and.screwdriver.fill",
        tint: .orange
      )
    }
    let dates = progressStore.recentActivities.map(\.date) + progressStore.practiceHistory.map(\.date)
    if let latestDate = dates.max() {
      items += AchievementCatalog.evaluateAll(progressStore.progress)
        .filter(\.isUnlocked)
        .map {
          DashboardTimelineItem(
            id: "achievement-\($0.id.rawValue)",
            title: $0.title,
            subtitle: "Osiągnięcie odblokowane",
            date: latestDate,
            icon: "medal.fill",
            tint: .yellow
          )
        }
    }
    return Array(items.sorted { $0.date > $1.date }.prefix(4))
  }

  private var navigationCards: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Twoja przestrzeń").font(.title3.bold())
      HStack(spacing: 10) {
        dashboardCard("Learn", icon: "book.fill", tint: .mint, tab: .learn)
        dashboardCard("Practice", icon: "wrench.and.screwdriver.fill", tint: .orange, tab: .practice)
      }
      HStack(spacing: 10) {
        dashboardCard("Security", icon: "lock.shield.fill", tint: .cyan, tab: .security)
        dashboardCard("Progress", icon: "chart.bar.fill", tint: .purple, tab: .progress)
      }
    }
  }

  private func dashboardCard(_ title: String, icon: String, tint: Color, tab: AppTab) -> some View {
    Button { selectedTab = tab } label: {
      VStack(alignment: .leading, spacing: 10) {
        Image(systemName: icon).font(.title2).foregroundStyle(tint)
        Text(title).font(.headline).foregroundStyle(.primary)
      }
      .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
      .padding(14)
      .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16))
    }
    .buttonStyle(.plain)
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
    }
  }

  var tint: Color {
    switch self {
    case .fundamentals: .mint
    case .blueTeam: .blue
    case .redTeam: .red
    case .webSecurity: .purple
    case .mobileSecurity: .cyan
    }
  }
}
