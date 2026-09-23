import SwiftUI
import UIKit

struct AppSettingsView: View {
    @ObservedObject var progressStore: LearningProgressStore
    @Environment(\.openURL) private var openURL

    private var dailyGoal: Binding<Int> {
        Binding(
            get: { progressStore.progress.dailyGoalXP },
            set: { progressStore.setDailyGoalXP($0) }
        )
    }

    var body: some View {
        Form {
            Section("Cel dzienny") {
                Stepper(value: dailyGoal, in: 25...500, step: 25) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Cel nauki")
                            .font(.headline)
                        Text("\(progressStore.progress.dailyGoalXP) XP dziennie")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                ProgressView(value: progressStore.dailyGoalProgress) {
                    Text("Dzisiejszy postęp")
                } currentValueLabel: {
                    Text("\(progressStore.progress.xpEarnedToday) / \(progressStore.progress.dailyGoalXP) XP")
                }
            }

            Section("Prywatność i system") {
                Button {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                } label: {
                    Label("Otwórz ustawienia iOS", systemImage: "gear")
                }

                Text("Northbyte Lab przechowuje postęp lokalnie. Ustawienia sieci i uprawnień kontrolujesz w systemie.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Skróty klawiaturowe") {
                LabeledContent("Learn", value: "⌘L")
                LabeledContent("Practice", value: "⌘P")
                LabeledContent("Security", value: "⌘S")
            }
        }
        .navigationTitle("Ustawienia")
        .navigationBarTitleDisplayMode(.inline)
    }
}
