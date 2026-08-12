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

    // Fixed ids, NOT UUID(). A `static let` initialiser runs once per process,
    // so UUID() minted four fresh ids on every cold launch - her saved Grow fund
    // pick pointed at last launch's id and silently fell back to the default.
    private static let defaultFunds: [Fund] = [
        Fund(id: UUID(uuidString: "B10E0000-0000-4000-A000-000000000001")!, name: "Conservative", ratePct: 4),
        Fund(id: UUID(uuidString: "B10E0000-0000-4000-A000-000000000002")!, name: "Balanced", ratePct: 6),
        Fund(id: UUID(uuidString: "B10E0000-0000-4000-A000-000000000003")!, name: "Growth", ratePct: 8),
        Fund(id: UUID(uuidString: "B10E0000-0000-4000-A000-000000000004")!, name: "Aggressive", ratePct: 10)
    ]
}
