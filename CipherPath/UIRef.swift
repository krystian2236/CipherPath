import Foundation

enum UIRef: String, CaseIterable, Sendable {
  case dashboard = "CIPHERPATH.DASHBOARD"
  case todayMission = "CIPHERPATH.DASHBOARD.TODAY_MISSION"
  case missionStages = "CIPHERPATH.DASHBOARD.MISSION_STAGES"
  case networkSnapshot = "CIPHERPATH.DASHBOARD.NETWORK_SNAPSHOT"
  case practice = "CIPHERPATH.PRACTICE"
  case security = "CIPHERPATH.SECURITY"
  case learn = "CIPHERPATH.LEARN"
  case progress = "CIPHERPATH.PROGRESS"

  var label: String {
    switch self {
    case .dashboard: "Start"
    case .todayMission: "Dzisiejsza misja"
    case .missionStages: "Etapy misji"
    case .networkSnapshot: "Stan sieci"
    case .practice: "Practice"
    case .security: "Security"
    case .learn: "Learn"
    case .progress: "Progress"
    }
  }

  var source: String {
    switch self {
    case .dashboard, .todayMission, .missionStages, .networkSnapshot: "CipherPath/DashboardView.swift"
    case .practice, .security: "CipherPath/AppShellView.swift"
    case .learn: "CipherPath/LearningPathListView.swift"
    case .progress: "CipherPath/AchievementsView.swift"
    }
  }

  var symbol: String {
    switch self {
    case .dashboard: "body"
    case .todayMission: "missionCard"
    case .missionStages: "missionStages"
    case .networkSnapshot: "networkSnapshot"
    case .practice: "PracticeHubView"
    case .security: "SecurityHubView"
    case .learn: "LearningPathListView"
    case .progress: "AchievementsView"
    }
  }

  var clipboardText: String {
    "UIREF: \(rawValue)\nLabel: \(label)\nSource: \(source)\nSymbol: \(symbol)"
  }
}
