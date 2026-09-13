import SwiftUI

struct PointsHistoryRowModel: Identifiable, Equatable, Sendable {
  let id: String
  let title: String
  let subtitle: String
  let amountText: String
  let date: Date

  static func rows(for transactions: [PointsTransaction]) -> [Self] {
    transactions
      .sorted { $0.date > $1.date }
      .map { transaction in
        PointsHistoryRowModel(
          id: transaction.id,
          title: title(for: transaction.kind),
          subtitle: subtitle(for: transaction),
          amountText: transaction.amount >= 0
            ? "+\(transaction.amount) pkt"
            : "−\(abs(transaction.amount)) pkt",
          date: transaction.date
        )
      }
  }

  private static func title(for kind: PointsTransactionKind) -> String {
    switch kind {
    case .initialBalance: "Punkty na start"
    case .missionReward: "Nagroda za misję"
    case .hint: "Podpowiedź"
    case .solution: "Rozwiązanie"
    case .developerAdjustment: "Korekta deweloperska"
    }
  }

  private static func subtitle(for transaction: PointsTransaction) -> String {
    guard let lessonID = transaction.lessonID else { return "CipherPath" }
    return StarterCurriculum.lessons.first(where: { $0.id == lessonID })?.title ?? lessonID
  }
}

struct PointsView: View {
  @ObservedObject var progressStore: LearningProgressStore
  let distribution: AppDistributionMode

  @State private var developerAction: DeveloperPointsAction?

  init(
    progressStore: LearningProgressStore,
    distribution: AppDistributionMode = .currentBuild
  ) {
    self.progressStore = progressStore
    self.distribution = distribution
  }

  var body: some View {
    List {
      Section {
        VStack(alignment: .leading, spacing: 8) {
          Label("Saldo", systemImage: "sparkles")
            .font(.headline)
          Text(distribution == .developer ? "∞" : "\(progressStore.pointsBalance)")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(.cyan)
          Text(distribution == .developer
            ? "Tryb Dev nie ogranicza podpowiedzi ani rozwiązań."
            : "Zdobywaj punkty za misje i wykorzystuj je na pomoc.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
      }

      Section("Historia") {
        ForEach(PointsHistoryRowModel.rows(for: progressStore.progress.pointsWallet.transactions)) { row in
          HStack {
            VStack(alignment: .leading, spacing: 3) {
              Text(row.title).font(.headline)
              Text(row.subtitle).font(.caption).foregroundStyle(.secondary)
              Text(row.date, format: .dateTime.day().month().year())
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(row.amountText)
              .font(.subheadline.bold())
              .foregroundStyle(row.amountText.hasPrefix("+") ? .green : .orange)
          }
        }
      }

      #if DEBUG
        if distribution == .developer {
          Section("Narzędzia Dev") {
            Button("Dodaj 100 pkt") { developerAction = .add }
            Button("Wyzeruj portfel testowy", role: .destructive) { developerAction = .reset }
          }
        }
      #endif
    }
    .navigationTitle("Punkty")
    .navigationBarTitleDisplayMode(.inline)
    .confirmationDialog(
      "Potwierdź operację Dev",
      isPresented: developerActionPresented,
      titleVisibility: .visible
    ) {
      if let developerAction {
        Button(developerAction.buttonTitle, role: developerAction == .reset ? .destructive : nil) {
          perform(developerAction)
        }
      }
      Button("Anuluj", role: .cancel) {}
    }
  }

  private var developerActionPresented: Binding<Bool> {
    Binding(
      get: { developerAction != nil },
      set: { if !$0 { developerAction = nil } }
    )
  }

  private func perform(_ action: DeveloperPointsAction) {
    switch action {
    case .add: progressStore.addPointsForDevelopment(100)
    case .reset: progressStore.resetPointsForDevelopment()
    }
  }
}

private enum DeveloperPointsAction: Equatable {
  case add
  case reset

  var buttonTitle: String {
    switch self {
    case .add: "Dodaj 100 pkt"
    case .reset: "Wyzeruj portfel"
    }
  }
}
