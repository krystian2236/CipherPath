import Foundation

enum PointsPurchase: String, Codable, Equatable, Sendable {
  case hint
  case solution

  var cost: Int {
    switch self {
    case .hint: 20
    case .solution: 50
    }
  }
}

enum PointsTransactionKind: String, Codable, Equatable, Sendable {
  case initialBalance
  case missionReward
  case hint
  case solution
  case developerAdjustment
}

struct PointsTransaction: Identifiable, Codable, Equatable, Sendable {
  let id: String
  let kind: PointsTransactionKind
  let amount: Int
  let date: Date
  let lessonID: String?
  let mode: LabMode?
}

enum PointsPurchaseResult: Equatable, Sendable {
  case purchased
  case alreadyUnlocked
  case insufficient(missing: Int)
}

struct PointsWallet: Codable, Equatable, Sendable {
  private(set) var transactions: [PointsTransaction]

  static var initial: Self {
    PointsWallet(
      transactions: [
        PointsTransaction(
          id: "initial",
          kind: .initialBalance,
          amount: 100,
          date: Date(timeIntervalSince1970: 0),
          lessonID: nil,
          mode: nil
        )
      ]
    )
  }

  init(transactions: [PointsTransaction]) {
    self.transactions = transactions
  }

  var balance: Int {
    transactions.reduce(0) { $0 + $1.amount }
  }

  @discardableResult
  mutating func purchase(
    _ purchase: PointsPurchase,
    lessonID: String,
    mode: LabMode,
    date: Date = Date()
  ) -> PointsPurchaseResult {
    let transactionID = "purchase:\(purchase.rawValue):\(lessonID):\(mode.rawValue)"
    guard !transactions.contains(where: { $0.id == transactionID }) else {
      return .alreadyUnlocked
    }
    guard balance >= purchase.cost else {
      return .insufficient(missing: purchase.cost - balance)
    }

    transactions.append(
      PointsTransaction(
        id: transactionID,
        kind: purchase == .hint ? .hint : .solution,
        amount: -purchase.cost,
        date: date,
        lessonID: lessonID,
        mode: mode
      )
    )
    return .purchased
  }

  @discardableResult
  mutating func rewardMission(lessonID: String, date: Date = Date()) -> Bool {
    let transactionID = "reward:\(lessonID)"
    guard !transactions.contains(where: { $0.id == transactionID }) else { return false }

    transactions.append(
      PointsTransaction(
        id: transactionID,
        kind: .missionReward,
        amount: 100,
        date: date,
        lessonID: lessonID,
        mode: nil
      )
    )
    return true
  }

  mutating func addDevelopmentPoints(_ amount: Int, date: Date = Date()) {
    guard amount > 0 else { return }
    transactions.append(
      PointsTransaction(
        id: "developer:\(UUID().uuidString)",
        kind: .developerAdjustment,
        amount: amount,
        date: date,
        lessonID: nil,
        mode: nil
      )
    )
  }
}
