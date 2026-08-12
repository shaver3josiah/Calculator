import SwiftUI
import BloomCore

struct ImportBudgetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @State private var text = ""
    @State private var failed = false
    /// Set only when the import would overwrite a month she has already worked
    /// on. Most imports are of a month she doesn't have yet, and those just go
    /// in - a dialog that also fires on the harmless case is one she learns to
    /// tap through, which is how the dangerous case gets waved past too.
    @State private var replace: ReplacePrompt?

    private struct ReplacePrompt {
        let key: String
        let mine: String
        let theirs: String
        var title: String { "Replace \(BudgetMath.monthLabel(key))?" }
        var message: String {
            "You have \(mine) in \(BudgetMath.monthLabel(key)). The shared one has \(theirs). Replacing yours can't be undone."
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Paste a shared budget. It ends with a #hannahs-budget-v1 code.")
                        .font(bloomBody(14))
                        .foregroundStyle(theme.color("muted"))
                    TextEditor(text: $text)
                        .font(bloomBody(13))
                        .frame(minHeight: 160)
                        .scrollContentBackground(.hidden)
                        .inputAccessories($text, alignment: .top)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 12).fill(theme.color("surface")))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(theme.color("line")))
                    if failed {
                        Text("That text doesn\u{2019}t contain a shared budget.")
                            .font(bloomBody(13, weight: .medium))
                            .foregroundStyle(theme.color("deep"))
                    }
                    Button {
                        attemptImport()
                    } label: {
                        Text("Import")
                            .font(bloomBody(15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(theme.color("primaryStrong")))
                    }
                    .buttonStyle(.plain)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(20)
            }
            .background(theme.color("bg"))
            .navigationTitle("Import a budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert(
                replace?.title ?? "",
                isPresented: Binding(get: { replace != nil }, set: { if !$0 { replace = nil } }),
                presenting: replace
            ) { _ in
                Button("Replace", role: .destructive) { commit() }
                // Cancel leaves her text in the box rather than closing the sheet,
                // so "not that month" is a correction, not a restart.
                Button("Keep mine", role: .cancel) { replace = nil }
            } message: { prompt in
                Text(prompt.message)
            }
        }
    }

    /// Nothing to lose -> import. Something to lose -> ask, once, with both
    /// sides of the trade named.
    private func attemptImport() {
        guard let incoming = store.previewImport(text) else {
            failed = true
            return
        }
        if let mine = store.replacementSummary(for: incoming.key) {
            replace = ReplacePrompt(key: incoming.key, mine: mine, theirs: incoming.summary)
        } else {
            commit()
        }
    }

    private func commit() {
        replace = nil
        if store.importShared(text) {
            dismiss()
        } else {
            failed = true
        }
    }
}
