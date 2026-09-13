import SwiftUI

struct MissionsView: View {
  @ObservedObject var progressStore: LearningProgressStore
  let accessPolicy: ContentAccessPolicy

  private var availableLessons: [LearningLesson] {
    StarterCurriculum.lessons.filter { accessPolicy.access(for: $0) == .included }
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          Label("Ćwiczenia działają na wbudowanych danych i w legalnych labach.", systemImage: "lock.shield")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        Section("Gotowe do rozpoczęcia") {
          ForEach(availableLessons) { lesson in
            NavigationLink {
              MissionBriefingView(lesson: lesson, progressStore: progressStore)
            } label: {
              VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title).font(.headline)
                Text(lesson.path.title).font(.caption).foregroundStyle(.secondary)
              }
            }
          }
        }
      }
      .navigationTitle("Misje")
    }
  }
}
