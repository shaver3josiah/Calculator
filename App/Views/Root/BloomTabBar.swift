import SwiftUI

struct BloomTabBar: View {
    @Environment(ThemeStore.self) private var themeStore
    @Binding var selection: BloomTab
    var onSelect: (BloomTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BloomTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .padding(.horizontal, 6)
        .background(themeStore.color("surface"))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(themeStore.color("line"))
                .frame(height: 1)
        }
    }

    private func tabButton(_ tab: BloomTab) -> some View {
        let isActive = tab == selection
        return Button {
            if selection != tab {
                onSelect(tab)
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 18, weight: isActive ? .semibold : .regular))
                if themeStore.showTabLabels {
                    Text(tab.label)
                        .font(bloomBody(9.5, weight: isActive ? .semibold : .regular))
                }
            }
            .frame(height: 38)
            .foregroundStyle(isActive ? themeStore.color("primaryStrong") : themeStore.color("muted"))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
