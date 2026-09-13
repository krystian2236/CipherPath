import SwiftUI

struct LearningPathDetailView: View {
  let path: LearningPath
  @ObservedObject var progressStore: LearningProgressStore

  var body: some View {
    List(StarterCurriculum.lessons(in: path)) { lesson in
      if lesson.availability == .available {
        NavigationLink {
          LessonFlowView(lesson: lesson, progressStore: progressStore)
        } label: {
          LessonRow(lesson: lesson, path: path, isCompleted: progressStore.isCompleted(lessonID: lesson.id))
        }
      } else {
        LessonRow(lesson: lesson, path: path, isCompleted: false)
          .opacity(0.48)
      }
    }
    .navigationTitle(path.title)
  }
}

private struct LessonRow: View {
  let lesson: LearningLesson
  let path: LearningPath
  let isCompleted: Bool

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: iconName)
        .foregroundStyle(lesson.availability == .available ? path.tint : .secondary)
      VStack(alignment: .leading, spacing: 4) {
        Text("Lekcja \(lesson.order)").font(.caption).foregroundStyle(.secondary)
        Text(lesson.title).font(.headline)
        Text(lesson.summary).font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
      if lesson.availability == .comingSoon {
        Text("Wkrótce").font(.caption2.bold()).foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 5)
    .accessibilityElement(children: .combine)
  }

  private var iconName: String {
    if lesson.availability == .comingSoon { return "lock.fill" }
    return isCompleted ? "checkmark.circle.fill" : "play.circle.fill"
  }
}
