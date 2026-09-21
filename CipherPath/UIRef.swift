import Foundation

enum UIRef: String, CaseIterable, Sendable {
  case dashboard = "CIPHERPATH.DASHBOARD"
  case todayMission = "CIPHERPATH.DASHBOARD.TODAY_MISSION"
  case missionStages = "CIPHERPATH.DASHBOARD.MISSION_STAGES"
  case networkSnapshot = "CIPHERPATH.DASHBOARD.NETWORK_SNAPSHOT"
  case practice = "CIPHERPATH.PRACTICE"
  case paths = "CIPHERPATH.PATHS"
  case achievements = "CIPHERPATH.ACHIEVEMENTS"

  var label: String {
    switch self {
    case .dashboard: "Start"
    case .todayMission: "Dzisiejsza misja"
    case .missionStages: "Etapy misji"
    case .networkSnapshot: "Stan sieci"
    case .practice: "Praktyka"
    case .paths: "Ścieżki"
    case .achievements: "Osiągnięcia"
    }
  }

  var source: String {
    switch self {
    case .dashboard, .todayMission, .missionStages, .networkSnapshot: "CipherPath/DashboardView.swift"
    case .practice: "CipherPath/AppShellView.swift"
    case .paths: "CipherPath/LearningPathListView.swift"
    case .achievements: "CipherPath/AchievementsView.swift"
    }
  }

  var symbol: String {
    switch self {
    case .dashboard: "body"
    case .todayMission: "missionCard"
    case .missionStages: "missionStages"
    case .networkSnapshot: "networkSnapshot"
    case .practice: "PracticeHubView"
    case .paths: "LearningPathListView"
    case .achievements: "AchievementsView"
    }
  }

  var clipboardText: String {
    "UIREF: \(rawValue)\nLabel: \(label)\nSource: \(source)\nSymbol: \(symbol)"
  }
}
