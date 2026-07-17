import SwiftUI
import BloomCore

// The app's one and only network call.
//
// Everything else in here works on a plane. This asks for exactly one public
// page, over https only (ATS is happy, no plist exception), reads the recipe out
// of it, and forgets the page. Nothing is uploaded, nothing is tracked, and
// nothing reaches her recipe book until she taps save.

enum RecipeLinkError: Error {
    case badLink, offline, blocked, slow, noRecipe, tooBig
}

// Not @MainActor: the fetch awaits the network and then parses up to 3 MB of
// HTML (regex + JSON + entity decoding). On the main actor that froze the
// spinner she's watching; off it, the UI stays live and only the final
// draft-write hops back to main (in readRecipe's Task { @MainActor }).
final class RecipeLinkFetcher {
    /// Many recipe sites 403 a bare Swift user-agent. This is what her phone's
    /// browser would say if she opened the same page herself.
    private static let userAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 "
        + "(KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    /// Recipe pages are heavy but not this heavy — past 3 MB it isn't a page we
    /// can read, and it isn't worth her memory to find out.
    private static let maxBytes = 3 * 1024 * 1024

    /// A private, ephemeral session: no cookie jar, no disk cache, gone when the
    /// process ends. For an app that has never made a request, that's the honest
    /// posture — a recipe blog gets no durable foothold on her phone. The
    /// resource timeout is a TOTAL wall-clock cap (the per-request timeout only
    /// bounds the gap between packets, so a slow-drip server could otherwise hold
    /// the spinner open forever).
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.httpCookieAcceptPolicy = .never
        config.httpShouldSetCookies = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    static func fetch(_ raw: String) async throws -> RecipeParse.WebRecipe {
        var cleaned = RecipeParse.cleanUrl(raw)
        // cleanUrl already gives a bare "example.com" an https:// — this covers
        // the link she copied out of an old email that still says http.
        if cleaned.lowercased().hasPrefix("http://") {
            cleaned = "https://" + cleaned.dropFirst(7)
        }
        guard let url = URL(string: cleaned),
              url.scheme?.lowercased() == "https",
              let host = url.host, host.contains(".") else {
            throw RecipeLinkError.badLink
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            // Blame the right thing, so her fix matches her problem.
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost,
                 .dataNotAllowed, .internationalRoamingOff:
                throw RecipeLinkError.offline
            case .timedOut:
                throw RecipeLinkError.slow
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .unsupportedURL:
                throw RecipeLinkError.badLink
            default:
                throw RecipeLinkError.blocked   // incl. TLS failures: the site really did refuse us
            }
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw RecipeLinkError.blocked
        }
        // Two checks, because the body is already in memory by the time we get
        // here: the declared length catches a well-behaved giant, the real count
        // catches a liar. Ceiling accepted — a page that lies about its size AND
        // is enormous costs us one download before we drop it.
        if response.expectedContentLength > Int64(maxBytes) {
            throw RecipeLinkError.tooBig
        }
        guard data.count <= maxBytes else {
            throw RecipeLinkError.tooBig
        }
        // Latin-1 never fails, so it's the honest last resort for the older sites
        // that still serve windows-1252 and call it UTF-8.
        guard let html = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1) else {
            throw RecipeLinkError.noRecipe
        }
        guard let recipe = RecipeParse.webRecipe(html: html) else {
            throw RecipeLinkError.noRecipe
        }
        return recipe
    }
}

struct RecipeLinkPanel: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var kitchen
    @Environment(SoundStore.self) private var sound
    @Environment(DraftStore.self) private var drafts

    // Ephemeral by design: a half-finished fetch should not survive a tab switch,
    // and neither should the error from one. Everything she can edit is a draft.
    @State private var loading = false
    @State private var failure: RecipeLinkError?
    @State private var confirmReplace = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            pasteRow
            if loading {
                loadingRow
            }
            if let failure {
                failureRow(failure)
            }
            if drafts.recipeLink.didFetch && !loading {
                leadSheet
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
        .alert("Replace what you've written?", isPresented: $confirmReplace) {
            Button("Replace", role: .destructive) { readRecipe() }
            Button("Keep it", role: .cancel) { confirmReplace = false }
        } message: {
            Text("Reading the link again will overwrite the recipe on screen.")
        }
    }

    // MARK: - Paste row

    private var pasteRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField(
                "Paste a recipe link",
                text: bind(\.url),
                prompt: Text("Paste a recipe link").foregroundStyle(theme.color("muted"))
            )
            .font(bloomBody(14))
            .foregroundStyle(theme.color("text"))
            .keyboardType(.URL)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .inputAccessories(bind(\.url))
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surfaceSoft")))

            Button {
                readRecipe()
            } label: {
                Text("Read this recipe")
                    .font(bloomBody(15, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 999).fill(theme.color("primaryStrong")))
                    .foregroundStyle(.white)
                    .contentShape(Rectangle())
            }
            .buttonStyle(TactilePressStyle(cornerRadius: 999))
            .discoverable("recipe.fetch", cornerRadius: 999)
            .disabled(loading || urlIsBlank)
            .opacity(loading || urlIsBlank ? 0.5 : 1)
        }
    }

    private var urlIsBlank: Bool {
        drafts.recipeLink.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(theme.color("accentInk"))
            Text("Reading the recipe\u{2026}")
                .font(bloomBody(13))
                .foregroundStyle(theme.color("muted"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(theme.color("surfaceSoft")))
    }

    // MARK: - Failure

    private func failureRow(_ error: RecipeLinkError) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(message(for: error))
                .font(bloomBody(13))
                .foregroundStyle(theme.color("text"))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                drafts.picks.recipeMode = "write"
            } label: {
                Text("Write it out instead")
                    .font(bloomBody(13, weight: .semibold))
                    .foregroundStyle(theme.color("accentInk"))
                    .padding(.horizontal, 14)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(Capsule().fill(theme.color("surface")))
                    .contentShape(Rectangle())
            }
            .buttonStyle(TactilePressStyle(cornerRadius: 999))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(theme.color("surfaceSoft")))
    }

    /// She never needs to hear the word "HTTP". Each of these says what happened
    /// and what she can do next, in that order.
    private func message(for error: RecipeLinkError) -> String {
        switch error {
        case .offline:
            return "You're offline — this one needs the internet."
        case .slow:
            return "That page is taking too long — try again in a moment."
        case .blocked, .tooBig:
            return "That site wouldn't let us read it. You can still paste the recipe text in Write."
        case .noRecipe:
            return "I couldn't find a recipe on that page — try the direct recipe link, or paste the text in Write."
        case .badLink:
            return "That doesn't look like a web link."
        }
    }

    // MARK: - Lead sheet

    private var leadSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField(
                "Recipe name",
                text: bind(\.name),
                prompt: Text("Recipe name").foregroundStyle(theme.color("muted"))
            )
            .font(bloomScript(30))
            .foregroundStyle(theme.color("text"))

            metaRow
            Divider().background(theme.color("line"))

            eyebrow("Ingredients")
            ingredientRows

            eyebrow("Steps")
            stepRows

            TextField(
                "Notes (storage, swaps, a little love note...)",
                text: bind(\.notes),
                prompt: Text("Notes (storage, swaps, a little love note...)").foregroundStyle(theme.color("muted")),
                axis: .vertical
            )
            .font(bloomBody(14))
            .foregroundStyle(theme.color("text"))
            .lineLimit(2...6)
            .inputAccessories(bind(\.notes), alignment: .top)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surfaceSoft")))

            saveButton
            sourceLine
        }
    }

    private var metaRow: some View {
        HStack(spacing: 10) {
            metaField("Serves", bind(\.serves), "4")
            metaField("Time", bind(\.time), "45 min")
        }
    }

    private func metaField(_ label: String, _ text: Binding<String>, _ placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(bloomBody(9, weight: .bold))
                .tracking(1)
                .foregroundStyle(theme.color("muted"))
            TextField(placeholder, text: text, prompt: Text(placeholder).foregroundStyle(theme.color("muted")))
                .font(bloomBody(14))
                .foregroundStyle(theme.color("text"))
                .frame(minHeight: 30)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surfaceSoft")))
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text.uppercased())
            .font(bloomBody(9, weight: .bold))
            .tracking(1)
            .foregroundStyle(theme.color("muted"))
    }

    private var ingredientRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(drafts.recipeLink.ingredients.indices, id: \.self) { idx in
                HStack(spacing: 8) {
                    TextField(
                        "1 cup flour",
                        text: bindIngredient(idx),
                        prompt: Text("1 cup flour").foregroundStyle(theme.color("muted"))
                    )
                    .font(bloomBody(14))
                    .foregroundStyle(theme.color("text"))
                    deleteButton("Remove ingredient") { removeIngredient(idx) }
                }
                .padding(.leading, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surfaceSoft")))
            }
            addRow("+ Add an ingredient") { drafts.recipeLink.ingredients.append("") }
        }
    }

    private var stepRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(drafts.recipeLink.steps.indices, id: \.self) { idx in
                HStack(alignment: .top, spacing: 8) {
                    stepNumber(idx + 1)
                    TextField(
                        "what to do",
                        text: bindStep(idx),
                        prompt: Text("what to do").foregroundStyle(theme.color("muted")),
                        axis: .vertical
                    )
                    .font(bloomBody(14))
                    .foregroundStyle(theme.color("text"))
                    .lineLimit(1...8)
                    .padding(.top, 4)
                    deleteButton("Remove step") { removeStep(idx) }
                }
            }
            addRow("+ Add a step") { drafts.recipeLink.steps.append("") }
        }
    }

    private func stepNumber(_ n: Int) -> some View {
        Text("\(n)")
            .font(bloomNumber(13))
            .foregroundStyle(theme.color("accentInk"))
            .frame(width: 26, height: 26)
            .background(Circle().fill(theme.color("surfaceSoft")))
    }

    /// 44pt and set apart from the field it deletes — this one throws away a line
    /// she typed, so a thumb aiming at the text must never land on it by accident.
    private func deleteButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "minus.circle")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.color("muted"))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(TactilePressStyle(cornerRadius: 22))
        .accessibilityLabel(label)
    }

    private func addRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(bloomBody(13, weight: .medium))
                .foregroundStyle(theme.color("accentInk"))
                .padding(.horizontal, 12)
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(TactilePressStyle(cornerRadius: 10))
    }

    private var saveButton: some View {
        Button {
            saveRecipe()
        } label: {
            Text("Save to my recipes")
                .font(bloomBody(15, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(RoundedRectangle(cornerRadius: 999).fill(theme.color("primaryStrong")))
                .foregroundStyle(.white)
                .contentShape(Rectangle())
        }
        .buttonStyle(TactilePressStyle(cornerRadius: 999))
        .discoverable("recipe.linkSave", cornerRadius: 999)
    }

    @ViewBuilder
    private var sourceLine: some View {
        let host = URL(string: drafts.recipeLink.sourceUrl)?.host ?? ""
        if !host.isEmpty {
            Text("From: \(host)")
                .font(bloomBody(11))
                .foregroundStyle(theme.color("muted"))
        }
    }

    // MARK: - Bindings

    private func bind(_ keyPath: WritableKeyPath<RecipeLinkDraft, String>) -> Binding<String> {
        Binding(
            get: { drafts.recipeLink[keyPath: keyPath] },
            set: { drafts.recipeLink[keyPath: keyPath] = $0 }
        )
    }

    private func bindIngredient(_ idx: Int) -> Binding<String> {
        Binding(
            get: { idx < drafts.recipeLink.ingredients.count ? drafts.recipeLink.ingredients[idx] : "" },
            set: { newValue in
                guard idx < drafts.recipeLink.ingredients.count else { return }
                drafts.recipeLink.ingredients[idx] = newValue
            }
        )
    }

    private func bindStep(_ idx: Int) -> Binding<String> {
        Binding(
            get: { idx < drafts.recipeLink.steps.count ? drafts.recipeLink.steps[idx] : "" },
            set: { newValue in
                guard idx < drafts.recipeLink.steps.count else { return }
                drafts.recipeLink.steps[idx] = newValue
            }
        )
    }

    private func removeIngredient(_ idx: Int) {
        guard drafts.recipeLink.ingredients.indices.contains(idx) else { return }
        drafts.recipeLink.ingredients.remove(at: idx)
    }

    private func removeStep(_ idx: Int) {
        guard drafts.recipeLink.steps.indices.contains(idx) else { return }
        drafts.recipeLink.steps.remove(at: idx)
    }

    // MARK: - Actions

    private func readRecipe() {
        let raw = drafts.recipeLink.url
        guard !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        // A second read would overwrite a recipe she's already edited — the fetch
        // button sits right above the sheet it would replace. Ask first; a first
        // read (nothing fetched yet) stays one tap.
        guard !drafts.recipeLink.didFetch || confirmReplace else {
            confirmReplace = true
            return
        }
        confirmReplace = false
        failure = nil
        loading = true
        Task { @MainActor in
            do {
                let recipe = try await RecipeLinkFetcher.fetch(raw)
                apply(recipe)
            } catch let error as RecipeLinkError {
                failure = error
            } catch {
                failure = .blocked
            }
            loading = false
        }
    }

    private func apply(_ recipe: RecipeParse.WebRecipe) {
        var draft = drafts.recipeLink
        draft.name = recipe.name
        draft.serves = recipe.serves
        draft.time = recipe.time
        draft.ingredients = recipe.ingredients
        draft.steps = recipe.steps
        draft.sourceUrl = RecipeParse.cleanUrl(draft.url)
        draft.didFetch = true
        // One assignment, so the store persists this once instead of six times.
        drafts.recipeLink = draft
        sound.play("success")
        theme.triggerCurtain()
    }

    private func saveRecipe() {
        let d = drafts.recipeLink
        let sourceNote = d.sourceUrl.isEmpty ? "" : "From: \(d.sourceUrl)"
        let notes = [d.notes, sourceNote].filter { !$0.isEmpty }.joined(separator: "\n\n")
        let recipe = SavedRecipe(
            name: d.name.isEmpty ? "Untitled" : d.name,
            serves: d.serves,
            time: d.time,
            ingredients: d.ingredients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            steps: d.steps.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            notes: notes
        )
        kitchen.saveRecipe(recipe)
        sound.play("success")
        ToastCenter.shared.show(
            title: "Saved",
            message: "\(recipe.name) is in your recipes."
        )
    }
}
