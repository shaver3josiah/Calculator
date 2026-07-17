import SwiftUI
import BloomCore

/// The leftover → S&P 500 handoff. Renders only when there's at least a dollar
/// left to grow — when there isn't, the bottom-line card already tells that story.
struct GrowLeftoverCard: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @Environment(ProjectionStore.self) private var projectionStore

    var body: some View {
        // ZStack container so the card can fade/scale in and out as edits push
        // the leftover across the $1 line — popping mid-scroll shifts the
        // categories under her finger.
        ZStack {
            if store.trueLeftOver >= 1 {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Grow what's left")
                            .font(bloomNumber(17, weight: .semibold))
                            .foregroundStyle(theme.color("deep"))
                        Text("\(Formatters.money(store.trueLeftOver)) a month, invested in the S&P 500 (its long-run average is about 10%), could really bloom.")
                            .font(bloomBody(12))
                            .foregroundStyle(theme.color("muted"))
                            .fixedSize(horizontal: false, vertical: true)
                        projectButton
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(theme.motionEnabled ? BloomMotion.springSoft : nil,
                   value: store.trueLeftOver >= 1)
    }

    private var projectButton: some View {
        Button {
            projectionStore.pendingGrow = PendingGrow(monthly: store.trueLeftOver)
            projectionStore.jumpToGrowEpoch += 1
        } label: {
            Text("Project it in the garden")
                .font(bloomBody(15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(theme.color("primaryStrong"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(TactilePressStyle(cornerRadius: 14))
        .discoverable("budget.growLeftover")
    }
}
