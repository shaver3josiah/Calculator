import SwiftUI
import Charts
import BloomCore

/// A long-horizon nest egg for a little one. Same monthly-compounding engine as
/// Grow, but the asset-class chips seed an honest editable rate — including the
/// land / real-estate profile she asked for (appreciation-only, so a lower rate
/// than stocks). Everything is a projection at a fixed rate; the rate is hers to
/// change, and the disclaimer says so.
struct BabyPanel: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(DraftStore.self) private var drafts

    @State private var points: [BabyPoint] = []
    @State private var futureValueResult: Double = 0
    @State private var contributionsResult: Double = 0

    /// Asset profiles with a starting rate. Editable defaults, not promises — the
    /// stocks figure is a conservative long-run number, real estate is appreciation
    /// only (no leverage, no rental income), bonds are today-ish.
    private struct AssetClass: Identifiable {
        let id: String
        let name: String
        let rate: Double
        let blurb: String
    }
    private let assetClasses: [AssetClass] = [
        AssetClass(id: "stocks", name: "Stocks", rate: 7, blurb: "A broad index fund, long-run pace."),
        AssetClass(id: "balanced", name: "Balanced", rate: 6, blurb: "A stock-and-bond mix, gentler ride."),
        AssetClass(id: "bonds", name: "Bonds", rate: 4, blurb: "Steadier, slower."),
        AssetClass(id: "realEstate", name: "Land & real estate", rate: 4.5, blurb: "Property appreciation, US long-run average.")
    ]

    var body: some View {
        @Bindable var d = drafts
        Card {
            VStack(alignment: .leading, spacing: 16) {
                Text("A garden for the little one")
                    .font(bloomNumber(17, weight: .semibold))
                    .foregroundStyle(themeStore.color("deep"))

                ProjectionFieldRow(
                    leftLabel: "Starting amount",
                    leftText: $d.baby.lumpSum,
                    rightLabel: "Monthly added",
                    rightText: $d.baby.monthly
                )
                yearsSlider
                assetPicker
                ProjectionFormField(label: "Yearly growth %", text: $d.baby.rate)

                ProjectionCalcButton(label: "Watch it grow", action: calculate)
                if drafts.baby.didCalculate {
                    resultSection
                }
                ProjectionDisclaimer(text: "Illustrative projection at a fixed annual rate, compounded monthly. The rate is an editable estimate, not a guaranteed return — real accounts (a 529, a custodial account, or the land itself) carry fees, taxes and risk. Not financial advice.")
            }
        }
        .onAppear {
            if drafts.baby.didCalculate { recompute() }
        }
    }

    private var yearsSlider: some View {
        let sliderYears = Double(drafts.baby.years) ?? 18
        return VStack(alignment: .leading, spacing: 6) {
            Text("Years to grow: \(Int(sliderYears))")
                .font(bloomBody(12, weight: .medium))
                .foregroundStyle(themeStore.color("muted"))
            Slider(
                value: Binding(
                    get: { Double(drafts.baby.years) ?? 18 },
                    set: { drafts.baby.years = String(Int($0)) }
                ),
                in: 1...40, step: 1
            )
            .tint(themeStore.color("primaryStrong"))
        }
    }

    private var assetPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What is it invested in?")
                .font(bloomBody(12, weight: .medium))
                .foregroundStyle(themeStore.color("muted"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(assetClasses) { asset in
                        assetChip(asset)
                    }
                }
            }
            if let current = assetClasses.first(where: { $0.id == drafts.baby.assetClass }) {
                Text(current.blurb)
                    .font(bloomBody(11))
                    .foregroundStyle(themeStore.color("muted"))
            }
        }
    }

    private func assetChip(_ asset: AssetClass) -> some View {
        let isSelected = asset.id == drafts.baby.assetClass
        return Button {
            drafts.baby.assetClass = asset.id
            // Picking a profile seeds its rate — she can still overwrite the field.
            drafts.baby.rate = Formatters.plain(asset.rate)
        } label: {
            VStack(spacing: 2) {
                Text(asset.name)
                    .font(bloomBody(12, weight: .semibold))
                Text("\(Formatters.plain(asset.rate))%")
                    .font(bloomBody(10))
            }
            .foregroundStyle(isSelected ? .white : themeStore.color("text"))
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(isSelected ? themeStore.color("primaryStrong") : themeStore.color("surfaceSoft"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(TactilePressStyle(cornerRadius: 12))
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                FlowerLogo(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("BY THEN, ABOUT")
                        .font(bloomBody(10, weight: .semibold))
                        .foregroundStyle(themeStore.color("muted"))
                    RollingNumberText(
                        text: Formatters.money(futureValueResult),
                        font: bloomNumber(28, weight: .semibold),
                        color: themeStore.color("deep")
                    )
                }
            }
            HStack(spacing: 20) {
                ProjectionResultStat(label: "You put in", value: Formatters.money(contributionsResult))
                ProjectionResultStat(label: "Growth", value: Formatters.money(futureValueResult - contributionsResult), isGrowth: true)
            }
            if !points.isEmpty {
                chart
            }
        }
    }

    private var chart: some View {
        Chart(points) { point in
            AreaMark(x: .value("Year", point.year), y: .value("Balance", point.balance))
                .foregroundStyle(themeStore.color("primary").opacity(0.25))
            LineMark(x: .value("Year", point.year), y: .value("Balance", point.balance))
                .foregroundStyle(themeStore.color("primaryStrong"))
        }
        .frame(height: 150)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .accessibilityLabel("Projected growth chart")
        .accessibilityValue("Grows to \(Formatters.money(futureValueResult)) over \(max(points.count - 1, 1)) years")
        .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: points.count)
    }

    private var years: Int { max(Int(Double(drafts.baby.years) ?? 18), 1) }
    private var rate: Double { Double(drafts.baby.rate) ?? 7 }

    private func recompute() {
        let principal = Double(drafts.baby.lumpSum) ?? 0
        let monthly = Double(drafts.baby.monthly) ?? 0
        futureValueResult = FinanceMath.futureValue(principal: principal, monthly: monthly, annualRatePct: rate, years: Double(years))
        contributionsResult = FinanceMath.contributions(principal: principal, monthly: monthly, years: Double(years))
        points = FinanceMath.futureValueSeries(principal: principal, monthly: monthly, annualRatePct: rate, years: years)
            .enumerated().map { BabyPoint(year: $0.offset, balance: $0.element) }
    }

    private func calculate() {
        recompute()
        drafts.baby.didCalculate = true
        historyStore.add(
            type: "proj",
            title: "Baby: \(assetClasses.first { $0.id == drafts.baby.assetClass }?.name ?? "grow")",
            value: Formatters.money(futureValueResult),
            extra: [
                "lumpSum": drafts.baby.lumpSum,
                "monthly": drafts.baby.monthly,
                "years": String(years),
                "ratePct": Formatters.plain(rate)
            ]
        )
        soundStore.play("success")
    }
}

private struct BabyPoint: Identifiable {
    let year: Int
    let balance: Double
    var id: Int { year }
}
