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
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: history.shareText())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") { showClearConfirm = true }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
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
                            onTap: { insertEntry(entry) },
                            onFavorite: { history.toggleFavorite(entry) },
                            onRecycle: { recycleTarget = entry },
                            onReopen: { reopenEntry(entry) }
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
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onRecycle: () -> Void
    let onReopen: () -> Void

    var body: some View {
        Button(action: onTap) {
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
        .swipeActions(edge: .trailing) {
            if entry.type == "calc" {
                Button("Recycle", action: onRecycle)
                    .tint(.orange)
            } else if entry.type == "list" {
                Button("Reopen", action: onReopen)
                    .tint(.blue)
            }
        }
        .swipeActions(edge: .leading) {
            Button(isFavorite ? "Unpin" : "Pin", action: onFavorite)
                .tint(.pink)
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
