import SwiftUI
import BloomCore

// Her work-in-progress, kept safe.
//
// Every tab is a `switch selectedTab` branch, so SwiftUI tears the old tab's
// views down the instant she taps another one — any @State inside a panel
// (the numbers she just typed) went with it. These drafts live OUTSIDE the view
// tree, so switching tabs, rotating the phone, or closing the app no longer
// costs her a single digit.
//
// Shape: one small Codable struct per panel, holding ONLY what she typed or
// picked — never a computed answer. Each carries `didCalculate`, so a panel can
// re-run its own math on appear and the result card comes back exactly as she
// left it, without persisting a single derived number.
//
// She clears a field the way she always has: the ⌫ in the field itself
// (`.inputAccessories`), or "Clear this page" in the tab.

// MARK: - Tools

struct TipSplitDraft: Codable, Equatable {
    var bill = "80"
    var tipPct = "20"
    var people = "4"
    var didCalculate = false
}

struct PercentageDraft: Codable, Equatable {
    var mode = "of"
    var a = "15"
    var b = "80"
    var didCalculate = false
}

struct LoanDraft: Codable, Equatable {
    var amount = "20000"
    var rate = "6"
    var years = "5"
    var didCalculate = false
}

struct SavingsGoalDraft: Codable, Equatable {
    var target = "15000"
    var years = "5"
    var rate = "4"
    var start = "0"
    var didCalculate = false
}

// MARK: - Projection

struct GrowDraft: Codable, Equatable {
    var principal = "10000"
    var monthly = "500"
    var years: Double = 20
    var fundID: UUID?
    var didCalculate = false
}

struct RetireDraft: Codable, Equatable {
    var age = "30"
    var retireAge = "65"
    var monthly = "600"
    var employer = "200"
    var rate = "7"
    var inflation = "2.5"
    var start = "25000"
    var didCalculate = false
}

struct MatchDraft: Codable, Equatable {
    var salary = "80000"
    var yourPct = "4"
    var matchRate = "50"
    var matchCap = "6"
    var didCalculate = false
}

struct RealRateDraft: Codable, Equatable {
    var nominal = "7"
    var inflation = "2.5"
    var didCalculate = false
}

struct CompareDraft: Codable, Equatable {
    var monthly = "500"
    var years = "20"
    var start = "10000"
    var didCalculate = false
}

struct Rule72Draft: Codable, Equatable {
    var rate = "8"
    var didCalculate = false
}

// MARK: - Kitchen

struct RecipeWriteDraft: Codable, Equatable {
    var name = ""
    var serves = ""
    var time = ""
    var ingredients: [String] = [""]
    var steps: [String] = [""]
    var notes = ""

    var isEmpty: Bool {
        name.isEmpty && serves.isEmpty && time.isEmpty && notes.isEmpty
            && ingredients.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty }
            && steps.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}

/// The "read me a link" flow: the address she pasted, plus the fetched recipe
/// in an editable form. Nothing here is written to her recipe book until she
/// taps save, so a bad fetch never touches what she's already kept.
struct RecipeLinkDraft: Codable, Equatable {
    var url = ""
    var name = ""
    var serves = ""
    var time = ""
    var ingredients: [String] = []
    var steps: [String] = []
    var notes = ""
    var sourceUrl = ""
    var didFetch = false
}

struct RecipeShareDraft: Codable, Equatable {
    var rawUrl = ""
    var alias = ""
}

struct VisualizeDraft: Codable, Equatable {
    var rawText = ""
    var scale: Double = 1.0
    var customScale = ""
    var useCustom = false
    var didParse = false
}

// MARK: - Lists

struct ListsDraft: Codable, Equatable {
    var newItemName = ""
    var newItemQty = "1"
    var newItemPrice = ""
    var newListTitle = ""
    /// "list" or "notes" — the Lists tab's mode.
    var mode = "list"
}

/// The note she's writing right now — kept in the draft so a tab switch or a
/// phone lock never costs her a word. `rtf` is the rich text (RTF Data); `body`
/// is the plain-text mirror kept in sync for the "make a list" parse, search,
/// and share. `id` ties the live page to a saved/archived note when she reopens
/// one, so re-saving updates instead of duplicating.
struct NotesDraft: Codable, Equatable {
    var id: UUID? = nil
    var title = ""
    var body = ""
    var rtf: Data? = nil
}

// MARK: - Projection (new panels)

struct BabyDraft: Codable, Equatable {
    var years = "18"            // birth to horizon
    var lumpSum = "1000"        // prefilled with the Trump seed
    var monthly = "50"
    var assetClass = "stocks"   // stocks | balanced | bonds | realEstate
    var rate = "7"              // seeded from the asset class, editable
    var didCalculate = false
}

struct TrumpDraft: Codable, Equatable {
    var birthYear = "2025"
    var currentAge = "0"
    var startBalance = "1000"   // seed if eligible
    var annualContribution = "2000"
    var employerContribution = "0"
    var returnPct = "7"
    var expenseRatio = "0.07"
    var targetAge = "18"
    var didCalculate = false
}

struct WholeLifeDraft: Codable, Equatable {
    var annualPremium = "5000"
    var yearsPaying = "20"
    var projectionYears = "30"
    var assumedRate = "5.75"        // NM 2026 dividend interest rate (reference)
    var initialDeathBenefit = "250000"
    var efficiency = "85"           // advanced: share of premium reaching cash value
    var didCalculate = false
}

// MARK: - Tools (new card)

/// Real-estate historical-growth card. No didCalculate — the chart is LIVE, it
/// redraws as she types, so there's nothing to "run".
struct RealEstateDraft: Codable, Equatable {
    var currentValue = "300000"
    var rate = "4.5"            // seeded from the "typical" preset
    var years = "20"
    var netYield = "0"          // optional rental income minus carrying costs
    var kind = "home"           // home | land — just changes the seeded rate + copy
}

// MARK: - Sub-mode picks (these are choices too — losing them is the same bug)

struct PanelPicks: Codable, Equatable {
    /// ProjectionView's panel: "Grow", "Baby", "Trump", "Whole life", "Retire",
    /// "Match", "Real rate", "Compare", "Rule of 72", "Beat market".
    var projection = "Grow"
    /// RecipePanel's mode: "write", "link", "share".
    var recipeMode = "write"
}

// MARK: - Store

@Observable
final class DraftStore {
    var tipSplit = TipSplitDraft() { didSet { schedulePersist() } }
    var percentage = PercentageDraft() { didSet { schedulePersist() } }
    var loan = LoanDraft() { didSet { schedulePersist() } }
    var savings = SavingsGoalDraft() { didSet { schedulePersist() } }

    var grow = GrowDraft() { didSet { schedulePersist() } }
    var baby = BabyDraft() { didSet { schedulePersist() } }
    var trump = TrumpDraft() { didSet { schedulePersist() } }
    var wholeLife = WholeLifeDraft() { didSet { schedulePersist() } }
    var retire = RetireDraft() { didSet { schedulePersist() } }
    var match = MatchDraft() { didSet { schedulePersist() } }
    var realRate = RealRateDraft() { didSet { schedulePersist() } }
    var compare = CompareDraft() { didSet { schedulePersist() } }
    var rule72 = Rule72Draft() { didSet { schedulePersist() } }
    var realEstate = RealEstateDraft() { didSet { schedulePersist() } }

    var recipeWrite = RecipeWriteDraft() { didSet { schedulePersist() } }
    var recipeLink = RecipeLinkDraft() { didSet { schedulePersist() } }
    var recipeShare = RecipeShareDraft() { didSet { schedulePersist() } }
    var visualize = VisualizeDraft() { didSet { schedulePersist() } }

    var lists = ListsDraft() { didSet { schedulePersist() } }
    var notes = NotesDraft() { didSet { schedulePersist() } }

    var picks = PanelPicks() { didSet { schedulePersist() } }

    /// False until init has finished hydrating, so loading the saved blob can't
    /// trigger a save of a half-applied state.
    private var hydrated = false
    private var saveTask: Task<Void, Never>?

    init() {
        if let blob = JSONStore.shared.get(.drafts, as: Blob.self) {
            apply(blob)
        }
        hydrated = true
    }

    /// Fresh page for one tab — the explicit "I'm done with this" gesture, so
    /// nothing is ever silently wiped for her.
    func clearTools() {
        tipSplit = TipSplitDraft()
        percentage = PercentageDraft()
        loan = LoanDraft()
        savings = SavingsGoalDraft()
        realEstate = RealEstateDraft()
    }

    func clearProjection() {
        grow = GrowDraft()
        baby = BabyDraft()
        trump = TrumpDraft()
        wholeLife = WholeLifeDraft()
        retire = RetireDraft()
        match = MatchDraft()
        realRate = RealRateDraft()
        compare = CompareDraft()
        rule72 = Rule72Draft()
    }

    // MARK: persistence

    /// Every field is optional so a draft added in a later version can never
    /// make an older saved blob undecodable — a missing key just takes its
    /// default (the same guard the songbook uses).
    private struct Blob: Codable {
        var tipSplit: TipSplitDraft?
        var percentage: PercentageDraft?
        var loan: LoanDraft?
        var savings: SavingsGoalDraft?
        var grow: GrowDraft?
        var baby: BabyDraft?
        var trump: TrumpDraft?
        var wholeLife: WholeLifeDraft?
        var retire: RetireDraft?
        var match: MatchDraft?
        var realRate: RealRateDraft?
        var compare: CompareDraft?
        var rule72: Rule72Draft?
        var realEstate: RealEstateDraft?
        var recipeWrite: RecipeWriteDraft?
        var recipeLink: RecipeLinkDraft?
        var recipeShare: RecipeShareDraft?
        var visualize: VisualizeDraft?
        var lists: ListsDraft?
        var notes: NotesDraft?
        var picks: PanelPicks?
    }

    private func apply(_ b: Blob) {
        tipSplit = b.tipSplit ?? TipSplitDraft()
        percentage = b.percentage ?? PercentageDraft()
        loan = b.loan ?? LoanDraft()
        savings = b.savings ?? SavingsGoalDraft()
        grow = b.grow ?? GrowDraft()
        baby = b.baby ?? BabyDraft()
        trump = b.trump ?? TrumpDraft()
        wholeLife = b.wholeLife ?? WholeLifeDraft()
        retire = b.retire ?? RetireDraft()
        match = b.match ?? MatchDraft()
        realRate = b.realRate ?? RealRateDraft()
        compare = b.compare ?? CompareDraft()
        rule72 = b.rule72 ?? Rule72Draft()
        realEstate = b.realEstate ?? RealEstateDraft()
        recipeWrite = b.recipeWrite ?? RecipeWriteDraft()
        recipeLink = b.recipeLink ?? RecipeLinkDraft()
        recipeShare = b.recipeShare ?? RecipeShareDraft()
        visualize = b.visualize ?? VisualizeDraft()
        lists = b.lists ?? ListsDraft()
        notes = b.notes ?? NotesDraft()
        picks = b.picks ?? PanelPicks()
    }

    private func makeBlob() -> Blob {
        Blob(tipSplit: tipSplit, percentage: percentage, loan: loan, savings: savings,
             grow: grow, baby: baby, trump: trump, wholeLife: wholeLife,
             retire: retire, match: match, realRate: realRate,
             compare: compare, rule72: rule72, realEstate: realEstate,
             recipeWrite: recipeWrite, recipeLink: recipeLink,
             recipeShare: recipeShare, visualize: visualize,
             lists: lists, notes: notes, picks: picks)
    }

    /// Debounced: she types fast, and rewriting the whole blob per keystroke is
    /// the exact anti-pattern the brief calls out. 0.8s after she stops.
    private func schedulePersist() {
        guard hydrated else { return }
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            JSONStore.shared.set(.drafts, makeBlob())
        }
    }

    /// Write now, no debounce — for the moment the app is leaving the screen.
    func flush() {
        saveTask?.cancel()
        JSONStore.shared.set(.drafts, makeBlob())
    }
}
