import Foundation
import BloomCore

/// A one-shot handoff from the budget tab: "project this monthly leftover".
/// Consumed (and cleared) by GrowPanel's onAppear.
struct PendingGrow {
    var monthly: Double
}

@Observable
final class ProjectionStore {
    var funds: [Fund]

    // Transient handoff state — deliberately NOT persisted: a relaunch should
    // never replay an old "jump to Grow" or refill the monthly field.
    var pendingGrow: PendingGrow?
    var jumpToGrowEpoch = 0

    init() {
        if let saved = JSONStore.shared.get(.funds, as: [Fund].self), !saved.isEmpty {
            funds = saved
        } else {
            funds = ProjectionStore.defaultFunds
        }
    }

    func addFund(name: String, ratePct: Double) {
        funds.append(Fund(id: UUID(), name: name, ratePct: ratePct))
        persist()
    }

    func updateFund(id: UUID, name: String, ratePct: Double) {
        guard let index = funds.firstIndex(where: { $0.id == id }) else { return }
        funds[index].name = name
        funds[index].ratePct = ratePct
        persist()
    }

    func removeFund(id: UUID) {
        funds.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        JSONStore.shared.set(.funds, funds)
    }

    private static let defaultFunds: [Fund] = [
        Fund(id: UUID(), name: "Conservative", ratePct: 4),
        Fund(id: UUID(), name: "Balanced", ratePct: 6),
        Fund(id: UUID(), name: "Growth", ratePct: 8),
        Fund(id: UUID(), name: "Aggressive", ratePct: 10)
    ]
}
