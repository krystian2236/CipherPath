import SwiftUI

struct MissionsView: View {
  @ObservedObject var progressStore: LearningProgressStore

  private var availableLessons: [LearningLesson] {
    StarterCurriculum.lessons.filter { $0.availability == .available }
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
              LessonFlowView(lesson: lesson, progressStore: progressStore)
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
