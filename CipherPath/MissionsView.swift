import SwiftUI

enum MissionsTabPresentation: Equatable, Sendable {
  case available

  static let current: Self = .available

  var showsLessonLinks: Bool { true }
  var title: String { "Misje offline" }
  var message: String {
    "Wybierz kontrolowany scenariusz i przećwicz decyzję bezpieczeństwa bez połączenia z siecią."
  }
}

struct MissionsView: View {
  @ObservedObject var progressStore: LearningProgressStore
  let accessPolicy: ContentAccessPolicy

  var body: some View {
    NavigationStack {
      List {
        Section {
          DevLocationLabel(location: .missions)
        }
        Section {
          Text(MissionsTabPresentation.current.message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Section(MissionsTabPresentation.current.title) {
          ForEach(StarterCurriculum.lessons.filter {
            accessPolicy.access(for: $0) == .included
          }) { lesson in
            NavigationLink {
              MissionBriefingView(lesson: lesson, progressStore: progressStore)
            } label: {
              Label {
                VStack(alignment: .leading, spacing: 3) {
                  Text(lesson.title).font(.headline)
                  Text(lesson.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              } icon: {
                Image(systemName: progressStore.isCompleted(lessonID: lesson.id)
                  ? "checkmark.circle.fill"
                  : "target")
                .foregroundStyle(.orange)
              }
            }
          }
        }
      }
      .navigationTitle("Misje")
    }
  }
}
