import SwiftUI
import BloomCore

struct ToolsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TipSplitCard()
                PercentageCard()
                LoanPaymentCard()
                SavingsGoalCard()
                ClearToolsButton()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
}

/// One quiet reset for the whole tab. Per-card clears would be four more things
/// to tap past; the ⌫ inside each field already covers a single wrong digit.
private struct ClearToolsButton: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(DraftStore.self) private var drafts

    var body: some View {
        Button {
            drafts.clearTools()
            ToastCenter.shared.show(title: "Cleared", message: "This page is fresh again.")
        } label: {
            Text("Clear this page")
                .font(bloomBody(13))
                .foregroundStyle(themeStore.color("muted"))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(TactilePressStyle(cornerRadius: 12))
        .discoverable("tools.clear", cornerRadius: 12)
        .padding(.top, 4)
    }
}

private struct ToolHeader: View {
    @Environment(ThemeStore.self) private var themeStore
    var title: String

    var body: some View {
        Text(title)
            .font(bloomNumber(17, weight: .semibold))
            .foregroundStyle(themeStore.color("deep"))
    }
}

private struct TipSplitCard: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(DraftStore.self) private var drafts

    @State private var pressEpoch = 0
    @State private var tipResult: Double = 0
    @State private var totalResult: Double = 0
    @State private var perPersonResult: Double = 0

    var body: some View {
        @Bindable var d = drafts
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeader(title: "Tip and split")
                ProjectionFieldRow(leftLabel: "Bill amount", leftText: $d.tipSplit.bill, rightLabel: "Tip %", rightText: $d.tipSplit.tipPct)
                ProjectionFormField(label: "Split between", text: $d.tipSplit.people)
                ProjectionCalcButton(label: "Work it out") {
                    calculate()
                    pressEpoch += 1
                }
                .encircleOnPress(pressEpoch, cornerRadius: themeStore.radius * 0.6)
                if drafts.tipSplit.didCalculate {
                    HStack(spacing: 16) {
                        ProjectionResultStat(label: "Tip", value: Formatters.money(tipResult))
                        ProjectionResultStat(label: "Total", value: Formatters.money(totalResult))
                        ProjectionResultStat(label: "Each pays", value: Formatters.money(perPersonResult), isGrowth: true)
                    }
                }
                ProjectionDisclaimer(text: "Illustrative only.")
            }
        }
        .onAppear { if drafts.tipSplit.didCalculate { recompute() } }
    }

    /// The maths only. `calculate()` adds the things that must happen once per
    /// tap — a history row, a sound — and must never fire on a silent replay.
    private func recompute() {
        let bill = Double(drafts.tipSplit.bill) ?? 0
        let tipPct = Double(drafts.tipSplit.tipPct) ?? 0
        let people = Int(drafts.tipSplit.people) ?? 1
        let result = FinanceMath.tip(bill: bill, tipPct: tipPct, people: max(people, 1))
        tipResult = result.tip
        totalResult = result.total
        perPersonResult = result.perPerson
    }

    private func calculate() {
        recompute()
        drafts.tipSplit.didCalculate = true

        historyStore.add(
            type: "tool",
            title: "Tip and split",
            value: Formatters.money(perPersonResult),
            extra: ["bill": drafts.tipSplit.bill, "tipPct": drafts.tipSplit.tipPct, "people": drafts.tipSplit.people]
        )
        soundStore.play("success")
    }
}

private struct PercentageCard: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore

    @Environment(DraftStore.self) private var drafts

    @State private var pressEpoch = 0
    @State private var resultValue: Double = 0

    private let modes = [
        ("of", "What is X percent of Y", "Percent X", "Of Y"),
        ("change", "Percent change from A to B", "From A", "To B"),
        ("discount", "Price after X percent off", "Percent off", "Of price"),
        ("markup", "Cost plus X percent markup", "Percent markup", "Of cost")
    ]

    var body: some View {
        @Bindable var d = drafts
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeader(title: "Percentage")
                modePicker
                ProjectionFieldRow(leftLabel: currentLabels.0, leftText: $d.percentage.a, rightLabel: currentLabels.1, rightText: $d.percentage.b)
                ProjectionCalcButton(label: "Calculate") {
                    calculate()
                    pressEpoch += 1
                }
                .encircleOnPress(pressEpoch, cornerRadius: themeStore.radius * 0.6)
                if drafts.percentage.didCalculate {
                    ProjectionResultStat(label: resultLabel, value: formattedResult, isGrowth: true)
                }
                ProjectionDisclaimer(text: "Illustrative only.")
            }
        }
        .onAppear { if drafts.percentage.didCalculate { recompute() } }
    }

    private var modePicker: some View {
        Menu {
            ForEach(modes, id: \.0) { entry in
                Button(entry.1) { drafts.percentage.mode = entry.0 }
            }
        } label: {
            HStack {
                Text(modes.first { $0.0 == drafts.percentage.mode }?.1 ?? "")
                    .font(bloomBody(14))
                    .foregroundStyle(themeStore.color("text"))
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(themeStore.color("muted"))
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .background(themeStore.color("surfaceSoft"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var currentLabels: (String, String) {
        let entry = modes.first { $0.0 == drafts.percentage.mode }
        return (entry?.2 ?? "X", entry?.3 ?? "Y")
    }

    private var resultLabel: String {
        drafts.percentage.mode == "change" ? "Change" : "Result"
    }

    private var formattedResult: String {
        drafts.percentage.mode == "change" ? "\(Formatters.plain(resultValue))%" : Formatters.money(resultValue)
    }

    private func recompute() {
        let a = Double(drafts.percentage.a) ?? 0
        let b = Double(drafts.percentage.b) ?? 0
        switch drafts.percentage.mode {
        case "of":
            resultValue = FinanceMath.percentOf(a, of: b)
        case "change":
            resultValue = FinanceMath.percentChange(from: a, to: b)
        case "discount":
            resultValue = b - FinanceMath.percentOf(a, of: b)
        default:
            resultValue = b + FinanceMath.percentOf(a, of: b)
        }
    }

    private func calculate() {
        recompute()
        drafts.percentage.didCalculate = true

        historyStore.add(
            type: "tool",
            title: "Percentage",
            value: formattedResult,
            extra: ["mode": drafts.percentage.mode, "a": drafts.percentage.a, "b": drafts.percentage.b]
        )
        soundStore.play("success")
    }
}

private struct LoanPaymentCard: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore

    @Environment(DraftStore.self) private var drafts

    @State private var pressEpoch = 0
    @State private var monthlyResult: Double = 0
    @State private var totalInterestResult: Double = 0

    var body: some View {
        @Bindable var d = drafts
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeader(title: "Loan payment")
                ProjectionFieldRow(leftLabel: "Amount", leftText: $d.loan.amount, rightLabel: "Rate % / yr", rightText: $d.loan.rate)
                ProjectionFormField(label: "Years", text: $d.loan.years)
                ProjectionCalcButton(label: "Find the payment") {
                    calculate()
                    pressEpoch += 1
                }
                .encircleOnPress(pressEpoch, cornerRadius: themeStore.radius * 0.6)
                if drafts.loan.didCalculate {
                    HStack(spacing: 20) {
                        ProjectionResultStat(label: "Monthly", value: Formatters.money(monthlyResult), isGrowth: true)
                        ProjectionResultStat(label: "Total interest", value: Formatters.money(totalInterestResult))
                    }
                }
                ProjectionDisclaimer(text: "Illustrative only. Not a loan offer, and not financial advice.")
            }
        }
        .onAppear { if drafts.loan.didCalculate { recompute() } }
    }

    private func recompute() {
        let amount = Double(drafts.loan.amount) ?? 0
        let rate = Double(drafts.loan.rate) ?? 0
        let years = Double(drafts.loan.years) ?? 0
        monthlyResult = FinanceMath.loanPayment(principal: amount, annualRatePct: rate, years: years)
        totalInterestResult = max(monthlyResult * years * 12 - amount, 0)
    }

    private func calculate() {
        recompute()
        drafts.loan.didCalculate = true

        historyStore.add(
            type: "tool",
            title: "Loan payment",
            value: Formatters.money(monthlyResult),
            extra: ["amount": drafts.loan.amount, "ratePct": drafts.loan.rate, "years": drafts.loan.years]
        )
        soundStore.play("success")
    }
}

private struct SavingsGoalCard: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore

    @Environment(DraftStore.self) private var drafts

    @State private var pressEpoch = 0
    @State private var monthlyResult: Double = 0

    var body: some View {
        @Bindable var d = drafts
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeader(title: "Savings goal")
                ProjectionFieldRow(leftLabel: "Target", leftText: $d.savings.target, rightLabel: "Years", rightText: $d.savings.years)
                ProjectionFieldRow(leftLabel: "Rate % / yr", leftText: $d.savings.rate, rightLabel: "Starting", rightText: $d.savings.start)
                ProjectionCalcButton(label: "How much per month") {
                    calculate()
                    pressEpoch += 1
                }
                .encircleOnPress(pressEpoch, cornerRadius: themeStore.radius * 0.6)
                if drafts.savings.didCalculate {
                    HStack(spacing: 20) {
                        ProjectionResultStat(label: "Save monthly", value: Formatters.money(monthlyResult), isGrowth: true)
                        ProjectionResultStat(label: "Note", value: monthlyResult > 0 ? "on track" : "goal met")
                    }
                }
                ProjectionDisclaimer(text: "Illustrative only. Not financial advice.")
            }
        }
        .onAppear { if drafts.savings.didCalculate { recompute() } }
    }

    private func recompute() {
        let target = Double(drafts.savings.target) ?? 0
        let years = Double(drafts.savings.years) ?? 0
        let rate = Double(drafts.savings.rate) ?? 0
        let start = Double(drafts.savings.start) ?? 0
        monthlyResult = FinanceMath.savingsGoalPayment(target: target, principal: start, annualRatePct: rate, years: years)
    }

    private func calculate() {
        recompute()
        drafts.savings.didCalculate = true

        historyStore.add(
            type: "tool",
            title: "Savings goal",
            value: Formatters.money(monthlyResult),
            extra: ["target": drafts.savings.target, "years": drafts.savings.years, "ratePct": drafts.savings.rate, "start": drafts.savings.start]
        )
        soundStore.play("success")
    }
}

/// Brief press-feedback ring: on each `epoch` bump, trace the shared
/// `EncircleOutline` around the control, then unmount it after ~1s so it fades
/// away instead of leaving a permanent glow. (EncircleOutline settles at its
/// `settleOpacity` forever, so a lingering mount would stay lit — hence the
/// timed unmount.) Gated behind `theme.shimmerOn`. Shared by ToolsView and
/// MusicView via `.encircleOnPress`.
/// ponytail: plain timed unmount; a stale timer is guarded by `generation`
/// so a rapid re-press never clears a newer ring early.
private struct PressEncircleModifier: ViewModifier {
    @Environment(ThemeStore.self) private var theme
    let epoch: Int
    var cornerRadius: CGFloat = 12
    var lineWidth: CGFloat = 1.5

    @State private var showing = false
    @State private var generation = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if theme.shimmerOn && showing {
                    EncircleOutline(trigger: epoch, cornerRadius: cornerRadius, lineWidth: lineWidth)
                        .transition(.opacity)
                }
            }
            .onChange(of: epoch) { _, newValue in
                guard newValue > 0 else { return }
                showing = true
                generation += 1
                let expected = generation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if generation == expected {
                        withAnimation(.easeOut(duration: 0.35)) { showing = false }
                    }
                }
            }
    }
}

extension View {
    /// Trace the encircle hairline around this control for ~1s whenever `epoch`
    /// bumps. See `PressEncircleModifier`.
    func encircleOnPress(_ epoch: Int, cornerRadius: CGFloat = 12, lineWidth: CGFloat = 1.5) -> some View {
        modifier(PressEncircleModifier(epoch: epoch, cornerRadius: cornerRadius, lineWidth: lineWidth))
    }
}
