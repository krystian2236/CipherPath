import SwiftUI

struct GlobalSearchView: View {
    @Binding var selectedTab: AppTab
    @ObservedObject var progressStore: LearningProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var matchingLessons: [LearningLesson] {
        StarterCurriculum.lessons.filter { lesson in
            matches(lesson.title, lesson.summary, lesson.path.title)
        }
    }

    private var matchingChecklist: [SecurityChecklistItem] {
        SecurityChecklistItem.all.filter { item in
            matches(item.title, item.explanation, item.tip)
        }
    }

    private var matchingTools: [ToolboxTool] {
        ToolboxTool.allCases.filter { tool in
            matches(tool.title, tool.summary, tool.stage.title)
        }
    }

    var body: some View {
        List {
            Section {
                TextField("Lekcje, Security, Practice", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Zapytanie wyszukiwania")
            }

            if query.isEmpty {
                Section {
                    Label(
                        "Wyszukaj lekcję, punkt checklisty albo narzędzie. Wyniki są dostępne offline.",
                        systemImage: "magnifyingglass"
                    )
                    .foregroundStyle(.secondary)
                }
            } else {
                if !matchingLessons.isEmpty {
                    Section("Lekcje") {
                        ForEach(matchingLessons) { lesson in
                            NavigationLink {
                                LessonFlowView(lesson: lesson, progressStore: progressStore)
                            } label: {
                                resultRow(
                                    title: lesson.title,
                                    subtitle: "\(lesson.path.title) • \(lesson.estimatedMinutes) min",
                                    icon: lesson.path.iconName,
                                    tint: lesson.path.tint
                                )
                            }
                        }
                    }
                }

                if !matchingChecklist.isEmpty {
                    Section("Security") {
                        ForEach(matchingChecklist) { item in
                            Button {
                                open(.security)
                            } label: {
                                resultRow(
                                    title: item.title,
                                    subtitle: item.explanation,
                                    icon: item.icon,
                                    tint: .cyan
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !matchingTools.isEmpty {
                    Section("Practice") {
                        ForEach(matchingTools) { tool in
                            Button {
                                open(.practice)
                            } label: {
                                resultRow(
                                    title: tool.title,
                                    subtitle: tool.summary,
                                    icon: tool.icon,
                                    tint: .orange
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if matchingLessons.isEmpty && matchingChecklist.isEmpty && matchingTools.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
        }
        .navigationTitle("Szukaj")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func matches(_ values: String...) -> Bool {
        query.isEmpty || values.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    private func open(_ tab: AppTab) {
        dismiss()
        selectedTab = tab
    }

    private func resultRow(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 24)
        }
    }
}
