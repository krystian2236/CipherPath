import SwiftUI

struct LearningPathDetailView: View {
  let path: LearningPath
  @ObservedObject var progressStore: LearningProgressStore
  let accessPolicy: ContentAccessPolicy

  var body: some View {
    List {
      Section {
        DevLocationLabel(location: .paths)
      }
      ForEach(StarterCurriculum.lessons(in: path)) { lesson in
        if accessPolicy.access(for: lesson) == .included {
          NavigationLink {
            MissionBriefingView(lesson: lesson, progressStore: progressStore)
          } label: {
            LessonRow(
              lesson: lesson,
              path: path,
              access: .included,
              isCompleted: progressStore.isCompleted(lessonID: lesson.id)
            )
          }
        } else {
          LessonRow(
            lesson: lesson,
            path: path,
            access: accessPolicy.access(for: lesson),
            isCompleted: false
          )
            .opacity(0.48)
        }
      }
    }
    .navigationTitle(path.title)
  }
}

private struct LessonRow: View {
  let lesson: LearningLesson
  let path: LearningPath
  let access: LessonAccess
  let isCompleted: Bool

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: iconName)
        .foregroundStyle(lesson.availability == .available ? path.tint : .secondary)
      VStack(alignment: .leading, spacing: 4) {
        DevLocationLabel(location: .missionCard)
        Text("Lekcja \(lesson.order)").font(.caption).foregroundStyle(.secondary)
        Text(lesson.title).font(.headline)
        Text(lesson.summary).font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
      if access == .comingSoon {
        Text("Wkrótce").font(.caption2.bold()).foregroundStyle(.secondary)
      } else if access == .requiresPro {
        Text("PRO").font(.caption2.bold()).foregroundStyle(path.tint)
      }
    }
    .padding(.vertical, 5)
    .accessibilityElement(children: .combine)
  }

  private var iconName: String {
    if access != .included { return "lock.fill" }
    return isCompleted ? "checkmark.circle.fill" : "play.circle.fill"
  }
}
