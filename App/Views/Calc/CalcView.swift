import SwiftUI
import BloomCore

struct CalcView: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(CalcStore.self) private var calcStore

    private let keypadRows: [[KeyDef]] = [
        [KeyDef(label: "AC", key: "C", event: "clear", accent: true),
         KeyDef(label: "+/−", key: "±", event: "operator", accent: true),
         KeyDef(label: "%", key: "%", event: "operator", accent: true),
         KeyDef(label: "÷", key: "/", event: "operator", accent: true)],
        [KeyDef(label: "7", key: "7", event: "tap"),
         KeyDef(label: "8", key: "8", event: "tap"),
         KeyDef(label: "9", key: "9", event: "tap"),
         KeyDef(label: "×", key: "*", event: "operator", accent: true)],
        [KeyDef(label: "4", key: "4", event: "tap"),
         KeyDef(label: "5", key: "5", event: "tap"),
         KeyDef(label: "6", key: "6", event: "tap"),
         KeyDef(label: "−", key: "-", event: "operator", accent: true)],
        [KeyDef(label: "1", key: "1", event: "tap"),
         KeyDef(label: "2", key: "2", event: "tap"),
         KeyDef(label: "3", key: "3", event: "tap"),
         KeyDef(label: "+", key: "+", event: "operator", accent: true)],
        [KeyDef(label: "0", key: "0", event: "tap"),
         KeyDef(label: ".", key: ".", event: "tap"),
         KeyDef(label: "⌫", key: "⌫", event: "clear"),
         KeyDef(label: "=", key: "=", event: "equals", strong: true)]
    ]

    var body: some View {
        VStack(spacing: 16) {
            displayArea
            memoryBar
            keypad
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var displayArea: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(calcStore.expression)
                .font(bloomBody(14))
                .foregroundStyle(themeStore.color("muted"))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)
            RollingNumberText(
                text: calcStore.display,
                font: bloomNumber(44, weight: .medium),
                color: themeStore.color("text")
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(themeStore.color("surfaceSoft"))
        .clipShape(RoundedRectangle(cornerRadius: themeStore.radius))
    }

    private var memoryBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Text("MEMORY")
                    .font(bloomBody(10, weight: .semibold))
                    .foregroundStyle(themeStore.color("muted"))
                if calcStore.memoryValue != 0 {
                    Circle()
                        .fill(themeStore.color("primaryStrong"))
                        .frame(width: 6, height: 6)
                }
            }
            Spacer()
            memoryButton("MC")
            memoryButton("MR")
            memoryButton("M-")
            memoryButton("M+")
            Text(Formatters.plain(calcStore.memoryValue))
                .font(bloomBody(12, weight: .medium))
                .foregroundStyle(themeStore.color("text"))
                .lineLimit(1)
                .frame(minWidth: 44, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeStore.color("surface2"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func memoryButton(_ label: String) -> some View {
        Button {
            calcStore.press(label)
        } label: {
            Text(label)
                .font(bloomBody(11, weight: .semibold))
                .foregroundStyle(themeStore.color("primaryStrong"))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }

    private var keypad: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(keypadRows.flatMap { $0 }) { def in
                KeypadButton(
                    label: def.label,
                    soundEvent: def.event,
                    isAccent: def.accent,
                    isStrong: def.strong
                ) {
                    calcStore.press(def.key)
                }
            }
        }
    }
}

private struct KeyDef: Identifiable {
    let label: String
    let key: String
    let event: String
    var accent: Bool = false
    var strong: Bool = false
    var id: String { key + label }
}
