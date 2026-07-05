# Bloom Contracts v1 (frozen)

Every worker builds against this document. Deviations are bugs. Source spec: `../Bloom Calculator (all-in-one).html`.

> v2, 2026-07-03, approved deviation: the Lists/Kitchen/Pantry-era tab registry below is stale. The shipped app replaced the `pantry` tab with a `budget` tab (Monthly Budget engine) and the app display name is `Hannah's Calculator`, not `Bloom Calculator`. Both changes are called out inline below where they occur, and the frozen Budget API is appended as its own section at the end of this document.

## Global style rules

Swift 5.10+, iOS 17 minimum, zero third-party dependencies. No comments, no docstrings, no force unwraps outside tests, no em-dash characters anywhere. Files under 400 lines; split when larger. `BloomCore` imports Foundation only (must compile on Linux). UI code lives in `App/` and may import SwiftUI, AVFoundation, CoreImage, UIKit.

## File ownership registry

| Path | Owner |
|---|---|
| Packages/BloomCore/** | worker-core |
| App/BloomApp.swift, App/Theme/**, App/Components/**, App/Views/Root/**, App/Views/Calc/**, App/Views/Projection/**, App/Views/Tools/** | worker-finance-ui |
| App/Views/Lists/**, App/Views/Kitchen/**, App/Views/Pantry/**, App/Views/History/**, App/Views/Music/**, App/Views/Overlays/**, App/Effects/**, App/Audio/**, App/Views/Settings/** | worker-delight-ui |
| project.yml, .github/**, fastlane/**, scripts/**, App/Resources/** (non-Swift), App/Support/** | worker-scaffold |
| contracts/** | orchestrator only |

## BloomCore public API (signatures are frozen)

```swift
public enum CalcOp: String, Codable, Sendable { case add, subtract, multiply, divide }

public struct CalcResult: Equatable, Sendable {
    public let display: String
    public let expression: String
    public let sequence: String
}

public struct CalcEngine: Sendable {
    public private(set) var current: String
    public private(set) var overwrite: Bool
    public init()
    public mutating func digit(_ d: Character)
    public mutating func dot()
    public mutating func setOp(_ op: CalcOp)
    public mutating func equals() -> CalcResult?
    public mutating func clearAll()
    public mutating func toggleSign()
    public mutating func percent()
    public mutating func backspace()
    public var displayText: String { get }
    public var expressionText: String { get }
}

public enum FinanceMath {
    public static func futureValue(principal: Double, monthly: Double, annualRatePct: Double, years: Double) -> Double
    public static func contributions(principal: Double, monthly: Double, years: Double) -> Double
    public static func loanPayment(principal: Double, annualRatePct: Double, years: Double) -> Double
    public static func savingsGoalPayment(target: Double, principal: Double, annualRatePct: Double, years: Double) -> Double
    public static func realRate(nominalPct: Double, inflationPct: Double) -> Double
    public static func employerMatch(salary: Double, contribPct: Double, matchPct: Double, matchLimitPct: Double) -> Double
    public static func ruleOf72(ratePct: Double) -> Double
    public static func tip(bill: Double, tipPct: Double, people: Int) -> (tip: Double, total: Double, perPerson: Double)
    public static func percentOf(_ pct: Double, of value: Double) -> Double
    public static func percentChange(from a: Double, to b: Double) -> Double
}

public enum Formatters {
    public static func round8(_ n: Double) -> Double
    public static func fmt(_ n: Double) -> String
    public static func plain(_ n: Double) -> String
    public static func money(_ n: Double) -> String
    public static func usd(_ n: Double) -> String
}

public struct Egg: Codable, Equatable, Sendable {
    public let id: String
    public let kind: String
    public let title: String
    public let dateLabel: String
    public let lines: [String]
    public let more: [String]?
    public let triggers: [String]
}

public enum EasterEggs {
    public static func all() -> [Egg]
    public static func match(sequence: String) -> Egg?
}

public struct Fund: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var ratePct: Double
    public init(id: UUID, name: String, ratePct: Double)
}

public struct HistoryEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var ts: Date
    public var type: String
    public var title: String
    public var value: String
    public var extra: [String: String]
    public init(id: String, ts: Date, type: String, title: String, value: String, extra: [String: String])
}

public struct ThemeSpec: Codable, Equatable, Sendable {
    public var name: String
    public var tokens: [String: String]
    public init(name: String, tokens: [String: String])
}

public struct Food: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var group: String
    public var measure: String
    public var glyph: String
    public var artKey: String?
}

public enum FoodLibrary {
    public static func load() -> [Food]
    public static func match(_ raw: String) -> Food?
    public static func groups() -> [String]
}

public struct ParsedIngredient: Codable, Equatable, Sendable {
    public var qty: Double?
    public var unit: String?
    public var name: String
    public var raw: String
}

public enum RecipeParse {
    public static func parseLine(_ line: String) -> ParsedIngredient?
    public static func scale(_ ing: ParsedIngredient, by factor: Double) -> ParsedIngredient
    public static func fmtQty(_ q: Double) -> String
    public static func cleanUrl(_ raw: String) -> String
    public static func jsonLDIngredients(html: String) -> [String]
}

public enum UnitConvert {
    public static let volumeUnits: [String]
    public static let weightUnits: [String]
    public static func convert(_ value: Double, from: String, to: String) -> Double?
}

public enum StoreKey: String, CaseIterable, Sendable {
    case history = "bloom_history"
    case favorites = "bloom_favorites"
    case funds = "bloom_funds"
    case theme = "bloom_theme"
    case custom = "bloom_custom"
    case soundmap = "bloom_soundmap"
    case recipes = "bloom_recipes"
    case shopLists = "bloomShopLists"
    case memory = "bloom_memory"
    case songs = "bloom_songs"
}

public final class JSONStore: @unchecked Sendable {
    public static let shared: JSONStore
    public func get<T: Decodable>(_ key: StoreKey, as type: T.Type) -> T?
    public func set<T: Encodable>(_ key: StoreKey, _ value: T)
    public func remove(_ key: StoreKey)
    public init(directory: URL)
}
```

## Behavioral parity notes (worker-core must read)

CalcEngine replicates HTML lines 1834-1911: left to right accumulator, chained ops compute immediately on second operator press, operator swap when pressed twice, divide by zero yields display "Error", equals returns nil when no pending op. `sequence` is the collapsed token string using glyphs ÷ × − + exactly as `checkEgg` receives it.

Formatters replicate lines 1809-1818 and 2049. round8 is `(n*1e8).rounded()/1e8`. fmt: if abs >= 1e15 or (abs < 1e-6 and n != 0) return exponential with 4 fraction digits in JS style `d.dddde+XX`; else group with en_US separators, max 8 fraction digits, no trailing zeros. plain: decimal string of round8 without grouping; values are multiples of 1e-8 so Swift shortest round trip printing matches JS; strip a trailing `.0`. money: `$` plus en_US grouping with exactly 2 fraction digits. usd: `$` plus whole dollar rounding with grouping.

FinanceMath.futureValue replicates lines 2037-2048: i = rate/100/12, n = years*12, if i == 0 then principal + monthly*n else principal*pow(1+i,n) + monthly*(pow(1+i,n)-1)/i.

EasterEggs.match: exact string match against each egg trigger list. Eggs load from bundled `eggs.json` (extracted verbatim from HTML lines 1694-1705, including `more` arrays). Near miss sequences must return nil.

Tests read `contracts/vectors.json` and assert string equality on every `expect` field, plus relative tolerance 1e-12 on every `raw` field.

## vectors.json schema (worker-extract produces, worker-core consumes)

```json
{
  "meta": {"generatedFrom": "Bloom Calculator (all-in-one).html", "date": "2026-07-02", "runtime": "node"},
  "formatters": [{"fn": "fmt|plain|money|usd", "arg": 1234.5678, "expect": "1,234.5678"}],
  "finance": [{"fn": "futureValue", "args": {"principal": 1000, "monthly": 100, "annualRatePct": 6, "years": 10}, "raw": 123.0, "expect": "$123"}],
  "calc": [{"keys": ["3","+","1","6","+","2","5","="], "display": "44", "sequence": "3+16+25"}],
  "eggs": [{"sequence": "3÷16÷25", "match": "egg-id-or-null"}],
  "recipe": [{"line": "1 ½ cups flour", "qty": 1.5, "unit": "cup", "name": "flour"}],
  "convert": [{"value": 2, "from": "cup", "to": "mL", "expect": 473.176}]
}
```

Minimum vector counts: formatters 40, finance 30 spanning all functions including zero rate and zero years edges, calc 25 including chained ops, operator swap, percent, sign toggle, divide by zero, eggs 24 covering all 10 eggs in both glyph and slash notation plus 4 near misses, recipe 20 including unicode fractions ½ ⅓ ¼ ¾ and word numbers, convert 12.

## UI registry (both UI workers)

App target name `Bloom`, entry `BloomApp` (owner: finance-ui). Root view `RootView` with custom bottom `BloomTabBar` over cases: calc, proj, lists, kitchen, tools, ~~pantry~~ budget, music. **(v2, 2026-07-03, approved deviation: the `pantry` tab was replaced by `budget`, backed by `BudgetStore` and the `BloomCore` Budget API below; see the Budget section at the end of this document.)** Stores are `@Observable` classes injected via `.environment(...)`: `CalcStore, ProjectionStore, HistoryStore, ListsStore, KitchenStore, ThemeStore, SoundStore, MusicStore, BudgetStore` (CalcStore, ProjectionStore, ThemeStore owned by finance-ui; BudgetStore owned by finance-ui per the v2 deviation; the rest by delight-ui; every store persists through `JSONStore.shared` with its StoreKey).

View names are frozen so RootView compiles: `CalcView, ProjectionView, ToolsView, BudgetView` (finance-ui, BudgetView added under the v2 deviation); `ListsView, KitchenView, MusicView, HistoryOverlay, PoemOverlay, ToastHost, SoundStudioView, RecycleSheet, SplashOverlay, CreditsView` (delight-ui; `PantryView` removed under the v2 deviation). Delight views must exist even if a sub-feature ships as a stub with a TODO screen; compile success on CI is the gate.

Theme: `ThemeStore` exposes `spec: ThemeSpec` and `color(_ token: String) -> Color`. The 16 tokens: bg, surface, surfaceSoft, surface2, primary, primaryStrong, deep, text, muted, line, flowerCenter, good, shadow, ripple, sh1, radius (radius is a CGFloat-encoded string). Presets cherry, rose, peony, soft come from `contracts/theme-tokens.md` hex values exactly. Custom theme edits any of the 12 editable tokens via ColorPicker and persists.

Sound event IDs (19, from HTML DEFAULT_MAP): tap digits rotate tap1 to tap5, plus operator, equals, clear, error, success, modeswitch, memory, easteregg, startup. `SoundStore.play(_ event: String)` resolves the user map, respects a master toggle, uses AVAudioSession category ambient. Haptics: light impact on keypad, success notification on egg, gated by a toggle in SoundStudioView.

Reduce motion: every particle system and long animation checks `@Environment(\.accessibilityReduceMotion)`.

## Scaffold registry (worker-scaffold)

Bundle id `com.shaver.bloomcalculator`, display name ~~`Bloom`~~ `Hannah's Calculator` **(v2, 2026-07-03, approved deviation)**, marketing version 1.0, build number from CI run number, deployment target 17.0, iPhone only, portrait plus portraitUpsideDown. Info.plist via project.yml: UIAppFonts (Quicksand, PlayfairDisplay, PlayfairDisplay-Italic, GreatVibes), ITSAppUsesNonExemptEncryption false. Secrets consumed in CI: APPLE_TEAM_ID, ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8. test.yml: swift:6.0 container on ubuntu-latest running `swift test` in Packages/BloomCore on every push. release.yml: macos-15, triggered by tags `v*`, steps: checkout, brew install xcodegen, scripts/fetch_fonts.sh, xcodegen, xcodebuild archive with cloud signing (`-allowProvisioningUpdates -authenticationKeyPath ... -authenticationKeyID ... -authenticationKeyIssuerID ...`), export ipa, `bundle exec fastlane pilot_upload`. Fonts fetched from pinned google/fonts GitHub raw URLs with sha256 checks, never committed.

## Budget (frozen, v2, 2026-07-03, approved addition)

Source spec: budget IIFE `Bloom Calculator (all-in-one).html:3113-3598`. Share text/tag: `exBudget` 3713-3735, `importBudget` 3832-3845, tag `#hannahs-budget-v1`. Owner: worker-core for `Packages/BloomCore/**`, worker-finance-ui for `App/Views/Budget/**`.

```swift
public struct BudgetRow: Codable, Equatable {
    public var n: String
    public var a: Double
    public var sel: Bool
    public init(n: String, a: Double, sel: Bool)
}

public struct BudgetIncome: Codable, Equatable {
    public var label: String
    public var gross: Double
    public var tax: Double
    public var ret: Double
    public var oth: Double
    public init(label: String, gross: Double, tax: Double, ret: Double, oth: Double)
}

public struct BudgetCategory: Codable, Equatable {
    public var n: String
    public var open: Bool
    public var goal: Double?
    public var items: [BudgetRow]
    public init(n: String, open: Bool, goal: Double?, items: [BudgetRow])
}

public struct BudgetMonth: Codable, Equatable {
    public var inc2On: Bool
    public var inc: [BudgetIncome]
    public var cats: [BudgetCategory]
    public init(inc2On: Bool, inc: [BudgetIncome], cats: [BudgetCategory])
}

public struct BudgetDB: Codable, Equatable {
    public var v: Int
    public var cur: String
    public var months: [String: BudgetMonth]
    public init(v: Int, cur: String, months: [String: BudgetMonth])
}

public struct BudgetPresetItem {
    public let name: String
    public let amount: Double
    public init(name: String, amount: Double)
}

public struct BudgetPreset {
    public let n: String
    public let items: [BudgetPresetItem]
    public init(n: String, items: [BudgetPresetItem])
}

public struct BudgetYearEntry: Equatable {
    public let key: String
    public let has: Bool
    public let planned: Double
    public let takeHome: Double
    public init(key: String, has: Bool, planned: Double, takeHome: Double)
}

public enum BudgetDefaults {
    public static func month() -> BudgetMonth
    public static let presets: [BudgetPreset]
    public static let colors: [String]
    public static let monthNames: [String]
}

public enum BudgetMath {
    public static func jsRound(_ x: Double) -> Double
    public static func netOf(_ i: BudgetIncome) -> Double
    public static func takeHome(of m: BudgetMonth) -> Double
    public static func catTotal(_ c: BudgetCategory) -> Double
    public static func catSel(_ c: BudgetCategory) -> Double
    public static func planned(of m: BudgetMonth) -> Double
    public static func importRow(name: String, qty: Double?, amount: Double) -> BudgetRow
    public static func ymKey(year: Int, month: Int) -> String
    public static func parseYM(_ key: String) -> (year: Int, month: Int)?
    public static func monthDays(_ ymKey: String) -> Int
    public static func monthLabel(_ ymKey: String) -> String
    public static func perDay(sel: Double, days: Int) -> Double
    public static func byToday(sel: Double, today: Int, days: Int) -> Double
    public static func chartYMax(sels: [Double], goals: [Double?]) -> Double
    public static func monthForSwitch(db: BudgetDB, to key: String) -> (month: BudgetMonth, copiedFrom: String?)
    public static func yearAggregate(db: BudgetDB, year: Int) -> [BudgetYearEntry]
}

public enum BudgetShare {
    public static func export(db: BudgetDB) -> String
    public static func parse(_ text: String) -> BudgetDB?
}
```

`StoreKey` gains `case budget2 = "bloom_budget2"` (raw value matches the JS `BKEY2` constant exactly; the case name is `budget2` to satisfy the `BudgetStore` UI call sites, not `budget`).

Behavioral parity notes: `jsRound` is `floor(x + 0.5)` including negatives (matches `Formatters.jsRound` already in the codebase). `netOf`: `gross * (1 - min(100, tax+ret+oth)/100)`, floored at 0. `takeHome`: `netOf(inc[0])` plus `netOf(inc[1])` only when `inc2On`. `catTotal`/`catSel` sum `item.a` over all items, or only `sel` items respectively. `planned` sums `catTotal` over all categories. `importRow`: `qty` nil (or the JS `''`/`null` equivalent) defaults to 1; `a = jsRound(qty*amount*100)/100`; `name` is trimmed then truncated to 60 characters; `sel` is always `false`. `monthDays` mirrors JS `new Date(y, m, 0).getDate()` (last day of month `m`, 1-indexed). `monthLabel` is `monthNames[month-1] + " " + year` (e.g. "July 2026"). `chartYMax`: base 1, then the max of every `sel` and `goal ?? 0` per series; if more than one series, also compare against the sum of all `sel` values; multiply the result by 1.08. `monthForSwitch`: if the target key exists, return it with `copiedFrom: nil`; otherwise search existing keys sorted ascending for the largest key strictly less than the target, falling back to the lexicographically-last existing key, falling back to `BudgetDefaults.month()` if no months exist at all; deep-copy the source, reset every item's `sel` to `false`, leave `goal` fields unchanged; `copiedFrom` is the source key used, or `nil` only when no months existed. `yearAggregate` walks months 1 through 12 of the given year and reports `has`/`planned`/`takeHome` (zeroed when absent).

Codable JSON keys are exact and match the JS payload shape: `BudgetRow` as `n, a, sel`; `BudgetIncome` as `label, gross, tax, ret, oth`; `BudgetCategory` as `n, open, goal, items`; `BudgetMonth` as `inc2On, inc, cats`; `BudgetDB` as `v, cur, months`. `BudgetCategory.goal` decodes from an explicit JSON `null` or an absent key identically (`decodeIfPresent`), and always encodes as an explicit `null` when `nil` (never an absent key), matching the JS `c.goal=c.goal` deep-copy-preserves-null-or-absent convention exactly.

`BudgetShare.export` replicates the JS `exBudget()` (lines 3713-3735) text template: `"Budget · " + label`, a summary line with take-home/planned/left via `money()`, an `INCOME` section, one line per category (`uppercased name — money(total)`, em dash), one line per non-empty item, an optional `(goal money(goal))` line when a goal is set, and a trailing `\n#hannahs-budget-v1 ` plus base64 of the UTF-8 JSON `{"k": cur, "m": month}` payload. `BudgetShare.parse` replicates `importBudget()` (lines 3832-3845): regex `#hannahs-budget-v1\s+([A-Za-z0-9+/=]+)`, base64-decode as UTF-8 JSON, guard on `payload.k` and non-empty `payload.m.cats`, and construct a fresh `BudgetDB(v: 2, cur: payload.k, months: [payload.k: payload.m])`. Byte-identical export text is not required; cross round-trip decodability is: a Swift-exported payload's base64 JSON must be parseable by the JS `importBudget` logic, and a JS-exported payload must be parseable by `BudgetShare.parse`. The JS `importBudget` additionally merges the imported month into whatever `BudgetDB` already exists in `localStorage` rather than replacing it outright; `BudgetShare.parse` returns a minimal single-month `BudgetDB` and leaves any merge-into-existing-store behavior to the caller.

Defaults are verbatim from the JS `defMonth()` (lines ~3134-3149): 11 categories (Housing through Everything Else), `Housing.open == true` and every other category closed, incomes `4200/18/5/2` and `3600/16/5/0`, `inc2On == true`. `PRESETS` (lines ~3120-3132): 12 presets including `Blank category` (which the UI relabels to "New category" on add). `COLORS` (line 3116) and `MONTHS` (line 3117) are transcribed verbatim as `BudgetDefaults.colors` (`[String]` hex values, Foundation-only per the BloomCore house rule; UI call sites convert via `Color(hex:)`) and `BudgetDefaults.monthNames`.

Vectors: `contracts/vectors.json` and `Packages/BloomCore/Tests/BloomCoreTests/Resources/vectors.json` carry 14 budget-prefixed keys (`budgetYmKey, budgetParseYM, budgetMonthLabel, budgetMonthDays, budgetChartYMax, budgetPerDay, budgetImportRow, budgetCatTotals, budgetNetOf, budgetTakeHome, budgetPlanned, budgetMonthSwitch, budgetYearAggregate, budgetShare`), 67 vectors total, generated by the budget section of `scripts/gen_vectors.mjs` and verified by the budget section of `scripts/verify_mirror.py`. `Packages/BloomCore/Tests/BloomCoreTests/BudgetTests.swift` asserts the combined budget vector count is at least 40.
