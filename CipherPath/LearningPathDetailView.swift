import SwiftUI

private enum LessonFilter: String, CaseIterable, Identifiable, Hashable {
  case all
  case inProgress
  case completed
  case locked

  var id: Self { self }

  var title: String {
    switch self {
    case .all: "Wszystkie"
    case .inProgress: "W toku"
    case .completed: "Ukończone"
    case .locked: "Zablokowane"
    }
  }
}

struct LearningPathDetailView: View {
  let path: LearningPath
  @ObservedObject var progressStore: LearningProgressStore
  let accessPolicy: ContentAccessPolicy
  @State private var filter: LessonFilter = .all

  private var lessons: [LearningLesson] {
    StarterCurriculum.lessons(in: path).filter { lesson in
      let access = accessPolicy.access(for: lesson)
      return switch filter {
      case .all: true
      case .inProgress:
        access == .included && !progressStore.isCompleted(lessonID: lesson.id)
      case .completed:
        access == .included && progressStore.isCompleted(lessonID: lesson.id)
      case .locked:
        access != .included
      }
    }
  }

  var body: some View {
    List {
      Section {
        DevLocationLabel(location: .paths)
        Picker("Filtr lekcji", selection: $filter) {
          ForEach(LessonFilter.allCases) { filter in
            Text(filter.title).tag(filter)
          }
        }
        .pickerStyle(.menu)
      }
      ForEach(lessons) { lesson in
        if accessPolicy.access(for: lesson) == .included {
          lessonLinks(lesson, access: .included)
        } else {
          lessonLinks(lesson, access: accessPolicy.access(for: lesson))
            .opacity(0.48)
        }
      }
      if lessons.isEmpty {
        ContentUnavailableView("Brak lekcji", systemImage: "line.3.horizontal.decrease.circle")
      }
    }
    .navigationTitle(path.title)
  }

  @ViewBuilder
  private func lessonLinks(_ lesson: LearningLesson, access: LessonAccess) -> some View {
    HStack(spacing: 8) {
      if access == .included {
        NavigationLink {
          MissionBriefingView(lesson: lesson, progressStore: progressStore)
        } label: {
          LessonRow(
            lesson: lesson,
            path: path,
            access: access,
            isCompleted: progressStore.isCompleted(lessonID: lesson.id),
            prerequisiteTitle: prerequisiteTitle(for: lesson),
            note: progressStore.note(for: lesson.id)
          )
        }
      } else {
        LessonRow(
          lesson: lesson,
          path: path,
          access: access,
          isCompleted: false,
          prerequisiteTitle: prerequisiteTitle(for: lesson),
          note: progressStore.note(for: lesson.id)
        )
      }
      NavigationLink {
        LessonNotesView(lesson: lesson, progressStore: progressStore)
      } label: {
        Image(systemName: progressStore.note(for: lesson.id).isEmpty ? "note.text" : "note.text.badge.plus")
          .foregroundStyle(.secondary)
          .padding(6)
      }
      .accessibilityLabel("Notatka do lekcji")
    }
  }

  private func prerequisiteTitle(for lesson: LearningLesson) -> String? {
    guard lesson.order > 1 else { return nil }
    return StarterCurriculum.lessons(in: path)
      .first { $0.order == lesson.order - 1 }?.title
  }
}

private struct LessonRow: View {
  let lesson: LearningLesson
  let path: LearningPath
  let access: LessonAccess
  let isCompleted: Bool
  let prerequisiteTitle: String?
  let note: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: iconName)
        .foregroundStyle(lesson.availability == .available ? path.tint : .secondary)
      VStack(alignment: .leading, spacing: 4) {
        DevLocationLabel(location: .missionCard)
        Text("Lekcja \(lesson.order)").font(.caption).foregroundStyle(.secondary)
        Text(lesson.title).font(.headline)
        Text(lesson.summary).font(.caption).foregroundStyle(.secondary)
        HStack(spacing: 8) {
          Label("\(lesson.order == 1 ? 8 : 12) min", systemImage: "clock")
          Label(lesson.order == 1 ? "Łatwa" : "Średnia", systemImage: "gauge.with.dots.needle.67percent")
          if !note.isEmpty {
            Label("Notatka", systemImage: "note.text")
          }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        if let prerequisiteTitle {
          Text("Wymaga: \(prerequisiteTitle)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
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

private struct LessonNotesView: View {
  let lesson: LearningLesson
  @ObservedObject var progressStore: LearningProgressStore
  @State private var note = ""

  var body: some View {
    Form {
      Section {
        TextEditor(text: $note)
          .frame(minHeight: 180)
      } footer: {
        Text("Notatka pozostaje wyłącznie na tym urządzeniu. Maksymalnie 2 000 znaków.")
      }
    }
    .navigationTitle("Notatka")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear { note = progressStore.note(for: lesson.id) }
    .onDisappear { progressStore.saveNote(note, for: lesson.id) }
  }
}
