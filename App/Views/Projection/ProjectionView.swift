import SwiftUI
import BloomCore

struct ProjectionView: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(DraftStore.self) private var drafts

    private let panels = ["Grow", "Baby", "Trump", "Whole life", "Retire", "Match", "Real rate", "Compare", "Rule of 72", "Beat market"]

    var body: some View {
        @Bindable var d = drafts
        ScrollView {
            VStack(spacing: 16) {
                KTabBar(items: panels, selection: $d.picks.projection)
                panelContent
                ClearProjectionButton()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private var panelContent: some View {
        switch drafts.picks.projection {
        case "Grow":
            GrowPanel()
        case "Baby":
            BabyPanel()
        case "Trump":
            TrumpPanel()
        case "Whole life":
            WholeLifePanel()
        case "Retire":
            RetirePanel()
        case "Match":
            MatchPanel()
        case "Real rate":
            RealRatePanel()
        case "Compare":
            ComparePanel()
        case "Beat market":
            ReturnsChart()
        default:
            RuleOf72Panel()
        }
    }
}

/// One quiet reset for the whole tab, matching the Tools tab. The ⌫ inside each
/// field still covers a single wrong digit.
private struct ClearProjectionButton: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(DraftStore.self) private var drafts

    var body: some View {
        Button {
            drafts.clearProjection()
            ToastCenter.shared.show(title: "Cleared", message: "This page is fresh again.")
        } label: {
            Text("Clear this page")
                .font(bloomBody(13))
                .foregroundStyle(themeStore.color("muted"))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(TactilePressStyle(cornerRadius: 12))
        .discoverable("proj.clear", cornerRadius: 12)
        .padding(.top, 4)
    }
}
