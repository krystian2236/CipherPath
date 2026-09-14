import SwiftUI

struct PathCardSummary: Equatable, Sendable {
  let includedCount: Int
  let remainingCount: Int
  let remainingLabel: String

  static func make(for path: LearningPath, policy: ContentAccessPolicy) -> Self {
    let lessons = StarterCurriculum.lessons(in: path)
    let includedCount = lessons.filter { policy.access(for: $0) == .included }.count
    return PathCardSummary(
      includedCount: includedCount,
      remainingCount: lessons.count - includedCount,
      remainingLabel: policy.tier == .pro ? "zapowiedziane" : "zapowiedziane lub Pro"
    )
  }
}

struct LearningPathListView: View {
  @ObservedObject var progressStore: LearningProgressStore
  let accessPolicy: ContentAccessPolicy

  private let columns = Array(
    repeating: GridItem(.flexible(), spacing: 8, alignment: .top),
    count: 3
  )

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          DevLocationLabel(location: .paths)
          LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(StarterCurriculum.paths, id: \.self) { path in
              let summary = PathCardSummary.make(for: path, policy: accessPolicy)
              NavigationLink {
                LearningPathDetailView(
                  path: path,
                  progressStore: progressStore,
                  accessPolicy: accessPolicy
                )
              } label: {
                pathTile(path, summary: summary)
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
      .background(Color(red: 0.025, green: 0.045, blue: 0.075).ignoresSafeArea())
      .navigationTitle("Ścieżki")
    }
    .preferredColorScheme(.dark)
  }

  private func pathTile(_ path: LearningPath, summary: PathCardSummary) -> some View {
    VStack(alignment: .leading, spacing: 7) {
      Image(systemName: path.iconName)
        .font(.title3)
        .foregroundStyle(path.tint)
      Text(path.shortTitle)
        .font(.caption.bold())
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      HStack(spacing: 3) {
        ForEach(1...5, id: \.self) { number in
          Image(systemName: number <= summary.includedCount ? "circle.fill" : "lock.fill")
            .font(.system(size: 7, weight: .semibold))
            .foregroundStyle(number <= summary.includedCount ? path.tint : .secondary)
        }
      }
      Text("\(summary.includedCount)/5 dostępne")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .frame(maxWidth: .infinity, minHeight: 98, alignment: .topLeading)
    .padding(10)
    .background(path.tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(path.tint.opacity(0.35)))
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(path.title), \(summary.includedCount) z 5 dostępnych")
  }
}
