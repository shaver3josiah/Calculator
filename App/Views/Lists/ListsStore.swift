import SwiftUI
import BloomCore

struct ShopListRow: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var qty: Double
    var unitPrice: Double
    var checked: Bool = false

    var lineTotal: Double { qty * unitPrice }
}

struct ShopList: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var rows: [ShopListRow]
    var createdAt: Date = Date()

    var total: Double { rows.reduce(0) { $0 + $1.lineTotal } }
}

@Observable
final class ListsStore {
    var lists: [ShopList] {
        didSet { JSONStore.shared.set(.shopLists, lists) }
    }
    var activeListId: UUID?

    init() {
        let loaded = JSONStore.shared.get(.shopLists, as: [ShopList].self) ?? []
        lists = loaded
        activeListId = loaded.first?.id
    }

    var activeList: ShopList? {
        get {
            guard let id = activeListId else { return lists.first }
            return lists.first { $0.id == id }
        }
    }

    func createList(title: String) -> UUID {
        let newList = ShopList(title: title.isEmpty ? "New list" : title, rows: [])
        lists.insert(newList, at: 0)
        activeListId = newList.id
        return newList.id
    }

    func deleteList(_ id: UUID) {
        lists.removeAll { $0.id == id }
        if activeListId == id {
            activeListId = lists.first?.id
        }
    }

    func addRow(to listId: UUID, name: String, qty: Double, unitPrice: Double) {
        guard let idx = lists.firstIndex(where: { $0.id == listId }) else { return }
        lists[idx].rows.append(ShopListRow(name: name, qty: qty, unitPrice: unitPrice))
    }

    func updateRow(listId: UUID, row: ShopListRow) {
        guard let listIdx = lists.firstIndex(where: { $0.id == listId }) else { return }
        guard let rowIdx = lists[listIdx].rows.firstIndex(where: { $0.id == row.id }) else { return }
        lists[listIdx].rows[rowIdx] = row
    }

    func deleteRow(listId: UUID, rowId: UUID) {
        guard let listIdx = lists.firstIndex(where: { $0.id == listId }) else { return }
        lists[listIdx].rows.removeAll { $0.id == rowId }
    }

    func toggleChecked(listId: UUID, rowId: UUID) {
        guard let listIdx = lists.firstIndex(where: { $0.id == listId }) else { return }
        guard let rowIdx = lists[listIdx].rows.firstIndex(where: { $0.id == rowId }) else { return }
        lists[listIdx].rows[rowIdx].checked.toggle()
    }

    func addIngredient(name: String) {
        guard let id = activeListId ?? lists.first?.id else {
            let newId = createList(title: "Groceries")
            addRow(to: newId, name: name, qty: 1, unitPrice: 0)
            return
        }
        addRow(to: id, name: name, qty: 1, unitPrice: 0)
    }

    func addIngredient(name: String, qty: Double) {
        guard let id = activeListId ?? lists.first?.id else {
            let newId = createList(title: "Groceries")
            addRow(to: newId, name: name, qty: qty, unitPrice: 0)
            return
        }
        addRow(to: id, name: name, qty: qty, unitPrice: 0)
    }

    func logTotalToHistory(listId: UUID, history: HistoryStore) {
        guard let list = lists.first(where: { $0.id == listId }) else { return }
        history.add(
            type: "list",
            title: list.title,
            value: Formatters.money(list.total),
            extra: ["listId": list.id.uuidString]
        )
    }

    // MARK: - Notes → list

    private static let bulletMarkers = ["- ", "* ", "• ", "· ", "– ", "— "]

    /// The line minus its bullet/number marker, or nil if it carries no marker.
    /// A marker with nothing behind it returns "" so the caller can drop it.
    private static func stripMarker(_ line: String) -> String? {
        for marker in bulletMarkers where line.hasPrefix(marker) {
            return String(line.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
        }
        if bulletMarkers.contains(where: { line == $0.trimmingCharacters(in: .whitespaces) }) {
            return ""
        }
        // "1." / "2)" numbering: digits, then a dot or paren, then the item.
        let digits = line.prefix { $0.isNumber }
        if !digits.isEmpty {
            let rest = line.dropFirst(digits.count)
            if let separator = rest.first, separator == "." || separator == ")" {
                return String(rest.dropFirst()).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    /// Her note, read as a list. Pure and static so it can be reasoned about
    /// (and tested) without standing up a view.
    ///
    /// Two passes, because a plain list is a list too: if she marked NO line,
    /// the whole page is her list. If she marked some, only those are items —
    /// otherwise the heading or stray thought she wrote above the bullets would
    /// arrive as groceries. Capped at 200 so a pasted wall of text can't build
    /// a list she'd have to delete a row at a time.
    static func listItems(from text: String) -> [String] {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let marked = lines.compactMap { stripMarker($0) }
        let items = marked.isEmpty ? lines : marked
        return Array(items.filter { !$0.isEmpty }.prefix(200))
    }

    func reopen(from entry: HistoryEntry) {
        guard let idString = entry.extra["listId"], let id = UUID(uuidString: idString) else { return }
        if lists.contains(where: { $0.id == id }) {
            activeListId = id
        }
    }
}
