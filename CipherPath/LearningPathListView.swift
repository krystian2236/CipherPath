import SwiftUI

struct LearningPathListView: View {
  @ObservedObject var progressStore: LearningProgressStore
  let accessPolicy: ContentAccessPolicy

  var body: some View {
    NavigationStack {
      List {
        Section {
          DevLocationLabel(location: .paths)
        }
        ForEach(StarterCurriculum.paths, id: \.self) { path in
          NavigationLink {
            LearningPathDetailView(
              path: path,
              progressStore: progressStore,
              accessPolicy: accessPolicy
            )
          } label: {
            VStack(alignment: .leading, spacing: 6) {
              DevLocationLabel(location: .pathCard)
              Label(path.title, systemImage: path.iconName).font(.headline)
              Text(accessSummary(for: path))
                .font(.caption)
                .foregroundStyle(.secondary)
              ProgressView(
                value: Double(accessPolicy.includedLessons(in: path)),
                total: 5
              )
              .tint(path.tint)
            }
            .padding(.vertical, 6)
          }
        }
      }
      .navigationTitle("Ścieżki")
    }
  }

  private func accessSummary(for path: LearningPath) -> String {
    let included = accessPolicy.includedLessons(in: path)
    return "\(included) dostępne • \(5 - included) zapowiedziane lub Pro"
  }
}
