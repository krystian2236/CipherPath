import Foundation
import StoreKit

actor StoreEntitlementStore {
  private(set) var currentSnapshot = StoreEntitlementSnapshot(activeProductIDs: [])
  private var updatesTask: Task<Void, Never>?

  func refresh() async {
    var activeProductIDs = Set<String>()

    for await result in Transaction.currentEntitlements {
      guard case .verified(let transaction) = result else { continue }
      activeProductIDs.insert(transaction.productID)
    }

    currentSnapshot = StoreEntitlementSnapshot(activeProductIDs: activeProductIDs)
  }

  func startObservingUpdates() {
    guard updatesTask == nil else { return }

    updatesTask = Task { [weak self] in
      for await result in Transaction.updates {
        guard case .verified(let transaction) = result else { continue }
        await transaction.finish()
        await self?.refresh()
      }
    }
  }

  func stopObservingUpdates() {
    updatesTask?.cancel()
    updatesTask = nil
  }

  deinit {
    updatesTask?.cancel()
  }
}
