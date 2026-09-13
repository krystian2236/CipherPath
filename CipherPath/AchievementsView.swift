import SwiftUI

struct AchievementsView: View {
  @ObservedObject var progressStore: LearningProgressStore

  private var achievements: [AchievementProgress] {
    AchievementCatalog.evaluateAll(progressStore.progress)
  }

  var body: some View {
    NavigationStack {
      List {
        ForEach(achievements, id: \.id) { achievement in
          HStack(spacing: 15) {
            Image(systemName: achievement.isUnlocked ? "medal.fill" : "lock.fill")
              .font(.title)
              .foregroundStyle(achievement.isUnlocked ? color(achievement.rarity) : .secondary)
              .frame(width: 52, height: 52)
              .background(color(achievement.rarity).opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
              Text(achievement.title).font(.headline)
              Text(achievement.rarity.rawValue)
                .font(.caption.bold())
                .foregroundStyle(color(achievement.rarity))
              Text(achievement.requirement).font(.caption).foregroundStyle(.secondary)
              ProgressView(
                value: Double(achievement.current),
                total: Double(achievement.target)
              )
              .tint(color(achievement.rarity))
              Text("\(achievement.current)/\(achievement.target)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, 7)
        }
      }
      .navigationTitle("Osiągnięcia")
    }
  }

  private func color(_ rarity: AchievementRarity) -> Color {
    switch rarity {
    case .bronze: .orange
    case .silver: .gray
    case .gold: .yellow
    }
  }
}
