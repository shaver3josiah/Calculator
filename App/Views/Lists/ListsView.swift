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

    var body: some View {
        @Bindable var d = drafts
        return ScrollView {
            VStack(spacing: 16) {
                KTabBar(items: ["Lists", "Notes"], selection: modeBinding)
                if drafts.lists.mode == "notes" {
                    notesPage
                } else {
                    listPicker
                    if let list = store.activeList {
                        listCard(list)
                    } else {
                        emptyState
                    }
                }
            }
            .padding(16)
        }
        .background(theme.color("bg"))
        .scrollDismissesKeyboard(.interactively)
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

    /// The draft speaks "list"/"notes"; the tab bar shows her the words she'd
    /// use. Kept apart so a label change can never rewrite what's on disk.
    private var modeBinding: Binding<String> {
        Binding(
            get: { drafts.lists.mode == "notes" ? "Notes" : "Lists" },
            set: { drafts.lists.mode = ($0 == "Notes") ? "notes" : "list" }
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

    // MARK: - Notes

    private var noteBodyIsBlank: Bool {
        drafts.notes.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var notesPage: some View {
        @Bindable var d = drafts
        return VStack(alignment: .leading, spacing: 12) {
            TextField("Name this note", text: $d.notes.title, prompt: Text("Name this note").foregroundStyle(theme.color("muted")))
                .font(bloomNumber(19, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
                .frame(minHeight: 44)

            TextField("", text: $d.notes.body, axis: .vertical)
                .lineLimit(12...40)
                .font(bloomBody(17))
                .foregroundStyle(theme.color("text"))
                .lineSpacing(5)
                .inputAccessories($d.notes.body, alignment: .top)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.color("surfaceSoft"))
                )

            Text("Start lines with - or • and I'll make them a list.")
                .font(bloomBody(12))
                .foregroundStyle(theme.color("muted"))

            HStack(spacing: 10) {
                Button {
                    saveNote()
                } label: {
                    Text("Save to history")
                        .font(bloomBody(15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(theme.color("primary"))
                        )
                }
                .buttonStyle(TactilePressStyle(cornerRadius: 14))
                .discoverable("notes.save", cornerRadius: 14)

                Button {
                    makeListFromNote()
                } label: {
                    Text("Make it a list")
                        .font(bloomBody(15, weight: .semibold))
                        .foregroundStyle(theme.color("accentInk"))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(theme.color("surfaceSoft"))
                        )
                }
                .buttonStyle(TactilePressStyle(cornerRadius: 14))
                .discoverable("notes.toList", cornerRadius: 14)
            }
            // A blank page has nothing to save and nothing to listify — she
            // should never end up with an empty list or a history entry of air.
            .disabled(noteBodyIsBlank)
            .opacity(noteBodyIsBlank ? 0.5 : 1)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surface"))
        )
    }

    private var noteDisplayTitle: String {
        let trimmed = drafts.notes.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Note" : trimmed
    }

    private func saveNote() {
        guard !noteBodyIsBlank else { return }
        let body = drafts.notes.body
        let lines = ListsStore.listItems(from: body).count
        history.add(
            type: "note",
            title: noteDisplayTitle,
            value: "\(lines) line\(lines == 1 ? "" : "s")",
            extra: ["text": body]
        )
        sound.play("success")
        ToastCenter.shared.show(title: "Saved", message: "\(noteDisplayTitle) is in your history.")
    }

    private func makeListFromNote() {
        let items = ListsStore.listItems(from: drafts.notes.body)
        // A page of nothing but bullet marks parses to zero items, so the blank
        // check above isn't enough on its own.
        guard !items.isEmpty else { return }
        let trimmed = drafts.notes.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = store.createList(title: trimmed.isEmpty ? "Notes list" : trimmed)
        for item in items {
            store.addRow(to: id, name: item, qty: 1, unitPrice: 0)
        }
        drafts.lists.mode = "list"
        sound.play("success")
        ToastCenter.shared.show(title: "Made a list", message: "\(items.count) item\(items.count == 1 ? "" : "s") added.")
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
            HStack {
                Button("Delete list") {
                    store.deleteList(list.id)
                }
                .font(bloomBody(13))
                .foregroundStyle(theme.color("muted"))
                Spacer()
                Button("Log total to history") {
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
