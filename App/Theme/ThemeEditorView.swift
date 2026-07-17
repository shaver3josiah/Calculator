import SwiftUI
import UIKit
import BloomCore

struct ThemeEditorView: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(CalcStore.self) private var calcStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    darkModeRow
                    presetSection
                    keysSection
                    screenSection
                    displaySection
                    motionSection
                    editableTokensSection
                }
                .padding(20)
            }
            .background(themeStore.color("bg"))
            .navigationTitle("Theme and colors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(bloomBody(15, weight: .semibold))
                }
            }
        }
    }

    // One friendly switch at the very top: moon on → the midnight garden,
    // moon off → right back to the light palette she had.
    private var darkModeRow: some View {
        Toggle(isOn: Binding(get: { themeStore.darkModeOn }, set: { themeStore.darkModeOn = $0 })) {
            HStack(spacing: 10) {
                Image(systemName: themeStore.isDark ? "moon.stars.fill" : "moon")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(themeStore.color(themeStore.isDark ? "flowerCenter" : "primaryStrong"))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Dark mode")
                        .font(bloomBody(15, weight: .semibold))
                        .foregroundStyle(themeStore.color("text"))
                    Text(themeStore.isDark ? "The garden at night" : "Lights down, petals still pink")
                        .font(bloomBody(12))
                        .foregroundStyle(themeStore.color("muted"))
                }
            }
        }
        .tint(themeStore.color("primaryStrong"))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(themeStore.color("surface"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .discoverable("theme.darkMode", cornerRadius: 16)
    }

    // Keypad key silhouette — soft squares (the classic) or circles. The
    // preview IS the control: two little keys, tap the one you want.
    private var keysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Calculator keys")
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(themeStore.color("muted"))
                .textCase(.uppercase)
            HStack(spacing: 12) {
                keyShapeChoice("soft", label: "Soft squares")
                keyShapeChoice("circle", label: "Circles")
            }
        }
    }

    private func keyShapeChoice(_ style: String, label: String) -> some View {
        let selected = themeStore.keyStyle == style
        return Button {
            withAnimation(BloomMotion.springSoft) { themeStore.keyStyle = style }
        } label: {
            VStack(spacing: 8) {
                // A mini "7" key drawn in the chosen shape, glyph dead-center.
                Text("7")
                    .font(bloomNumber(20, weight: .medium))
                    .foregroundStyle(themeStore.color("text"))
                    .frame(width: 52, height: 52)
                    .background(themeStore.color("surfaceSoft"))
                    .clipShape(RoundedRectangle(cornerRadius: style == "circle" ? 26 : themeStore.radius * 0.6))
                Text(label)
                    .font(bloomBody(12, weight: selected ? .semibold : .medium))
                    .foregroundStyle(themeStore.color(selected ? "deep" : "muted"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(themeStore.color("surface"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(selected ? themeStore.color("primaryStrong") : themeStore.color("line"),
                                  lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(TactilePressStyle(cornerRadius: 16))
        .accessibilityLabel("\(label) keys")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // Rotation lock. Worth calling out what landscape actually buys her —
    // it isn't just a wider page, it's a different calculator.
    private var screenSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Screen")
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(themeStore.color("muted"))
                .textCase(.uppercase)
            HStack(spacing: 12) {
                ForEach(OrientationPref.allCases, id: \.self) { pref in
                    orientationChoice(pref)
                }
            }
            Text("Landscape turns the calculator scientific.")
                .font(bloomBody(12))
                .foregroundStyle(themeStore.color("muted"))
        }
        .discoverable("theme.orientation", cornerRadius: 16)
    }

    private func orientationChoice(_ pref: OrientationPref) -> some View {
        let selected = themeStore.orientation == pref
        return Button {
            withAnimation(BloomMotion.springSoft) { themeStore.orientation = pref }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: pref.symbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(themeStore.color(selected ? "accentInk" : "text"))
                    .frame(width: 52, height: 44)
                Text(pref.label)
                    .font(bloomBody(12, weight: selected ? .semibold : .medium))
                    .foregroundStyle(themeStore.color(selected ? "deep" : "muted"))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 12)
            .background(themeStore.color("surface"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(selected ? themeStore.color("primaryStrong") : themeStore.color("line"),
                                  lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(TactilePressStyle(cornerRadius: 16))
        .accessibilityLabel("\(pref.label) screen")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Display")
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(themeStore.color("muted"))
                .textCase(.uppercase)
            VStack(spacing: 0) {
                Toggle(isOn: Binding(get: { themeStore.showTabLabels }, set: { themeStore.showTabLabels = $0 })) {
                    Text("Show tab labels")
                        .font(bloomBody(14))
                        .foregroundStyle(themeStore.color("text"))
                }
                .tint(themeStore.color("primaryStrong"))
                .padding(.vertical, 10)
                Divider().overlay(themeStore.color("line"))
                decimalsRow
            }
            .padding(.horizontal, 14)
            .background(themeStore.color("surface"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // The same setting the calculator's swipe-up/down changes, given a home in the
    // menu so it's discoverable without knowing the gesture exists.
    private var decimalsRow: some View {
        Stepper(
            value: Binding(
                get: { calcStore.decimals },
                set: { calcStore.decimals = min(8, max(0, $0)) }
            ),
            in: 0...8
        ) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Calculator decimals: \(calcStore.decimals)")
                    .font(bloomBody(14))
                    .foregroundStyle(themeStore.color("text"))
                Text("Or swipe the result up for more, down for fewer.")
                    .font(bloomBody(11))
                    .foregroundStyle(themeStore.color("muted"))
            }
        }
        .tint(themeStore.color("primaryStrong"))
        .padding(.vertical, 8)
    }

    private var motionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Motion")
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(themeStore.color("muted"))
                .textCase(.uppercase)
            VStack(spacing: 0) {
                motionToggle("Animations", isOn: Binding(
                    get: { themeStore.motionEnabled }, set: { themeStore.motionEnabled = $0 }))
                Divider().overlay(themeStore.color("line"))
                motionToggle("Petal effects", isOn: Binding(
                    get: { themeStore.petalsEnabled }, set: { themeStore.petalsEnabled = $0 }))
                    .disabled(!themeStore.motionEnabled)
                Divider().overlay(themeStore.color("line"))
                motionToggle("Shimmer & outline", isOn: Binding(
                    get: { themeStore.shimmerEnabled }, set: { themeStore.shimmerEnabled = $0 }))
                    .disabled(!themeStore.motionEnabled)
            }
            .padding(.horizontal, 14)
            .background(themeStore.color("surface"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func motionToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(bloomBody(14))
                .foregroundStyle(themeStore.color("text"))
        }
        .tint(themeStore.color("primaryStrong"))
        .padding(.vertical, 10)
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Presets")
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(themeStore.color("muted"))
                .textCase(.uppercase)
            HStack(spacing: 12) {
                ForEach(themeStore.presetNames, id: \.self) { name in
                    presetSwatch(name)
                }
            }
        }
    }

    private func presetSwatch(_ name: String) -> some View {
        let isActive = themeStore.spec.name == name
        return Button {
            themeStore.setPreset(name)
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(ThemeEditorView.previewColor(for: name))
                    .frame(width: 44, height: 44)
                    // Permanent hairline so the midnight swatch never vanishes
                    // into a dark page; the active ring draws on top of it.
                    .overlay(Circle().stroke(themeStore.color("line"), lineWidth: 1))
                    .overlay(
                        Circle().stroke(isActive ? themeStore.color("primaryStrong") : .clear, lineWidth: 3)
                    )
                Text(name.capitalized)
                    .font(bloomBody(11, weight: .medium))
                    .foregroundStyle(themeStore.color("text"))
            }
        }
        .buttonStyle(.plain)
    }

    private var editableTokensSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Custom colors")
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(themeStore.color("muted"))
                .textCase(.uppercase)
            VStack(spacing: 0) {
                ForEach(ThemeStore.editableTokenOrder, id: \.self) { token in
                    tokenRow(token)
                    if token != ThemeStore.editableTokenOrder.last {
                        Divider().overlay(themeStore.color("line"))
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(themeStore.color("surface"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func tokenRow(_ token: String) -> some View {
        ColorPicker(selection: colorBinding(for: token), supportsOpacity: false) {
            Text(ThemeStore.editableTokenLabel(token))
                .font(bloomBody(14))
                .foregroundStyle(themeStore.color("text"))
        }
        .padding(.vertical, 10)
    }

    private func colorBinding(for token: String) -> Binding<Color> {
        Binding(
            get: { themeStore.color(token) },
            set: { newColor in
                if let hex = newColor.toHex() {
                    themeStore.setCustomToken(token, hex: hex)
                    if themeStore.spec.name != "custom" {
                        themeStore.setPreset("custom")
                        themeStore.setCustomToken(token, hex: hex)
                    }
                }
            }
        )
    }

    private static func previewColor(for name: String) -> Color {
        switch name {
        case "rose": return Color(hex: "#E56A87") ?? .pink
        case "peony": return Color(hex: "#E15BA4") ?? .pink
        case "soft": return Color(hex: "#EE9DBB") ?? .pink
        case "midnight": return Color(hex: "#1B1118") ?? .black
        default: return Color(hex: "#F06FA7") ?? .pink
        }
    }
}

extension Color {
    func toHex() -> String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        // Clamp: extended sRGB (wide-gamut picks) can yield components outside 0...1.
        func channel(_ v: CGFloat) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", channel(r), channel(g), channel(b))
    }
}
