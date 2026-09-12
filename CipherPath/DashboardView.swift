import SwiftUI

struct DashboardView: View {
  @Binding var selectedTab: AppTab

  private let featuredLesson = StarterCurriculum.lessons.first {
    $0.id == "blue-team-suspicious-login"
  } ?? StarterCurriculum.lessons[0]

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 22) {
          header
          missionCard
          missionStages
          pathSection
          achievementSection
          footer
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
      }
      .background(Color(red: 0.025, green: 0.045, blue: 0.075).ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
    }
    .preferredColorScheme(.dark)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .firstTextBaseline) {
        Text("Cipher") + Text("Path").foregroundStyle(.indigo)
        Spacer()
        Text("Małe kroki.\nWiększe możliwości.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .font(.largeTitle.bold())
      Text("PRAWO  •  BEZPIECZEŃSTWO  •  PRAKTYKA")
        .font(.caption2.weight(.semibold))
        .tracking(2)
        .foregroundStyle(.secondary)
    }
  }

  private var missionCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Dzisiejsza misja").font(.largeTitle.bold())
      Text("Realna wiedza. Bezpieczniejszy świat.").foregroundStyle(.secondary)
      VStack(alignment: .leading, spacing: 12) {
        Label("BLUE TEAM • SYMULACJA OFFLINE", systemImage: "lock.shield.fill")
          .font(.caption2.bold())
          .foregroundStyle(.indigo)
        Text(featuredLesson.title).font(.title2.bold())
        Text(featuredLesson.summary).font(.subheadline).foregroundStyle(.secondary)
        Label("8 min", systemImage: "clock")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
        Button {
          selectedTab = .missions
        } label: {
          HStack {
            Spacer()
            Text("Rozpocznij misję").fontWeight(.semibold)
            Image(systemName: "chevron.right")
            Spacer()
          }
          .padding(.vertical, 13)
        }
        .buttonStyle(.borderedProminent)
        .tint(.indigo)
      }
      .padding(18)
      .background(
        LinearGradient(
          colors: [.indigo.opacity(0.2), .cyan.opacity(0.08), .black.opacity(0.35)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ),
        in: RoundedRectangle(cornerRadius: 22)
      )
      .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.12)))
    }
  }

  private var missionStages: some View {
    HStack(alignment: .top, spacing: 4) {
      ForEach(Array(LessonStage.allCases.enumerated()), id: \.element) { index, stage in
        VStack(spacing: 7) {
          Image(systemName: ["doc.text.fill", "magnifyingglass", "flag.fill", "lightbulb.fill"][index])
            .font(.headline)
            .foregroundStyle(index == 0 ? .white : .secondary)
            .frame(width: 46, height: 46)
            .background(index == 0 ? Color.indigo : Color.clear, in: Circle())
            .overlay(Circle().stroke(index == 0 ? Color.indigo : Color.secondary.opacity(0.45), lineWidth: 2))
          Text(stage.title).font(.caption2.bold()).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
      }
    }
  }

  private var pathSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionHeader("Twoje ścieżki", destination: .paths)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
          ForEach(StarterCurriculum.paths, id: \.self) { path in
            VStack(alignment: .leading, spacing: 9) {
              Image(systemName: path.iconName).font(.title2).foregroundStyle(path.tint)
              Text(path.shortTitle).font(.subheadline.bold())
              HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { number in
                  Image(systemName: number <= 2 ? "circle.fill" : "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(number <= 2 ? path.tint : .secondary)
                }
              }
              Text("2 dostępne\n3 zablokowane").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(width: 112, alignment: .leading)
            .padding(13)
            .background(path.tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(path.tint.opacity(0.35)))
          }
        }
      }
    }
  }

  private var achievementSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionHeader("Osiągnięcia", destination: .achievements)
      HStack(spacing: 10) {
        achievementCard("Pierwsza flaga", icon: "star.fill", color: .orange)
        achievementCard("Bez podpowiedzi", icon: "leaf.fill", color: .gray)
        achievementCard("Obrońca", icon: "lock.fill", color: .yellow)
      }
    }
  }

  private func achievementCard(_ title: String, icon: String, color: Color) -> some View {
    VStack(spacing: 8) {
      Image(systemName: icon).font(.title2).foregroundStyle(color)
      Text(title).font(.caption2.bold()).multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, minHeight: 84)
    .padding(8)
    .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1)))
  }

  private func sectionHeader(_ title: String, destination: AppTab) -> some View {
    HStack {
      Text(title).font(.title3.bold())
      Spacer()
      Button("Zobacz wszystkie") { selectedTab = destination }
        .font(.caption.bold())
        .foregroundStyle(.indigo)
    }
  }

  private var footer: some View {
    Label("Systematyczna nauka dziś, większe możliwości jutro.", systemImage: "leaf.fill")
      .font(.footnote)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
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
