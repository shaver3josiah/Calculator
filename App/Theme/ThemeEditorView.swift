import SwiftUI
import UIKit
import BloomCore

struct ThemeEditorView: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    presetSection
                    displaySection
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

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Display")
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(themeStore.color("muted"))
                .textCase(.uppercase)
            Toggle(isOn: Binding(get: { themeStore.showTabLabels }, set: { themeStore.showTabLabels = $0 })) {
                Text("Show tab labels")
                    .font(bloomBody(14))
                    .foregroundStyle(themeStore.color("text"))
            }
            .tint(themeStore.color("primaryStrong"))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(themeStore.color("surface"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
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
        default: return Color(hex: "#F06FA7") ?? .pink
        }
    }
}

extension Color {
    func toHex() -> String? {
        let uiColor = UIColor(self)
        guard let components = uiColor.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Int(round(components[0] * 255))
        let g = Int(round(components[1] * 255))
        let b = Int(round(components[2] * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
