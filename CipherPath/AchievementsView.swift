import SwiftUI

struct AchievementsView: View {
  private let achievements = [
    ("Pierwsza flaga", "Łatwe", "star.fill", Color.orange, "Ukończ pierwszą misję"),
    ("Bez podpowiedzi", "Średnie", "leaf.fill", Color.gray, "Ukończ misję bez pomocy"),
    ("Obrońca systemów", "Trudne", "lock.fill", Color.yellow, "Ukończ 10 misji Blue Team"),
  ]

  var body: some View {
    NavigationStack {
      List {
        ForEach(Array(achievements.enumerated()), id: \.offset) { _, item in
          HStack(spacing: 15) {
            Image(systemName: item.2)
              .font(.title)
              .foregroundStyle(item.3)
              .frame(width: 52, height: 52)
              .background(item.3.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
              Text(item.0).font(.headline)
              Text(item.1).font(.caption.bold()).foregroundStyle(item.3)
              Text(item.4).font(.caption).foregroundStyle(.secondary)
              ProgressView(value: 0, total: 1).tint(item.3)
            }
          }
          .padding(.vertical, 7)
        }
      }
      .navigationTitle("Osiągnięcia")
    }
  }
}
