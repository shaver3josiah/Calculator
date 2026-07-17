import SwiftUI
import Charts
import BloomCore

/// "Trump Account" projector — the tax-advantaged children's account created by
/// the One Big Beautiful Bill Act (July 2025). The real rules this models:
///   • a one-time $1,000 federal seed for a child born 2025–2028,
///   • contributions up to $5,000/yr (employers may add up to $2,500 of that),
///   • money invested in a low-fee US stock index fund,
///   • no withdrawals before 18, when it converts to a traditional IRA.
/// It's a projection at a fixed, editable rate — not tax advice, and the caps are
/// enforced here so the number can't quietly assume an illegal contribution.
struct TrumpPanel: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(DraftStore.self) private var drafts

    @State private var points: [TrumpPoint] = []
    @State private var finalBalance: Double = 0
    @State private var totalContributed: Double = 0

    // The program's real limits (2025 law). Employer money is a subset of the
    // annual cap, not an addition on top of it.
    private static let annualCap: Double = 5000
    private static let employerCap: Double = 2500

    var body: some View {
        @Bindable var d = drafts
        Card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Trump Account")
                    .font(bloomNumber(17, weight: .semibold))
                    .foregroundStyle(themeStore.color("deep"))

                seedNote

                ProjectionFieldRow(
                    leftLabel: "Starting balance",
                    leftText: $d.trump.startBalance,
                    rightLabel: "You add /yr",
                    rightText: $d.trump.annualContribution
                )
                ProjectionFieldRow(
                    leftLabel: "Employer adds /yr",
                    leftText: $d.trump.employerContribution,
                    rightLabel: "Growth %/yr",
                    rightText: $d.trump.returnPct
                )
                ProjectionFieldRow(
                    leftLabel: "Child's age now",
                    leftText: $d.trump.currentAge,
                    rightLabel: "Born in year",
                    rightText: $d.trump.birthYear
                )
                capNote
                targetAgeSlider
                ProjectionFormField(label: "Fund fee %/yr (expense ratio)", text: $d.trump.expenseRatio)

                ProjectionCalcButton(label: "Project the account", action: calculate)
                if drafts.trump.didCalculate {
                    resultSection
                }
                ProjectionDisclaimer(text: "Illustrative projection of a Trump Account under the 2025 law, at a fixed editable rate. Contributions stop at 18, when the account becomes a traditional IRA. Rules and limits can change; this is not tax or financial advice.")
            }
        }
        .onAppear {
            if drafts.trump.didCalculate { recompute() }
        }
    }

    // MARK: derived inputs

    private var birthYear: Int { Int(drafts.trump.birthYear) ?? 2025 }
    private var seed: Double { FinanceMath.trumpSeed(birthYear: birthYear) }
    private var currentAge: Int { max(0, Int(Double(drafts.trump.currentAge) ?? 0)) }
    private var targetAge: Int { max(currentAge, Int(Double(drafts.trump.targetAge) ?? 18)) }

    /// Personal + employer contribution, with the real caps applied. Employer is
    /// clamped to its own $2,500 ceiling first, then the combined total to $5,000.
    private var cappedAnnual: Double {
        let personal = max(0, Double(drafts.trump.annualContribution) ?? 0)
        let employer = min(max(0, Double(drafts.trump.employerContribution) ?? 0), Self.employerCap)
        return min(personal + employer, Self.annualCap)
    }

    private var isOverCap: Bool {
        let personal = max(0, Double(drafts.trump.annualContribution) ?? 0)
        let employer = max(0, Double(drafts.trump.employerContribution) ?? 0)
        return personal + employer > Self.annualCap || employer > Self.employerCap
    }

    // MARK: sub-views

    private var seedNote: some View {
        let eligible = seed > 0
        return HStack(spacing: 8) {
            Image(systemName: eligible ? "gift.fill" : "info.circle")
                .foregroundStyle(themeStore.color(eligible ? "primaryStrong" : "muted"))
            Text(eligible
                 ? "Born \(birthYear): eligible for the one-time $1,000 federal seed. Add it to the starting balance."
                 : "Born \(birthYear): no federal seed (that's only for births 2025–2028).")
                .font(bloomBody(11))
                .foregroundStyle(themeStore.color("muted"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(themeStore.color("surfaceSoft")))
    }

    @ViewBuilder
    private var capNote: some View {
        if isOverCap {
            Text("Over the limit — capped at $5,000/yr total (employer at most $2,500 of it). The projection uses the capped amount.")
                .font(bloomBody(11, weight: .medium))
                .foregroundStyle(themeStore.color("primaryStrong"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var targetAgeSlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Project to age: \(targetAge)")
                .font(bloomBody(12, weight: .medium))
                .foregroundStyle(themeStore.color("muted"))
            Slider(
                value: Binding(
                    get: { Double(targetAge) },
                    set: { drafts.trump.targetAge = String(Int($0)) }
                ),
                // Lower bound is clamped to 64 so an out-of-range "child age" can
                // never build an inverted range (lower > upper) and crash the Slider.
                in: Double(min(currentAge + 1, 64))...65, step: 1
            )
            .tint(themeStore.color("primaryStrong"))
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                FlowerLogo(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AT AGE \(targetAge), ABOUT")
                        .font(bloomBody(10, weight: .semibold))
                        .foregroundStyle(themeStore.color("muted"))
                    RollingNumberText(
                        text: Formatters.money(finalBalance),
                        font: bloomNumber(28, weight: .semibold),
                        color: themeStore.color("deep")
                    )
                }
            }
            HStack(spacing: 20) {
                ProjectionResultStat(label: "Put in", value: Formatters.money(totalContributed))
                ProjectionResultStat(label: "Growth", value: Formatters.money(finalBalance - totalContributed), isGrowth: true)
            }
            if !points.isEmpty {
                chart
            }
        }
    }

    private var chart: some View {
        Chart(points) { point in
            AreaMark(x: .value("Age", point.age), y: .value("Balance", point.balance))
                .foregroundStyle(themeStore.color("primary").opacity(0.25))
            LineMark(x: .value("Age", point.age), y: .value("Balance", point.balance))
                .foregroundStyle(themeStore.color("primaryStrong"))
        }
        .frame(height: 150)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .accessibilityLabel("Projected account balance by age")
        .accessibilityValue("About \(Formatters.money(finalBalance)) at age \(targetAge)")
        .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: points.count)
    }

    // MARK: math

    private func recompute() {
        let start = max(0, Double(drafts.trump.startBalance) ?? 0)
        let expense = max(0, Double(drafts.trump.expenseRatio) ?? 0)
        let series = FinanceMath.trumpSeries(
            startBalance: start,
            annualContribution: cappedAnnual,
            currentAge: currentAge,
            targetAge: targetAge,
            returnPct: Double(drafts.trump.returnPct) ?? 7,
            expenseRatioPct: expense
        )
        points = series.map { TrumpPoint(age: $0.age, balance: $0.balance) }
        finalBalance = series.last?.balance ?? start
        // Contributions only land while the child is under 18.
        let contributingYears = max(0, min(targetAge, 18) - currentAge)
        totalContributed = start + cappedAnnual * Double(contributingYears)
    }

    private func calculate() {
        recompute()
        drafts.trump.didCalculate = true
        historyStore.add(
            type: "proj",
            title: "Trump Account",
            value: Formatters.money(finalBalance),
            extra: [
                "startBalance": drafts.trump.startBalance,
                "annual": Formatters.plain(cappedAnnual),
                "toAge": String(targetAge),
                "ratePct": drafts.trump.returnPct
            ]
        )
        soundStore.play("success")
    }
}

private struct TrumpPoint: Identifiable {
    let age: Int
    let balance: Double
    var id: Int { age }
}
