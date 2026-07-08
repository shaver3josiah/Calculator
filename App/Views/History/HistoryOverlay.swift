import SwiftUI
import BloomCore

struct HistoryOverlay: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeStore.self) private var theme
    @Environment(CalcStore.self) private var calc
    @Environment(HistoryStore.self) private var history
    @Environment(SoundStore.self) private var sound
    @Environment(ListsStore.self) private var lists

    @State private var showClearConfirm = false
    @State private var recycleTarget: HistoryEntry?
    @State private var isSelecting = false
    @State private var selectedIds: Set<String> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                if history.groupedEntries().isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
            .background(theme.color("bg"))
            .navigationTitle(isSelecting ? selectionTitle : "History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isSelecting {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", action: cancelSelection)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: formatShareText(selectedEntries))
                            .disabled(selectedIds.isEmpty)
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Select") { isSelecting = true }
                            .disabled(history.groupedEntries().isEmpty)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") { showClearConfirm = true }
                    }
                }
            }
            .confirmationDialog(
                "Clear history?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear non-favorites", role: .destructive) {
                    history.clearNonFavorites()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Pinned entries stay. This cannot be undone.")
            }
        }
        .sheet(item: $recycleTarget) { entry in
            RecycleSheet(entry: entry)
        }
    }

    private var selectionTitle: String {
        selectedIds.isEmpty ? "Select Items" : "\(selectedIds.count) Selected"
    }

    private func cancelSelection() {
        isSelecting = false
        selectedIds.removeAll()
    }

    private func toggleSelection(_ entry: HistoryEntry) {
        if selectedIds.contains(entry.id) {
            selectedIds.remove(entry.id)
        } else {
            selectedIds.insert(entry.id)
        }
    }

    private var selectedEntries: [HistoryEntry] {
        history.groupedEntries().flatMap { $0.entries }.filter { selectedIds.contains($0.id) }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.color("muted"))
            TextField("Search your history", text: Binding(
                get: { history.searchText },
                set: { history.searchText = $0 }
            ), prompt: Text("Search your history").foregroundColor(theme.color("muted")))
            .font(bloomBody(15))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surfaceSoft"))
        )
        .padding(16)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("No history yet")
                .font(bloomNumber(20))
                .foregroundStyle(theme.color("deep"))
            Text("Your calculations, projections, and lists will show up here.")
                .font(bloomBody(14))
                .foregroundStyle(theme.color("muted"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var entryList: some View {
        List {
            ForEach(history.groupedEntries(), id: \.label) { group in
                Section {
                    ForEach(group.entries) { entry in
                        HistoryRow(
                            entry: entry,
                            isFavorite: history.isFavorite(entry),
                            isSelecting: isSelecting,
                            isSelected: selectedIds.contains(entry.id),
                            onTap: { insertEntry(entry) },
                            onFavorite: { history.toggleFavorite(entry) },
                            onRecycle: { recycleTarget = entry },
                            onReopen: { reopenEntry(entry) },
                            onToggleSelect: { toggleSelection(entry) }
                        )
                        .listRowBackground(theme.color("bg"))
                    }
                } header: {
                    Text(group.label)
                        .foregroundColor(theme.color("muted"))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func insertEntry(_ entry: HistoryEntry) {
        guard entry.type == "calc" else { return }
        calc.press("clear")
        for ch in entry.value {
            switch ch {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                calc.press("d\(ch)")
            case ".":
                calc.press("dot")
            case "-":
                calc.press("sign")
            default:
                continue
            }
        }
        sound.play("tap1")
        dismiss()
    }

    private func reopenEntry(_ entry: HistoryEntry) {
        switch entry.type {
        case "list":
            lists.reopen(from: entry)
            dismiss()
        default:
            break
        }
    }
}

private struct HistoryRow: View {
    @Environment(ThemeStore.self) private var theme
    let entry: HistoryEntry
    let isFavorite: Bool
    let isSelecting: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onRecycle: () -> Void
    let onReopen: () -> Void
    let onToggleSelect: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            leadingAccessory
            Button(action: isSelecting ? onToggleSelect : onTap) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(bloomBody(15, weight: .medium))
                            .foregroundStyle(theme.color("text"))
                        Text(kindLabel)
                            .font(bloomBody(12))
                            .foregroundStyle(theme.color("muted"))
                    }
                    Spacer()
                    Text(entry.value)
                        .font(bloomNumber(16))
                        .foregroundStyle(theme.color("deep"))
                }
            }
            .buttonStyle(.plain)
        }
        .swipeActions(edge: .trailing) {
            if !isSelecting {
                if entry.type == "calc" {
                    Button("Recycle", action: onRecycle)
                        .tint(.orange)
                } else if entry.type == "list" {
                    Button("Reopen", action: onReopen)
                        .tint(.blue)
                }
            }
        }
        .swipeActions(edge: .leading) {
            if !isSelecting {
                Button(isFavorite ? "Unpin" : "Pin", action: onFavorite)
                    .tint(.pink)
            }
        }
    }

    @ViewBuilder
    private var leadingAccessory: some View {
        if isSelecting {
            Button(action: onToggleSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? theme.color("primaryStrong") : theme.color("muted"))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSelected ? "Deselect" : "Select")
        } else {
            Button(action: onFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 18))
                    .foregroundStyle(isFavorite ? theme.color("primaryStrong") : theme.color("muted"))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Unpin" : "Pin")
        }
    }

    private var kindLabel: String {
        switch entry.type {
        case "proj": return "Projection"
        case "list": return "List"
        default: return "Calculation"
        }
    }
}

private func entryShareLines(_ entry: HistoryEntry) -> [String] {
    if entry.type == "calc" {
        let expression = prettifyExpression(entry.extra["tokens"]) ?? entry.title
        return [expression, "= \(entry.value)"]
    }
    return [entry.title, entry.value]
}

private func prettifyExpression(_ raw: String?) -> String? {
    guard let raw, !raw.isEmpty else { return nil }
    let operators: Set<Character> = ["+", "\u{2212}", "\u{00D7}", "\u{00F7}"]
    var spaced = ""
    for ch in raw {
        if operators.contains(ch) {
            spaced += " \(ch) "
        } else {
            spaced.append(ch)
        }
    }
    return spaced.trimmingCharacters(in: .whitespaces)
}

private func formatShareText(_ entries: [HistoryEntry]) -> String {
    guard entries.count > 1 else {
        return entries.first.map { entryShareLines($0).joined(separator: "\n") } ?? ""
    }
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .none
    let blocks = entries.map { entry -> String in
        (entryShareLines(entry) + [dateFormatter.string(from: entry.ts)]).joined(separator: "\n")
    }
    return (["Hannah's Calculator"] + blocks).joined(separator: "\n\n")
}
