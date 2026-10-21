import SwiftUI
import BloomCore

/// The "My Recipes" door that sits above the Write / From a link / Share picker.
/// Saved recipes used to go into the store and never come back out — there was
/// no screen that listed them. This is that screen.
struct MyRecipesButton: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var kitchen
    @State private var showBook = false

    var body: some View {
        Button {
            showBook = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "book.closed")
                    .font(.system(size: 16, weight: .semibold))
                Text("My Recipes")
                    .font(bloomBody(15, weight: .semibold))
                Spacer()
                Text("\(kitchen.savedRecipes.count)")
                    .font(bloomNumber(14, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(theme.color("surfaceSoft")))
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.color("muted"))
            }
            .foregroundStyle(theme.color("deep"))
            .padding(.horizontal, 16)
            .frame(minHeight: 50)
            .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
            .contentShape(Rectangle())
        }
        .buttonStyle(TactilePressStyle(cornerRadius: theme.radius))
        .accessibilityLabel("My Recipes, \(kitchen.savedRecipes.count) saved")
        .discoverable("recipe.book", cornerRadius: theme.radius)
        .sheet(isPresented: $showBook) {
            SavedRecipesSheet()
        }
    }
}

struct SavedRecipesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var kitchen
    @State private var query = ""

    /// Newest first: a recipe she just saved or edited is the one she's after.
    private var shown: [SavedRecipe] {
        let all = kitchen.savedRecipes.sorted { $0.savedAt > $1.savedAt }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return all }
        return all.filter { r in
            r.name.localizedCaseInsensitiveContains(q)
                || r.ingredients.contains { $0.localizedCaseInsensitiveContains(q) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    if kitchen.savedRecipes.isEmpty {
                        emptyState
                    } else if shown.isEmpty {
                        Text("No recipe matches \u{201C}\(query)\u{201D}.")
                            .font(bloomBody(14))
                            .foregroundStyle(theme.color("muted"))
                            .padding(.top, 40)
                    } else {
                        ForEach(shown) { recipe in
                            NavigationLink(value: recipe.id) {
                                row(recipe)
                            }
                            .buttonStyle(TactilePressStyle(cornerRadius: 16))
                        }
                    }
                }
                .padding(16)
            }
            .background(theme.color("bg"))
            .navigationTitle("My Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { id in
                SavedRecipeDetail(recipeId: id, closeBook: { dismiss() })
            }
            .modifier(SearchWhenLong(isLong: kitchen.savedRecipes.count > 5, query: $query))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func row(_ recipe: SavedRecipe) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(bloomNumber(17, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(SavedRecipeFormat.meta(recipe))
                    .font(bloomBody(13))
                    .foregroundStyle(theme.color("muted"))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.color("muted"))
        }
        .padding(14)
        .frame(minHeight: 64)
        .background(RoundedRectangle(cornerRadius: 16).fill(theme.color("surface")))
        .contentShape(Rectangle())
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.closed")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(theme.color("primaryStrong"))
            Text("No saved recipes yet")
                .font(bloomNumber(18, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
            Text("Write one, or read one from a link, then tap Save. It will live here.")
                .font(bloomBody(14))
                .foregroundStyle(theme.color("muted"))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.horizontal, 24)
    }
}

/// Search only earns its space once the book is long enough to need it.
private struct SearchWhenLong: ViewModifier {
    let isLong: Bool
    @Binding var query: String

    func body(content: Content) -> some View {
        if isLong {
            content.searchable(text: $query, prompt: "Search recipes or ingredients")
        } else {
            content
        }
    }
}

enum SavedRecipeFormat {
    static func meta(_ r: SavedRecipe) -> String {
        var bits: [String] = []
        let serves = r.serves.trimmingCharacters(in: .whitespaces)
        if !serves.isEmpty {
            bits.append(serves.lowercased().hasPrefix("serve") ? serves : "Serves \(serves)")
        }
        let time = r.time.trimmingCharacters(in: .whitespaces)
        if !time.isEmpty { bits.append(time) }
        bits.append("\(r.ingredients.count) ingredient\(r.ingredients.count == 1 ? "" : "s")")
        bits.append(r.savedAt.formatted(.dateTime.month(.abbreviated).day()))
        return bits.joined(separator: " \u{00B7} ")
    }
}

struct SavedRecipeDetail: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var kitchen
    @Environment(ListsStore.self) private var lists
    @Environment(DraftStore.self) private var drafts
    @Environment(SoundStore.self) private var sound

    let recipeId: UUID
    let closeBook: () -> Void

    @State private var confirmDelete = false
    @State private var confirmReplace = false

    private var recipe: SavedRecipe? { kitchen.savedRecipes.first { $0.id == recipeId } }

    var body: some View {
        Group {
            if let recipe {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header(recipe)
                        actions(recipe)
                        if !recipe.ingredients.isEmpty {
                            section("Ingredients") {
                                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, line in
                                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                                        Text("\u{2022}")
                                            .font(bloomBody(15, weight: .bold))
                                            .foregroundStyle(theme.color("primaryStrong"))
                                        Text(line)
                                            .font(bloomBody(15))
                                            .foregroundStyle(theme.color("text"))
                                    }
                                }
                            }
                        }
                        if !recipe.steps.isEmpty {
                            section("Steps") {
                                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, step in
                                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                                        Text("\(i + 1)")
                                            .font(bloomNumber(15, weight: .semibold))
                                            .foregroundStyle(theme.color("primaryStrong"))
                                            .frame(minWidth: 20, alignment: .trailing)
                                        Text(step)
                                            .font(bloomBody(15))
                                            .foregroundStyle(theme.color("text"))
                                    }
                                }
                            }
                        }
                        if !recipe.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            section("Notes") {
                                Text(recipe.notes)
                                    .font(bloomBody(15))
                                    .foregroundStyle(theme.color("text"))
                            }
                        }
                        if let link = recipe.sourceUrl.flatMap(URL.init(string:)) {
                            Link(destination: link) {
                                Label("Open the original page", systemImage: "safari")
                                    .font(bloomBody(14, weight: .medium))
                                    .foregroundStyle(theme.color("accentInk"))
                                    .frame(minHeight: 44)
                            }
                        }
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Label("Delete recipe", systemImage: "trash")
                                .font(bloomBody(14, weight: .medium))
                                .frame(minHeight: 44)
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            } else {
                // Deleted out from under the open page.
                Color.clear.onAppear { dismiss() }
            }
        }
        .background(theme.color("bg"))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete \(recipe?.name ?? "this recipe")?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                kitchen.deleteRecipe(recipeId)
                if drafts.recipeWrite.savedId == recipeId { drafts.recipeWrite.savedId = nil }
                dismiss()
            }
        } message: {
            Text("This can't be undone.")
        }
        .alert("Replace the recipe you're writing?", isPresented: $confirmReplace) {
            Button("Replace", role: .destructive) { if let recipe { edit(recipe) } }
            Button("Keep writing", role: .cancel) {}
        } message: {
            Text("The Write page has a recipe you haven't saved. Opening this one there will replace it.")
        }
    }

    private func header(_ recipe: SavedRecipe) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(recipe.name)
                .font(bloomNumber(26, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
            Text(SavedRecipeFormat.meta(recipe))
                .font(bloomBody(14))
                .foregroundStyle(theme.color("muted"))
        }
    }

    private func actions(_ recipe: SavedRecipe) -> some View {
        HStack(spacing: 10) {
            actionButton("Edit", symbol: "pencil") {
                let w = drafts.recipeWrite
                // Unsaved work on the Write page that ISN'T this recipe would be lost.
                if !w.isEmpty && w.savedId != recipe.id {
                    confirmReplace = true
                } else {
                    edit(recipe)
                }
            }
            ShareLink(item: RecipeShare.text(name: recipe.name, serves: recipe.serves, time: recipe.time,
                                             ingredients: recipe.ingredients, steps: recipe.steps,
                                             notes: recipe.notes, sourceUrl: recipe.sourceUrl ?? "")) {
                actionLabel("Share", symbol: "square.and.arrow.up")
            }
            .buttonStyle(TactilePressStyle(cornerRadius: 14))
            actionButton("To list", symbol: "cart") {
                addToList(recipe)
            }
        }
    }

    private func actionButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionLabel(title, symbol: symbol)
        }
        .buttonStyle(TactilePressStyle(cornerRadius: 14))
    }

    private func actionLabel(_ title: String, symbol: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
            Text(title)
                .font(bloomBody(12, weight: .semibold))
        }
        .foregroundStyle(theme.color("primaryStrong"))
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(RoundedRectangle(cornerRadius: 14).fill(theme.color("surface")))
        .contentShape(Rectangle())
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(bloomBody(13, weight: .semibold))
                .textCase(.uppercase)
                .foregroundStyle(theme.color("muted"))
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(theme.color("surface")))
        }
    }

    /// Opens the saved recipe on the Write page, tied to its id, so Save there
    /// updates this recipe instead of making a second copy.
    private func edit(_ recipe: SavedRecipe) {
        drafts.recipeWrite = RecipeWriteDraft(
            name: recipe.name,
            serves: recipe.serves,
            time: recipe.time,
            ingredients: recipe.ingredients.isEmpty ? [""] : recipe.ingredients,
            steps: recipe.steps.isEmpty ? [""] : recipe.steps,
            notes: recipe.notes,
            savedId: recipe.id,
            sourceUrl: recipe.sourceUrl
        )
        drafts.picks.recipeMode = "write"
        kitchen.activeTab = .recipe
        sound.play("modeswitch")
        closeBook()
    }

    private func addToList(_ recipe: SavedRecipe) {
        for line in recipe.ingredients {
            lists.addIngredient(name: RecipeParse.parseLine(line)?.name ?? line)
        }
        sound.play("success")
        ToastCenter.shared.show(title: "Added to your list",
                                message: "\(recipe.ingredients.count) ingredients from \(recipe.name).")
    }
}
