import SwiftUI

struct AchievementsView: View {
  @ObservedObject var progressStore: LearningProgressStore

  private var achievements: [AchievementProgress] {
    AchievementCatalog.evaluateAll(progressStore.progress)
  }

  private var pathSummaries: [LearningPathProgressSummary] {
    LearningPath.allCases.map {
      LearningPathProgressSummary.make(
        for: $0,
        progress: progressStore.progress,
        policy: .current
      )
    }
  }

  private var totalXP: Int {
    pathSummaries.reduce(0) { $0 + $1.xp }
  }

  private var completedLabs: Int {
    progressStore.progress.labMissions.values.reduce(0) {
      $0 + ($1.completedModes.isEmpty ? 0 : 1)
    }
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          HStack {
            DevLocationLabel(location: .achievements)
            UIRefCopyButton(ref: .progress)
          }
        }
        Section("Podsumowanie") {
          HStack {
            progressMetric("XP", value: "\(totalXP)", icon: "bolt.fill", color: .orange)
            progressMetric("Punkty", value: "\(progressStore.pointsBalance)", icon: "sparkles", color: .cyan)
            progressMetric("Labs", value: "\(completedLabs)", icon: "target", color: .green)
          }
          NavigationLink {
            PointsView(progressStore: progressStore)
          } label: {
            Label("Punkty i historia", systemImage: "list.bullet.rectangle")
          }
        }
        Section("Cel dzienny i seria") {
          HStack {
            progressMetric(
              "Dzisiaj",
              value: "\(progressStore.progress.xpEarnedToday)/\(progressStore.progress.dailyGoalXP) XP",
              icon: "sun.max.fill",
              color: .orange
            )
            progressMetric("Seria", value: "\(progressStore.streakDays) dni", icon: "flame.fill", color: .red)
          }
          ProgressView(value: progressStore.dailyGoalProgress) {
            Text(progressStore.isDailyGoalComplete ? "Cel wykonany" : "Postęp celu dziennego")
          }
          .tint(.orange)
        }
        Section("Postęp ścieżek") {
          ForEach(pathSummaries) { summary in
            VStack(alignment: .leading, spacing: 6) {
              HStack {
                Label(summary.path.title, systemImage: summary.path.iconName)
                  .foregroundStyle(summary.path.tint)
                Spacer()
                Text("\(summary.completedLessons)/\(summary.availableLessons)")
                  .font(.caption.monospacedDigit())
                  .foregroundStyle(.secondary)
              }
              ProgressView(
                value: Double(summary.completedLessons),
                total: Double(max(summary.availableLessons, 1))
              )
              .tint(summary.path.tint)
              HStack {
                Text("\(summary.completedLabs) labs")
                Spacer()
                Text("\(summary.xp) XP")
              }
              .font(.caption2)
              .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
          }
        }
        Section("Osiągnięcia") {
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
          Section("Ostatnia aktywność") {
            if progressStore.recentActivities.isEmpty {
              ContentUnavailableView("Brak aktywności", systemImage: "clock")
            } else {
              ForEach(progressStore.recentActivities.prefix(8)) { activity in
                HStack {
                  Image(systemName: activity.kind == .labCompleted ? "target" : "book.fill")
                    .foregroundStyle(activity.kind == .labCompleted ? .orange : .cyan)
                  VStack(alignment: .leading) {
                    Text(activity.title)
                    Text(activity.date, format: .dateTime.day().month().hour().minute())
                      .font(.caption2)
                      .foregroundStyle(.secondary)
                  }
                }
              }
            }
          }
          Section("Historia Practice") {
            if progressStore.practiceHistory.isEmpty {
              Text("Ukończ pierwszy lab, aby zobaczyć historię.")
                .foregroundStyle(.secondary)
            } else {
              ForEach(progressStore.practiceHistory.prefix(8)) { entry in
                HStack {
                  VStack(alignment: .leading) {
                    Text(entry.labTitle)
                    Text("\(entry.mode.title) • \(entry.date, format: .dateTime.day().month().year())")
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                  Spacer()
                  Text("+\(entry.xp) XP")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                }
              }
            }
          }
          #if CIPHERPATH_DEVELOPER
            if AppDistributionMode.currentBuild == .developer {
              Section("Narzędzia Dev") {
                Button("Resetuj postęp", role: .destructive) {
                  progressStore.reset()
                }
                Button("Dodaj 100 XP") {
                  progressStore.addPointsForDevelopment(100)
                }
              }
            }
          #endif
      }
      .navigationTitle("Progress")
    }
  }

  private func color(_ rarity: AchievementRarity) -> Color {
    switch rarity {
    case .bronze: .orange
    case .silver: .gray
    case .gold: .yellow
    }
  }

  private func progressMetric(_ title: String, value: String, icon: String, color: Color) -> some View {
    VStack(spacing: 4) {
      Image(systemName: icon).foregroundStyle(color)
      Text(value).font(.headline.monospacedDigit())
      Text(title).font(.caption2).foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }
}
