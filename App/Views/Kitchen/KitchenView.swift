import SwiftUI

struct KitchenView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                kitchenTabs

                switch store.activeTab {
                case .convert:
                    ConvertPanel()
                case .recipe:
                    RecipePanel()
                case .visualize:
                    VisualizePanel()
                }
            }
            .padding(16)
        }
        .background(theme.color("bg"))
    }

    private var kitchenTabs: some View {
        HStack(spacing: 8) {
            tabButton("Convert", tab: .convert)
            tabButton("Recipe", tab: .recipe)
            tabButton("Visualize", tab: .visualize)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surfaceSoft"))
        )
    }

    private func tabButton(_ title: String, tab: KitchenTab) -> some View {
        let isActive = store.activeTab == tab
        return Button {
            store.activeTab = tab
        } label: {
            Text(title)
                .font(bloomBody(14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: theme.radius - 4)
                        .fill(isActive ? theme.color("surface") : Color.clear)
                )
                .foregroundStyle(isActive ? theme.color("deep") : theme.color("muted"))
        }
        .buttonStyle(.plain)
    }
}
