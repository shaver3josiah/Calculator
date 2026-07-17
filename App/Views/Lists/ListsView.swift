import SwiftUI
import BloomCore

struct ListsView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(ListsStore.self) private var store
    @Environment(HistoryStore.self) private var history
    @Environment(SoundStore.self) private var sound
    @Environment(DraftStore.self) private var drafts

    @State private var showNewListPrompt = false
    @State private var editingRow: ShopListRow?
    @State private var editingListId: UUID?
    /// True while she's typing in the notes editor — hides the tab bar so the
    /// page is hers alone.
    @State private var composing = false

    var body: some View {
        @Bindable var d = drafts
        return VStack(spacing: 0) {
            if !composing {
                KTabBar(items: ["Lists", "Notes", "Archive"], selection: modeBinding)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            content
        }
        .background(theme.color("bg"))
        .onChange(of: drafts.lists.mode) { _, newMode in
            if newMode != "notes" { composing = false }
        }
        .sheet(item: $editingRow) { row in
            EditListItemSheet(row: row) { updated in
                if let listId = editingListId {
                    store.updateRow(listId: listId, row: updated)
                }
            } onDelete: {
                if let listId = editingListId {
                    store.deleteRow(listId: listId, rowId: row.id)
                }
            }
        }
        .alert("Name this list", isPresented: $showNewListPrompt) {
            TextField("Groceries, a trip, the month", text: $d.lists.newListTitle, prompt: Text("Groceries, a trip, the month").foregroundStyle(theme.color("muted")))
            Button("Create") {
                _ = store.createList(title: drafts.lists.newListTitle)
                drafts.lists.newListTitle = ""
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var content: some View {
        switch drafts.lists.mode {
        case "notes":
            // Manages its own scrolling (a UITextView underneath) and its own
            // full height — deliberately NOT wrapped in the outer ScrollView.
            NotesEditorView(composing: $composing)
        case "archive":
            ScrollView {
                NotesArchiveView()
                    .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
        default:
            ScrollView {
                VStack(spacing: 16) {
                    listPicker
                    if let list = store.activeList {
                        listCard(list)
                    } else {
                        emptyState
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    /// The draft speaks "list"/"notes"/"archive"; the tab bar shows her the words.
    /// Kept apart so a label change can never rewrite what's on disk.
    private var modeBinding: Binding<String> {
        Binding(
            get: {
                switch drafts.lists.mode {
                case "notes": return "Notes"
                case "archive": return "Archive"
                default: return "Lists"
                }
            },
            set: {
                switch $0 {
                case "Notes": drafts.lists.mode = "notes"
                case "Archive": drafts.lists.mode = "archive"
                default: drafts.lists.mode = "list"
                }
            }
        )
    }

    private var listPicker: some View {
        HStack {
            Menu {
                ForEach(store.lists) { list in
                    Button(list.title) { store.activeListId = list.id }
                }
            } label: {
                HStack {
                    Text(store.activeList?.title ?? "No lists yet")
                        .font(bloomNumber(19, weight: .semibold))
                        .foregroundStyle(theme.color("deep"))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13))
                        .foregroundStyle(theme.color("muted"))
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            Spacer()
            Button {
                showNewListPrompt = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(theme.color("accentInk"))
                    .frame(width: 44, height: 44)
            }
            .discoverable("lists.new", cornerRadius: 999)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("Start a list")
                .font(bloomNumber(20))
                .foregroundStyle(theme.color("deep"))
            Text("Groceries, a trip, or the month. Tap + to begin.")
                .font(bloomBody(14))
                .foregroundStyle(theme.color("muted"))
        }
        .padding(.top, 60)
    }

    // MARK: - Lists

    private func listCard(_ list: ShopList) -> some View {
        VStack(spacing: 12) {
            ForEach(list.rows) { row in
                rowView(listId: list.id, row: row)
            }
            if !list.rows.isEmpty {
                Text("Tap a row to edit it.")
                    .font(bloomBody(11))
                    .foregroundStyle(theme.color("muted"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            addRow(listId: list.id)
            totalsBar(list)
            HStack(spacing: 14) {
                Button("Delete list") {
                    store.deleteList(list.id)
                }
                .font(bloomBody(13))
                .foregroundStyle(theme.color("muted"))

                ShareLink(item: listShareText(list)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(bloomBody(13, weight: .semibold))
                        .foregroundStyle(theme.color("accentInk"))
                }
                .disabled(list.rows.isEmpty)
                .opacity(list.rows.isEmpty ? 0.4 : 1)

                Spacer()
                Button("Log total") {
                    store.logTotalToHistory(listId: list.id, history: history)
                    sound.play("success")
                }
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(theme.color("accentInk"))
                .discoverable("lists.logTotal", cornerRadius: 12)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surface"))
        )
    }

    /// Plain-text version of a list she can drop into a message.
    private func listShareText(_ list: ShopList) -> String {
        var lines = [list.title.isEmpty ? "List" : list.title, ""]
        for row in list.rows {
            let check = row.checked ? "✓ " : "• "
            if row.qty != 1 || row.unitPrice != 0 {
                lines.append("\(check)\(row.name) — \(Formatters.plain(row.qty)) × \(Formatters.money(row.unitPrice)) = \(Formatters.money(row.lineTotal))")
            } else {
                lines.append("\(check)\(row.name)")
            }
        }
        lines.append("")
        lines.append("Total: \(Formatters.money(list.total))")
        return lines.joined(separator: "\n")
    }

    private func rowView(listId: UUID, row: ShopListRow) -> some View {
        HStack(spacing: 10) {
            Button {
                store.toggleChecked(listId: listId, rowId: row.id)
            } label: {
                Image(systemName: row.checked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(row.checked ? theme.color("good") : theme.color("muted"))
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())

            Button {
                editingListId = listId
                editingRow = row
            } label: {
                HStack(spacing: 10) {
                    Text(row.name)
                        .font(bloomBody(15))
                        .foregroundStyle(row.checked ? theme.color("muted") : theme.color("text"))
                        .strikethrough(row.checked)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(Formatters.plain(row.qty))
                        .font(bloomBody(13))
                        .foregroundStyle(theme.color("muted"))
                        .frame(width: 36)

                    Text(Formatters.money(row.lineTotal))
                        .font(bloomNumber(14))
                        .foregroundStyle(theme.color("deep"))
                        .frame(width: 70, alignment: .trailing)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                store.deleteRow(listId: listId, rowId: row.id)
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(theme.color("muted"))
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
    }

    private func addRow(listId: UUID) -> some View {
        @Bindable var d = drafts
        return HStack(spacing: 8) {
            TextField("Item", text: $d.lists.newItemName, prompt: Text("Item").foregroundStyle(theme.color("muted")))
                .font(bloomBody(14))
                .inputAccessories($d.lists.newItemName, compact: true)
            TextField("Qty", text: $d.lists.newItemQty, prompt: Text("Qty").foregroundStyle(theme.color("muted")))
                .keyboardType(.decimalPad)
                .font(bloomBody(14))
                .frame(width: 44)
            TextField("Price", text: $d.lists.newItemPrice, prompt: Text("Price").foregroundStyle(theme.color("muted")))
                .keyboardType(.decimalPad)
                .font(bloomBody(14))
                .frame(width: 60)
            Button {
                addItem(listId: listId)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(theme.color("accentInk"))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(TactilePressStyle(cornerRadius: 999))
            .discoverable("lists.addItem", cornerRadius: 999)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.color("surfaceSoft"))
        )
    }

    private func addItem(listId: UUID) {
        guard !drafts.lists.newItemName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let qty = Double(drafts.lists.newItemQty) ?? 1
        let price = Double(drafts.lists.newItemPrice) ?? 0
        store.addRow(to: listId, name: drafts.lists.newItemName, qty: qty, unitPrice: price)
        drafts.lists.newItemName = ""
        drafts.lists.newItemQty = "1"
        drafts.lists.newItemPrice = ""
        sound.play("tap1")
    }

    private func totalsBar(_ list: ShopList) -> some View {
        HStack {
            Text("TOTAL")
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(theme.color("muted"))
            Spacer()
            Text(Formatters.money(list.total))
                .font(bloomNumber(22, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
        }
        .padding(.top, 4)
    }
}
