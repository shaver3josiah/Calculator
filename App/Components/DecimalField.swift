import SwiftUI
import BloomCore

/// A number field that doesn't fight her typing. The old pattern bound the TextField
/// straight to `Formatters.plain(Double)`, so every keystroke round-tripped through a
/// Double: typing "12." reformatted to "12" and the decimal point vanished under her
/// finger. This field owns the raw text — every keystroke still parses and pushes the
/// value (totals stay live), but the text is only re-rendered from the value when the
/// field is NOT being edited. nil shows as empty so the grey prompt reads.
struct DecimalField: View {
    @Environment(ThemeStore.self) private var theme

    @Binding var value: Double?
    var prompt = "0"
    var font: Font = bloomBody(14)
    var alignment: TextAlignment = .leading
    /// Fixed width for the text box itself (the clear accessory sits OUTSIDE it, so a
    /// showing accessory never squeezes the digits). nil = flexible.
    var width: CGFloat?

    @State private var text = ""
    @FocusState private var focused: Bool

    /// Non-optional convenience: empty field ⇄ 0.
    init(value: Binding<Double>, prompt: String = "0", font: Font = bloomBody(14),
         alignment: TextAlignment = .leading, width: CGFloat? = nil) {
        self.init(
            value: Binding<Double?>(
                get: { value.wrappedValue == 0 ? nil : value.wrappedValue },
                set: { value.wrappedValue = $0 ?? 0 }
            ),
            prompt: prompt, font: font, alignment: alignment, width: width
        )
    }

    init(value: Binding<Double?>, prompt: String = "0", font: Font = bloomBody(14),
         alignment: TextAlignment = .leading, width: CGFloat? = nil) {
        self._value = value
        self.prompt = prompt
        self.font = font
        self.alignment = alignment
        self.width = width
    }

    var body: some View {
        TextField(prompt, text: $text, prompt: Text(prompt).foregroundStyle(theme.color("muted")))
            .keyboardType(.decimalPad)
            .font(font)
            .foregroundStyle(theme.color("text"))
            .multilineTextAlignment(alignment)
            .focused($focused)
            .frame(width: width)
            .inputAccessories($text, compact: true)
            .onAppear { text = Self.display(value) }
            .onChange(of: text) { _, t in
                // A cleared field is an explicit nil, whoever cleared it (keyboard or
                // the accessory ✕ while unfocused) — and it's a no-op when the clear
                // was our own programmatic display(nil).
                if t.trimmingCharacters(in: .whitespaces).isEmpty {
                    value = nil
                    return
                }
                // Only real keystrokes commit. Programmatic rewrites (appear, blur
                // re-canonicalisation, external sync) happen unfocused and must not
                // echo a rounded render back into the model.
                guard focused, let parsed = Double(Self.normalize(t)), parsed.isFinite else { return }
                value = parsed
            }
            .onChange(of: focused) { _, isFocused in
                if !isFocused { text = Self.display(value) }
            }
            .onChange(of: value) { _, v in
                // External change (budget import, +/- steppers) while she's not typing here.
                guard !focused else { return }
                text = Self.display(v)
            }
    }

    /// Comma-decimal locales put "," on the decimal pad — map it to "." there. On
    /// dot-decimal locales a comma can only be pasted grouping ("1,234") — strip it.
    private static func normalize(_ t: String) -> String {
        let raw = t.trimmingCharacters(in: .whitespaces)
        let commaIsDecimal = Locale.current.decimalSeparator == ","
        return raw.replacingOccurrences(of: ",", with: commaIsDecimal ? "." : "")
    }

    private static func display(_ v: Double?) -> String {
        guard let v else { return "" }
        return Formatters.plain(v)
    }
}
