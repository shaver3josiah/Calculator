import SwiftUI
import UIKit

/// Copy + clear buttons that live inside a text box and appear only once
/// there's something to act on. Apply `.inputAccessories($text)` directly to
/// the TextField (inside its padding/background chain) — the field is wrapped
/// in an HStack, so the buttons never overlap the text.
///
/// `compact: true` drops the copy button (for narrow numeric fields where
/// copying "80" isn't worth the room). `alignment: .top` pins the buttons to
/// the first line of multi-line boxes.
struct InputAccessoryBar: View {
    @Environment(ThemeStore.self) private var theme
    @Binding var text: String
    var compact = false

    var body: some View {
        if !text.isEmpty {
            HStack(spacing: 0) {
                if !compact {
                    accessory("doc.on.doc", label: "Copy text") {
                        UIPasteboard.general.string = text
                        ToastCenter.shared.show(title: "Copied", message: "On the clipboard, ready to paste.")
                    }
                }
                accessory("xmark.circle.fill", label: "Clear text") {
                    withAnimation(.easeOut(duration: 0.15)) { text = "" }
                }
            }
            .transition(.opacity)
        }
    }

    private func accessory(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.color("muted"))
                // Height ≈ one text line so a field never grows when the
                // buttons appear; width keeps the tap target honest.
                .frame(width: 28, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

extension View {
    /// Wrap a TextField/TextEditor so copy + clear buttons sit at its trailing
    /// edge whenever it has content. Apply INSIDE the field's own box.
    func inputAccessories(
        _ text: Binding<String>,
        compact: Bool = false,
        alignment: VerticalAlignment = .center
    ) -> some View {
        HStack(alignment: alignment, spacing: 2) {
            self
            InputAccessoryBar(text: text, compact: compact)
        }
    }
}
