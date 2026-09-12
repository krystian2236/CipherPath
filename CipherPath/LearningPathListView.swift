import SwiftUI

struct LearningPathListView: View {
  var body: some View {
    NavigationStack {
      List(StarterCurriculum.paths, id: \.self) { path in
        NavigationLink {
          LearningPathDetailView(path: path)
        } label: {
          VStack(alignment: .leading, spacing: 6) {
            Label(path.title, systemImage: path.iconName).font(.headline)
            Text("2 dostępne • 3 w kolejnych aktualizacjach")
              .font(.caption)
              .foregroundStyle(.secondary)
            ProgressView(value: 2, total: 5).tint(path.tint)
          }
          .padding(.vertical, 6)
        }
      }
      .navigationTitle("Ścieżki")
    }
  }
}
