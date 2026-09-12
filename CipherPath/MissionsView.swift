import SwiftUI

struct MissionsView: View {
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
              MissionPreviewView(lesson: lesson)
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

private struct MissionPreviewView: View {
  let lesson: LearningLesson

  var body: some View {
    List {
      Section("Cel") { Text(lesson.summary) }
      Section("Przebieg") {
        ForEach(lesson.stages, id: \.self) { stage in
          Label(stage.title, systemImage: "circle")
        }
      }
      Section {
        Text("Pełny przebieg misji zostanie uruchomiony w etapie 75%.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .navigationTitle(lesson.title)
    .navigationBarTitleDisplayMode(.inline)
  }
}
