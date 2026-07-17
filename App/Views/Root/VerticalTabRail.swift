import SwiftUI

/// Landscape navigation: the portrait bottom tab bar becomes a vertical rail on the
/// RIGHT edge of the screen, freeing the full height for real content. All text is
/// upright — a normal VStack of icon+label buttons, no rotation — so it reads
/// correctly in landscape. Mirrors BloomTabBar's colors + active-tab language.
///
/// The rail also carries the header buttons (sound, history, theme) that portrait
/// keeps in its top bar. That is not decoration: the theme editor is the ONLY way
/// to change the orientation lock, so a landscape lock with no way to reach it
/// would strand her sideways for good.
///
/// It scrolls rather than flexes. Ten controls at a real 44pt+ do not fit the
/// ~350pt landscape height of a phone, and squeezing them to fit would undo the
/// tap targets. Scrolling costs nothing on a screen where they all fit
/// (.scrollBounceBehavior(.basedOnSize) keeps it inert there).
struct VerticalTabRail: View {
    @Environment(ThemeStore.self) private var theme
    @Binding var selection: BloomTab
    var onSelect: (BloomTab) -> Void
    var onSound: () -> Void = {}
    var onHistory: () -> Void = {}
    var onTheme: () -> Void = {}

    private static let itemHeight: CGFloat = 46

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 4) {
                ForEach(BloomTab.allCases) { tab in
                    railButton(tab)
                }

                Rectangle()
                    .fill(theme.color("line"))
                    .frame(height: 1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 2)

                railIcon("speaker.wave.2", label: "Sounds", action: onSound)
                railIcon("clock", label: "History", action: onHistory)
                railIcon("pencil", label: "Theme and colors", action: onTheme)
            }
            .padding(.vertical, 6)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(width: 68)
        .frame(maxHeight: .infinity)
        .background(theme.color("surface"))
        .overlay(alignment: .leading) {
            // Divider sits on the rail's LEADING edge, between content and rail.
            Rectangle().fill(theme.color("line")).frame(width: 1)
        }
    }

    private func railButton(_ tab: BloomTab) -> some View {
        let active = tab == selection
        return Button {
            if selection != tab { onSelect(tab) }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 18, weight: active ? .semibold : .regular))
                if theme.showTabLabels {
                    Text(tab.label)
                        .font(bloomBody(8, weight: active ? .semibold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)   // "Monthly Budget" shrinks, never wraps
                }
            }
            .foregroundStyle(active ? theme.color("primaryStrong") : theme.color("muted"))
            .frame(maxWidth: .infinity)
            .frame(height: Self.itemHeight)
            .background {
                if active {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(theme.color("surfaceSoft"))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private func railIcon(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.color("accentInk"))
                .frame(maxWidth: .infinity)
                .frame(height: Self.itemHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(TactilePressStyle(cornerRadius: 12))
        .accessibilityLabel(label)
    }
}
