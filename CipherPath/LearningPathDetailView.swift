import SwiftUI

struct LearningPathDetailView: View {
  let path: LearningPath

  var body: some View {
    List(StarterCurriculum.lessons(in: path)) { lesson in
      HStack(spacing: 12) {
        Image(systemName: lesson.availability == .available ? "play.circle.fill" : "lock.fill")
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
      .opacity(lesson.availability == .available ? 1 : 0.48)
      .accessibilityElement(children: .combine)
    }
    .navigationTitle(path.title)
  }
}
