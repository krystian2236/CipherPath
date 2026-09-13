import SwiftUI

enum MissionsTabPresentation: Equatable, Sendable {
  case comingSoon

  static let current: Self = .comingSoon

  var showsLessonLinks: Bool { false }
  var title: String { "Nowe wyzwania wkrótce" }
  var message: String {
    "Tutaj pojawią się niezależne wyzwania i dodatkowe próby sprawdzające umiejętności zdobyte w Ścieżkach."
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
          ContentUnavailableView(
            MissionsTabPresentation.current.title,
            systemImage: "sparkles.rectangle.stack",
            description: Text(MissionsTabPresentation.current.message)
          )
        }
      }
      .navigationTitle("Misje")
    }
  }
}
