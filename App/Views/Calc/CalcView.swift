import SwiftUI
import BloomCore

struct CalcView: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(CalcStore.self) private var calcStore
    @Environment(HistoryStore.self) private var historyStore
    @State private var activeSolver: MathSolver?

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
        .overlay {
            // Confetti celebration on an easter-egg result — flies across the whole pad.
            if themeStore.petalsOn {
                PetalBurstView(trigger: calcStore.eggEpoch, originX: 0.5, originY: 0.3)
                    .allowsHitTesting(false)
            }
        }
        .sheet(item: $activeSolver) { solver in
            MathSolverSheet(solver: solver) { value in
                calcStore.sendValue(value)
            }
        }
    }

    private var displayArea: some View {
        HStack(alignment: .top, spacing: 12) {
            calcLog
            VStack(alignment: .trailing, spacing: 4) {
                Text(calcStore.expression)
                    .font(bloomNumber(56, weight: .medium))   // the big "what is typed" line
                    .foregroundStyle(themeStore.color("muted"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)   // long expressions shrink instead of clipping
                RollingNumberText(
                    text: calcStore.display,
                    font: bloomNumber(58, weight: .semibold),
                    color: themeStore.color("text")
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.35)   // long results shrink instead of clipping
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(themeStore.color("surfaceSoft"))
        .clipShape(RoundedRectangle(cornerRadius: themeStore.radius))
        .overlay {
            // The encircle traces the display card each time a result lands, and
            // again whenever the tab remounts (RootView's .id(selectedTab)) —
            // the same greet-on-arrival trace the kitchen pill and QR use.
            if themeStore.shimmerOn {
                EncircleOutline(
                    trigger: calcStore.resultEpoch,
                    cornerRadius: themeStore.radius,
                    lineWidth: 1.5,
                    settleOpacity: 0.4
                )
            }
        }
        .background {
            // Bloom sits behind the opaque card and is left unclipped, so petals
            // only show where they rise past the card's edges.
            if themeStore.petalsOn {
                ResultBloomView(trigger: calcStore.resultEpoch)
                    .padding(-34)
                    .allowsHitTesting(false)
            }
        }
    }

    // Left-side running log: last 3 completed calcs, oldest→newest top-to-bottom.
    // Sourced from history (calc entries carry extra["tokens"] + value); tapping a
    // line replays it via the same replayTokens the recycle sheet uses. Fixed width
    // so the result column never reflows between the empty and populated states.
    private var calcLog: some View {
        let recent = historyStore.entries
            .filter { $0.type == "calc" && !($0.extra["tokens"] ?? "").isEmpty }
            .prefix(3)
            .reversed()
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(recent)) { entry in
                Button {
                    if let tokens = entry.extra["tokens"] {
                        calcStore.replayTokens(tokens)
                    }
                } label: {
                    Text("\(entry.extra["tokens"] ?? "") = \(entry.value)")
                        .font(bloomBody(11))
                        .foregroundStyle(themeStore.color("muted"))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 110, alignment: .leading)   // reserved even when empty
    }

    private var memoryBar: some View {
        HStack(spacing: 10) {
            modeLabelButton
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    modeContent
                }
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeStore.color("surface2"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var modeLabelButton: some View {
        Button {
            calcStore.cycleMathMode()
        } label: {
            HStack(spacing: 4) {
                Text(calcStore.mathMode.title)
                    .font(bloomBody(10, weight: .semibold))
                    .foregroundStyle(themeStore.color("muted"))
                if calcStore.mathMode == .memory, calcStore.memoryValue != 0 {
                    Circle()
                        .fill(themeStore.color("primaryStrong"))
                        .frame(width: 6, height: 6)
                }
                Image(systemName: "chevron.forward")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(themeStore.color("primaryStrong"))
            }
        }
        .buttonStyle(.plain)
        .fixedSize()
    }

    @ViewBuilder
    private var modeContent: some View {
        switch calcStore.mathMode {
        case .memory:
            memoryControls
        case .complex:
            complexStrip
        case .trig:
            trigStrip
        }
    }

    private var memoryControls: some View {
        HStack(spacing: 8) {
            memoryButton("MC")
            memoryButton("MR")
            memoryButton("M-")
            memoryButton("M+")
            Text(Formatters.plain(calcStore.memoryValue))
                .font(bloomBody(12, weight: .medium))
                .foregroundStyle(themeStore.color("text"))
                .lineLimit(1)
                .frame(minWidth: 40, alignment: .trailing)
        }
    }

    private var complexStrip: some View {
        HStack(spacing: 8) {
            mathChip("x·y") { activeSolver = .xy }
            mathChip("Quad") { activeSolver = .quadratic }
            mathChip("Pyth") { activeSolver = .pythagorean }
            mathChip("Frac") { activeSolver = .fraction }
            angleChip
        }
    }

    private var trigStrip: some View {
        HStack(spacing: 8) {
            ForEach(TrigFunction.allCases, id: \.self) { fn in
                mathChip(fn.rawValue) { calcStore.applyTrig(fn) }
            }
            angleChip
        }
    }

    private var angleChip: some View {
        Button {
            calcStore.toggleAngleMode()
        } label: {
            Text(calcStore.angleMode.shortLabel)
                .font(bloomBody(11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 999).fill(themeStore.color("primaryStrong")))
        }
        .buttonStyle(.plain)
    }

    private func mathChip(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(bloomBody(11, weight: .semibold))
                .foregroundStyle(themeStore.color("primaryStrong"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 999).fill(themeStore.color("surfaceSoft")))
        }
        .buttonStyle(.plain)
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
