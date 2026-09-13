import Foundation
import Testing

@testable import CipherPath

@Suite("Points wallet")
struct PointsWalletTests {
  @Test("New wallet starts with one hundred points")
  func startsWithInitialBalance() {
    let wallet = PointsWallet.initial

    #expect(wallet.balance == 100)
    #expect(wallet.transactions.map(\.id) == ["initial"])
  }

  @Test("Hint costs twenty points only once per mission mode")
  func hintIsChargedOnce() {
    var wallet = PointsWallet.initial

    #expect(wallet.purchase(.hint, lessonID: "web-http", mode: .guided) == .purchased)
    #expect(wallet.balance == 80)
    #expect(wallet.purchase(.hint, lessonID: "web-http", mode: .guided) == .alreadyUnlocked)
    #expect(wallet.balance == 80)
  }

  @Test("Solution costs fifty points")
  func solutionHasExpectedCost() {
    var wallet = PointsWallet.initial

    #expect(wallet.purchase(.solution, lessonID: "network-scout", mode: .adventure) == .purchased)
    #expect(wallet.balance == 50)
  }

  @Test("Purchase cannot make balance negative")
  func rejectsPurchaseWithoutEnoughPoints() {
    var wallet = PointsWallet(
      transactions: [
        PointsTransaction(
          id: "fixture",
          kind: .initialBalance,
          amount: 10,
          date: Date(timeIntervalSince1970: 1),
          lessonID: nil,
          mode: nil
        )
      ]
    )

    #expect(wallet.purchase(.hint, lessonID: "mobile-storage", mode: .guided) == .insufficient(missing: 10))
    #expect(wallet.balance == 10)
    #expect(wallet.transactions.count == 1)
  }

  @Test("Mission reward is granted only once across modes")
  func missionRewardIsIdempotent() {
    var wallet = PointsWallet.initial

    let firstReward = wallet.rewardMission(lessonID: "fundamentals-scout")
    let repeatedReward = wallet.rewardMission(lessonID: "fundamentals-scout")

    #expect(firstReward)
    #expect(!repeatedReward)
    #expect(wallet.balance == 200)
    #expect(wallet.transactions.filter { $0.kind == .missionReward }.count == 1)
  }

  @Test("Developer adjustment adds test points")
  func addsDeveloperTestPoints() {
    var wallet = PointsWallet.initial

    wallet.addDevelopmentPoints(100, date: Date(timeIntervalSince1970: 30))

    #expect(wallet.balance == 200)
    #expect(wallet.transactions.last?.kind == .developerAdjustment)
  }
}
