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
    if let current = progressStore.continueLesson {
      return current
    }
    return availableLessons.first { !progressStore.isCompleted(lessonID: $0.id) }
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
    }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          header
          AppReleaseIdentityCard()
          readinessCard
          continueCard
          todayCard
          recentActivityCard
          navigationCards
          quickMission
          recentAchievement
        }
        .padding(18)
      }
      .background(Color(red: 0.025, green: 0.045, blue: 0.075).ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
    }
    .preferredColorScheme(.dark)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Cipher") + Text("Path").foregroundStyle(.indigo)
        .font(.largeTitle.bold())
      Text("Ucz się bezpieczeństwa krok po kroku")
        .foregroundStyle(.secondary)
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

  private var continueCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(progressStore.continueLesson == nil ? "Zacznij naukę" : "Kontynuuj naukę").font(.title3.bold())
      Text(featuredLesson.title).font(.headline)
      Text(featuredLesson.summary).font(.subheadline).foregroundStyle(.secondary)
      Label("Następny etap: \(featuredStageTitle)", systemImage: "arrow.right.circle")
        .font(.caption)
        .foregroundStyle(.secondary)
      NavigationLink {
        LessonFlowView(lesson: featuredLesson, progressStore: progressStore)
      } label: {
        Label("Otwórz temat", systemImage: "arrow.right.circle.fill")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .tint(.indigo)
    }
    .padding(16)
    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
  }

  private var todayCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label("Dzisiaj warto zrobić", systemImage: "sun.max.fill")
        .font(.headline)
        .foregroundStyle(.orange)
      Text(featuredLesson.title)
        .font(.subheadline.weight(.semibold))
      Text("Poświęć około \(MissionBriefing.forLesson(featuredLesson).estimatedMinutes) minut na kolejny kontrolowany krok.")
        .font(.caption)
        .foregroundStyle(.secondary)
      Button("Zacznij teraz") { selectedTab = .learn }
        .buttonStyle(.bordered)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
  }

  private var recentActivityCard: some View {
    let activity = progressStore.recentActivities.first
    return HStack(spacing: 10) {
      Image(systemName: activity == nil ? "clock" : "checkmark.circle.fill")
        .foregroundStyle(activity == nil ? Color.secondary : Color.green)
      VStack(alignment: .leading, spacing: 3) {
        Text("Ostatnia aktywność")
          .font(.caption.bold())
        Text(activity?.title ?? "Jeszcze nic nie ukończono")
          .font(.subheadline)
          .lineLimit(2)
        if let activity {
          Text(activity.date, format: .dateTime.day().month().hour().minute())
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      Spacer()
    }
    .padding(14)
    .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
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

  private var quickMission: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Dzisiejsza misja").font(.title3.bold())
      Text("Przećwicz decyzję bezpieczeństwa w kontrolowanym scenariuszu.")
        .font(.subheadline).foregroundStyle(.secondary)
      Button("Przejdź do Security") { selectedTab = .security }
        .buttonStyle(.bordered)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
  }

  private var recentAchievement: some View {
    let achievement = AchievementCatalog.evaluateAll(progressStore.progress).first(where: { $0.isUnlocked })
    return HStack {
      Image(systemName: achievement == nil ? "lock.fill" : "medal.fill")
        .foregroundStyle(achievement == nil ? Color.secondary : Color.yellow)
      Text(achievement?.title ?? "Pierwsze osiągnięcie czeka")
        .font(.subheadline.weight(.semibold))
      Spacer()
      Button("Progress") { selectedTab = .progress }
        .font(.caption.bold())
    }
    .padding(14)
    .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
  }
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
