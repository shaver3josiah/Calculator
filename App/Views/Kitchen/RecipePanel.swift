import SwiftUI
import BloomCore

struct RecipePanel: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(DraftStore.self) private var drafts

    var body: some View {
        @Bindable var d = drafts
        VStack(spacing: 14) {
            Picker("Mode", selection: $d.picks.recipeMode) {
                Text("Write").tag("write")
                Text("From a link").tag("link")
                Text("Share").tag("share")
            }
            .pickerStyle(.segmented)
            .tint(theme.color("primaryStrong"))

            switch drafts.picks.recipeMode {
            case "link":
                RecipeLinkPanel()
            case "share":
                RecipeSharePanel()
            default:
                RecipeWritePanel()
            }
        }
    }
}

struct RecipeWritePanel: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var kitchen
    @Environment(ListsStore.self) private var lists
    @Environment(SoundStore.self) private var sound
    @Environment(DraftStore.self) private var drafts

    /// Read-side shorthand. Every field she types lives in the draft, so tapping
    /// another tab (which tears this view down) no longer costs her the recipe.
    private var w: RecipeWriteDraft { drafts.recipeWrite }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Recipe name", text: bind(\.name), prompt: Text("Recipe name").foregroundStyle(theme.color("muted")))
                .font(bloomBody(15))
                .foregroundStyle(theme.color("text"))
                .inputAccessories(bind(\.name))
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surface")))

            HStack {
                TextField("Serves 4", text: bind(\.serves), prompt: Text("Serves 4").foregroundStyle(theme.color("muted")))
                TextField("45 min", text: bind(\.time), prompt: Text("45 min").foregroundStyle(theme.color("muted")))
            }
            .font(bloomBody(14))
            .foregroundStyle(theme.color("text"))
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surface")))

            sectionHeader("Ingredients")
            ForEach(w.ingredients.indices, id: \.self) { idx in
                editableRow(text: bindRow(\.ingredients, idx: idx), placeholder: "1 cup flour", deleteLabel: "Remove ingredient") {
                    removeRow(\.ingredients, at: idx)
                }
            }
            addRow("+ ingredient") { drafts.recipeWrite.ingredients.append("") }

            sectionHeader("Steps")
            ForEach(w.steps.indices, id: \.self) { idx in
                editableRow(text: bindRow(\.steps, idx: idx), placeholder: "what to do", deleteLabel: "Remove step") {
                    removeRow(\.steps, at: idx)
                }
            }
            addRow("+ step") { drafts.recipeWrite.steps.append("") }

            TextField("Notes (storage, swaps, a little love note...)", text: bind(\.notes), prompt: Text("Notes (storage, swaps, a little love note...)").foregroundStyle(theme.color("muted")), axis: .vertical)
                .font(bloomBody(14))
                .foregroundStyle(theme.color("text"))
                .lineLimit(3...6)
                .inputAccessories(bind(\.notes), alignment: .top)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surface")))

            previewCard

            HStack {
                Button("Add to shopping list") {
                    addToList()
                }
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(theme.color("primaryStrong"))
                Spacer()
                Button {
                    saveRecipe()
                } label: {
                    Text("Save")
                        .font(bloomBody(14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 999).fill(theme.color("primaryStrong")))
                        .foregroundStyle(.white)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ShareLink(item: previewText) {
                Label("Copy for texting", systemImage: "square.and.arrow.up")
                    .font(bloomBody(13, weight: .medium))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
    }

    private var previewText: String {
        var lines: [String] = []
        if !w.name.isEmpty { lines.append(w.name) }
        let meta = [w.serves, w.time].filter { !$0.isEmpty }.joined(separator: " • ")
        if !meta.isEmpty { lines.append(meta) }
        let ing = w.ingredients.filter { !$0.isEmpty }
        if !ing.isEmpty {
            lines.append("")
            lines.append("Ingredients:")
            lines.append(contentsOf: ing.map { "- \($0)" })
        }
        let st = w.steps.filter { !$0.isEmpty }
        if !st.isEmpty {
            lines.append("")
            lines.append("Steps:")
            for (i, s) in st.enumerated() { lines.append("\(i + 1). \(s)") }
        }
        if !w.notes.isEmpty {
            lines.append("")
            lines.append(w.notes)
        }
        return lines.joined(separator: "\n")
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Text preview")
                    .font(bloomBody(11, weight: .semibold))
                    .foregroundStyle(theme.color("muted"))
                Spacer()
                Text("\(previewText.count) chars")
                    .font(bloomBody(11))
                    .foregroundStyle(previewText.count > 1600 ? theme.color("deep") : theme.color("muted"))
            }
            Text(previewText.isEmpty ? "Your recipe preview appears here." : previewText)
                .font(bloomBody(13))
                .foregroundStyle(theme.color("text"))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(theme.color("surfaceSoft")))
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(bloomBody(13, weight: .semibold))
            .foregroundStyle(theme.color("deep"))
    }

    private func editableRow(text: Binding<String>, placeholder: String, deleteLabel: String, onDelete: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: text, prompt: Text(placeholder).foregroundStyle(theme.color("muted")))
                .font(bloomBody(14))
                .foregroundStyle(theme.color("text"))
            // Was 22×22 and 8pt from the field it destroys: a thumb reaching for
            // the text could throw the line away. Full 44pt target, its own gap,
            // and a press she can see before she lets go.
            Button(action: onDelete) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.color("muted"))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(TactilePressStyle(cornerRadius: 22))
            .accessibilityLabel(deleteLabel)
        }
        .padding(.leading, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(theme.color("surface")))
    }

    private func addRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(bloomBody(13, weight: .medium))
                .foregroundStyle(theme.color("accentInk"))
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(TactilePressStyle(cornerRadius: 10))
    }

    private func bind(_ keyPath: WritableKeyPath<RecipeWriteDraft, String>) -> Binding<String> {
        Binding(
            get: { drafts.recipeWrite[keyPath: keyPath] },
            set: { drafts.recipeWrite[keyPath: keyPath] = $0 }
        )
    }

    private func bindRow(_ keyPath: WritableKeyPath<RecipeWriteDraft, [String]>, idx: Int) -> Binding<String> {
        Binding(
            get: {
                let list = drafts.recipeWrite[keyPath: keyPath]
                return idx < list.count ? list[idx] : ""
            },
            set: { newValue in
                guard idx < drafts.recipeWrite[keyPath: keyPath].count else { return }
                drafts.recipeWrite[keyPath: keyPath][idx] = newValue
            }
        )
    }

    private func removeRow(_ keyPath: WritableKeyPath<RecipeWriteDraft, [String]>, at idx: Int) {
        guard drafts.recipeWrite[keyPath: keyPath].indices.contains(idx) else { return }
        drafts.recipeWrite[keyPath: keyPath].remove(at: idx)
        // One empty row always stays, so the section never collapses to nothing
        // she can tap.
        if drafts.recipeWrite[keyPath: keyPath].isEmpty {
            drafts.recipeWrite[keyPath: keyPath].append("")
        }
    }

    private func addToList() {
        let names = w.ingredients.filter { !$0.isEmpty }
        for ing in names {
            if let parsed = RecipeParse.parseLine(ing) {
                lists.addIngredient(name: parsed.name)
            } else {
                lists.addIngredient(name: ing)
            }
        }
        sound.play("success")
    }

    private func saveRecipe() {
        let recipe = SavedRecipe(
            name: w.name.isEmpty ? "Untitled" : w.name,
            serves: w.serves,
            time: w.time,
            ingredients: w.ingredients.filter { !$0.isEmpty },
            steps: w.steps.filter { !$0.isEmpty },
            notes: w.notes
        )
        kitchen.saveRecipe(recipe)
        sound.play("success")
    }
}
