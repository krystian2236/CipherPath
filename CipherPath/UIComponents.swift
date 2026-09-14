import SwiftUI
import UIKit

enum AppLanguage: String, CaseIterable, Sendable {
  case system
  case polish = "pl"
  case english = "en"

  var localeOverride: Locale? {
    switch self {
    case .system: nil
    case .polish: Locale(identifier: "pl")
    case .english: Locale(identifier: "en")
    }
  }

  static func fromStoredValue(_ value: String?) -> AppLanguage {
    guard let value, let language = AppLanguage(rawValue: value) else {
      return .system
    }
    return language
  }
}

enum DevLocation: String, CaseIterable, Sendable {
  case dashboard = "START"
  case dashboardMission = "START / DZISIEJSZA MISJA"
  case dashboardAchievements = "START / OSIĄGNIĘCIA"
  case dashboardPoints = "START / PUNKTY"
  case paths = "ŚCIEŻKI"
  case pathDetail = "ŚCIEŻKI / SZCZEGÓŁY"
  case missions = "MISJE"
  case missionCard = "MISJE / KARTA MISJI"
  case briefing = "ODPRAWA"
  case labMode = "LAB / TRYB"
  case labObjectives = "LAB / CELE"
  case labTerminal = "LAB / TERMINAL"
  case labAnswer = "LAB / ODPOWIEDŹ"
  case labDefense = "LAB / OBRONA"
  case practice = "PRAKTYKA"
  case practiceScanner = "PRAKTYKA / SKANER"
  case practiceToolbox = "PRAKTYKA / TOOLBOX"
  case practiceDevices = "PRAKTYKA / URZĄDZENIA"
  case practiceServices = "PRAKTYKA / USŁUGI"
  case achievements = "OSIĄGNIĘCIA"
  case points = "PUNKTY"

  // Legacy values are kept temporarily so older tests and references remain valid
  // while the visible DEV system moves to stable English technical identifiers.
  var label: String { "[DEV: \(rawValue)]" }
  var copyValue: String { "DEV: \(rawValue)" }

  var displayLabel: String { "[DEV: VECTORSEC / \(technicalPath)]" }

  var uiRef: String {
    "UIREF app=VectorSec screen=\(screen) component=\(component) view=\(viewName)"
  }

  private var technicalPath: String {
    switch self {
    case .dashboard: "START"
    case .dashboardMission: "START / FEATURED_LESSON"
    case .dashboardAchievements: "START / ACHIEVEMENTS"
    case .dashboardPoints: "START / POINTS"
    case .paths: "PATHS"
    case .pathDetail: "PATHS / PATH_DETAIL"
    case .missions: "MISSIONS"
    case .missionCard: "MISSIONS / MISSION_CARD"
    case .briefing: "LESSON / BRIEFING"
    case .labMode: "LAB / MODE"
    case .labObjectives: "LAB / OBJECTIVES"
    case .labTerminal: "LAB / TERMINAL"
    case .labAnswer: "LAB / ANSWER"
    case .labDefense: "LAB / DEFENSE"
    case .practice: "PRACTICE"
    case .practiceScanner: "PRACTICE / SCANNER"
    case .practiceToolbox: "PRACTICE / TOOLBOX"
    case .practiceDevices: "PRACTICE / DEVICES"
    case .practiceServices: "PRACTICE / SERVICES"
    case .achievements: "ACHIEVEMENTS"
    case .points: "POINTS"
    }
  }

  private var screen: String {
    switch self {
    case .dashboard, .dashboardMission, .dashboardAchievements, .dashboardPoints: "start"
    case .paths, .pathDetail: "paths"
    case .missions, .missionCard: "missions"
    case .briefing: "lesson"
    case .labMode, .labObjectives, .labTerminal, .labAnswer, .labDefense: "lab"
    case .practice, .practiceScanner, .practiceToolbox, .practiceDevices, .practiceServices: "practice"
    case .achievements: "achievements"
    case .points: "points"
    }
  }

  private var component: String {
    switch self {
    case .dashboard, .paths, .missions, .practice, .achievements, .points: "root"
    case .dashboardMission: "featuredLesson"
    case .dashboardAchievements: "achievements"
    case .dashboardPoints: "points"
    case .pathDetail: "pathDetail"
    case .missionCard: "missionCard"
    case .briefing: "briefing"
    case .labMode: "mode"
    case .labObjectives: "objectives"
    case .labTerminal: "terminal"
    case .labAnswer: "answer"
    case .labDefense: "defense"
    case .practiceScanner: "scanner"
    case .practiceToolbox: "toolbox"
    case .practiceDevices: "devices"
    case .practiceServices: "services"
    }
  }

  private var viewName: String {
    switch self {
    case .dashboard, .dashboardMission, .dashboardAchievements, .dashboardPoints: "DashboardView"
    case .paths: "LearningPathListView"
    case .pathDetail: "LearningPathDetailView"
    case .missions, .missionCard: "MissionsView"
    case .briefing: "MissionBriefingView"
    case .labMode, .labObjectives, .labTerminal, .labAnswer, .labDefense: "LabTerminalView"
    case .practice: "PracticeHubView"
    case .practiceScanner: "ScannerView"
    case .practiceToolbox: "ToolboxView"
    case .practiceDevices: "DevicesView"
    case .practiceServices: "ServicesHubView"
    case .achievements: "AchievementsView"
    case .points: "PointsView"
    }
  }

  static func isVisible(in distribution: AppDistributionMode) -> Bool {
    distribution == .developer
  }
}

struct DevLocationLabel: View {
  let location: DevLocation
  var distribution: AppDistributionMode = .currentBuild
  @State private var copied = false

  var body: some View {
    if DevLocation.isVisible(in: distribution) {
      HStack(spacing: 4) {
        Text(location.displayLabel)
        if copied {
          Image(systemName: "checkmark")
        }
      }
        .font(.caption2.monospaced().weight(.semibold))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.55)
        .contentShape(Rectangle())
        .onTapGesture(perform: copyLocation)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(location.displayLabel)
        .accessibilityHint("Kopiuje techniczny identyfikator UI")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { copyLocation() }
    }
  }

  private func copyLocation() {
    UIPasteboard.general.string = location.uiRef
    copied = true
    UIAccessibility.post(
      notification: .announcement,
      argument: "Skopiowano \(location.uiRef)"
    )
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
      copied = false
    }
  }
}

struct ToolCard<Content: View>: View {
  let icon: String
  let title: String
  let subtitle: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 11) {
      HStack(spacing: 9) {
        Image(systemName: icon)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.cyan)
          .frame(width: 32, height: 32)
          .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
        VStack(alignment: .leading, spacing: 1) {
          Text(title)
            .font(.subheadline.weight(.semibold))
          Text(subtitle)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      content
    }
    .padding(12)
    .background(.background, in: RoundedRectangle(cornerRadius: 14))
  }
}

struct AddressRow: View {
  let label: String
  let value: String

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
      Text(value)
        .font(.caption.monospaced())
        .multilineTextAlignment(.trailing)
        .textSelection(.enabled)
    }
  }
}

struct MetricCard: View {
  let title: String
  let value: String
  let icon: String
  var tint: Color = .cyan

  var body: some View {
    HStack(spacing: 9) {
      Image(systemName: icon)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(tint)
        .frame(width: 28, height: 28)
        .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 8))
      VStack(alignment: .leading, spacing: 1) {
        Text(value)
          .font(.subheadline.weight(.bold))
          .monospacedDigit()
        Text(title)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      Spacer(minLength: 0)
    }
    .padding(10)
    .background(.background, in: RoundedRectangle(cornerRadius: 12))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityValue(value)
  }
}

struct ExposureBadge: View {
  let level: ExposureLevel

  var body: some View {
    Text(level.title)
      .font(.caption2.weight(.semibold))
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .foregroundStyle(color)
      .background(color.opacity(0.12), in: Capsule())
  }

  private var color: Color {
    switch level {
    case .low: .green
    case .medium: .orange
    case .high: .red
    }
  }
}

struct DiagnosticResultView: View {
  let result: HostDiagnosticResult

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Divider()
      Label(result.host, systemImage: "globe")
        .font(.caption.weight(.semibold))

      if result.resolvedAddresses.isEmpty {
        Label("DNS: brak odpowiedzi", systemImage: "xmark.circle")
          .font(.caption)
          .foregroundStyle(.orange)
      } else {
        ForEach(result.resolvedAddresses, id: \.self) { address in
          AddressRow(label: "DNS", value: address)
        }
      }

      HStack {
        Label(statusText, systemImage: statusIcon)
          .font(.caption.weight(.medium))
          .foregroundStyle(result.portResult.status.isOpen ? .green : .orange)
        Spacer()
        if let latency = result.portResult.latencyMilliseconds {
          Text(String(format: "%.1f ms", latency))
            .font(.caption2.monospaced())
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private var statusIcon: String {
    result.portResult.status.isOpen ? "checkmark.circle.fill" : "xmark.circle.fill"
  }

  private var statusText: String {
    switch result.portResult.status {
    case .open: "Port \(result.portResult.port) otwarty"
    case .closed: "Port \(result.portResult.port) zamknięty"
    case .timedOut: "Brak odpowiedzi portu \(result.portResult.port)"
    case .localNetworkDenied: "Brak dostępu do sieci lokalnej"
    }
  }
}

struct PortResultRow: View {
  let entry: PortScanEntry

  var body: some View {
    HStack(spacing: 9) {
      Circle()
        .fill(entry.status.isOpen ? .green : .secondary.opacity(0.35))
        .frame(width: 8, height: 8)
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 5) {
          Text("\(entry.port)")
            .font(.caption.monospaced().weight(.semibold))
          Text(entry.serviceName)
            .font(.caption.weight(.semibold))
          if entry.status.isOpen && entry.info.isEncrypted {
            Image(systemName: "lock.fill")
              .font(.caption2)
              .foregroundStyle(.green)
          }
        }
        Text(entry.status.isOpen ? entry.info.description : statusText)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
      Spacer(minLength: 6)
      if let latency = entry.latencyMilliseconds {
        Text(String(format: "%.1f ms", latency))
          .font(.caption2.monospaced())
          .foregroundStyle(.secondary)
      }
    }
    .padding(10)
    .background(.background, in: RoundedRectangle(cornerRadius: 11))
  }

  private var statusText: String {
    switch entry.status {
    case .open: "Otwarty"
    case .closed: "Zamknięty"
    case .timedOut: "Brak odpowiedzi"
    case .localNetworkDenied: "Brak dostępu"
    }
  }
}
