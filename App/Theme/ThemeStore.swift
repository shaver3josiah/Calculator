import SwiftUI
import BloomCore

@Observable
final class ThemeStore {
    var spec: ThemeSpec
    var presetNames: [String] = ["cherry", "rose", "peony", "soft"]
    var radius: CGFloat = 22
    var showTabLabels: Bool = true {
        didSet { JSONStore.shared.set(.tabLabels, showTabLabels) }
    }

    // Motion preferences + first-visit tracking. Kept here because ThemeStore is
    // already injected into every view that needs to gate an animation.
    var motionEnabled: Bool = true { didSet { persistMotion() } }
    var petalsEnabled: Bool = true { didSet { persistMotion() } }
    var shimmerEnabled: Bool = true { didSet { persistMotion() } }
    private var seenTabs: Set<String> = []
    var curtainEpoch: Int = 0   // transient; bumped to fire the petal curtain

    /// Effective gates — a sub-effect is on only when the master switch is too.
    var petalsOn: Bool { motionEnabled && petalsEnabled }
    var shimmerOn: Bool { motionEnabled && shimmerEnabled }

    /// True the first time (ever) a tab is opened; marks it seen and persists.
    func firstVisit(_ tabRaw: String) -> Bool {
        guard !seenTabs.contains(tabRaw) else { return false }
        seenTabs.insert(tabRaw)
        persistMotion()
        return true
    }

    /// Fire the top-down petal curtain (no-op when petals are disabled).
    func triggerCurtain() {
        guard petalsOn else { return }
        curtainEpoch += 1
    }

    private var customTokens: [String: String]

    init() {
        let savedPresetName = JSONStore.shared.get(.theme, as: String.self) ?? "cherry"
        let savedCustom = JSONStore.shared.get(.custom, as: [String: String].self)
        let tokens = savedCustom ?? ThemeStore.presetTokens(for: "cherry")
        customTokens = tokens

        let initialSpec: ThemeSpec
        if savedPresetName == "custom" {
            initialSpec = ThemeSpec(name: "custom", tokens: tokens)
        } else {
            initialSpec = ThemeSpec(name: savedPresetName, tokens: ThemeStore.presetTokens(for: savedPresetName))
        }
        spec = initialSpec
        radius = ThemeStore.parseRadius(initialSpec.tokens["radius"])
        showTabLabels = JSONStore.shared.get(.tabLabels, as: Bool.self) ?? true

        let motion = JSONStore.shared.get(.motion, as: MotionPrefs.self)
        seenTabs = Set(motion?.seenTabs ?? [])   // before the prefs — their didSet persists seenTabs
        motionEnabled = motion?.motion ?? true
        petalsEnabled = motion?.petals ?? true
        shimmerEnabled = motion?.shimmer ?? true
    }

    private func persistMotion() {
        JSONStore.shared.set(.motion, MotionPrefs(
            motion: motionEnabled, petals: petalsEnabled,
            shimmer: shimmerEnabled, seenTabs: Array(seenTabs)
        ))
    }

    func color(_ token: String) -> Color {
        guard let hex = spec.tokens[token] else { return .clear }
        return Color(hex: hex) ?? .clear
    }

    func setPreset(_ name: String) {
        if name == "custom" {
            spec = ThemeSpec(name: "custom", tokens: customTokens)
        } else {
            spec = ThemeSpec(name: name, tokens: ThemeStore.presetTokens(for: name))
        }
        radius = ThemeStore.parseRadius(spec.tokens["radius"])
        JSONStore.shared.set(.theme, spec.name)
    }

    func setCustomToken(_ token: String, hex: String) {
        customTokens[token] = hex
        JSONStore.shared.set(.custom, customTokens)
        if spec.name == "custom" {
            spec = ThemeSpec(name: "custom", tokens: customTokens)
        }
    }

    static let editableTokenOrder: [String] = [
        "bg", "surface", "surfaceSoft", "surface2", "primary", "primaryStrong",
        "deep", "text", "muted", "line", "flowerCenter", "good"
    ]

    static func editableTokenLabel(_ token: String) -> String {
        switch token {
        case "bg": return "Page background"
        case "surface": return "Card surface"
        case "surfaceSoft": return "Keys & panels"
        case "surface2": return "Accent panels"
        case "primary": return "Flower petals"
        case "primaryStrong": return "Strong accent"
        case "deep": return "Headlines"
        case "text": return "Main text"
        case "muted": return "Soft text"
        case "line": return "Borders"
        case "flowerCenter": return "Flower center"
        case "good": return "Growth color"
        default: return token
        }
    }

    private static func parseRadius(_ raw: String?) -> CGFloat {
        guard let raw, let value = Double(raw) else { return 22 }
        return CGFloat(value)
    }

    private static func presetTokens(for name: String) -> [String: String] {
        let base: [String: String] = [
            "shadow": "rgba(176,27,88,.16)",
            "ripple": "rgba(255,255,255,.55)",
            "sh1": "0 1px 2px rgba(66,21,39,.10),0 1px 1px rgba(66,21,39,.06)",
            "radius": "22",
            "good": "#17703B",
            "surface": "#FFFFFF"
        ]
        switch name {
        case "rose":
            return base.merging([
                "bg": "#FDF2F1",
                "surfaceSoft": "#FADDE0",
                "surface2": "#FCEBEC",
                "primary": "#E56A87",
                "primaryStrong": "#CE3E63",
                "deep": "#A11C41",
                "text": "#431B23",
                "muted": "#835862",
                "line": "#F1CBD1",
                "flowerCenter": "#FFC878",
                "shadow": "rgba(161,28,65,.16)"
            ]) { _, new in new }
        case "peony":
            return base.merging([
                "bg": "#FDF1F8",
                "surfaceSoft": "#F9DCEC",
                "surface2": "#FCEAF3",
                "primary": "#E15BA4",
                "primaryStrong": "#C22E85",
                "deep": "#8E1560",
                "text": "#3B1030",
                "muted": "#815571",
                "line": "#EFC8E0",
                "flowerCenter": "#FFC966",
                "shadow": "rgba(142,21,96,.16)"
            ]) { _, new in new }
        case "soft":
            return base.merging([
                "bg": "#FEF7F9",
                "surfaceSoft": "#FBE7ED",
                "surface2": "#FDF1F4",
                "primary": "#EE9DBB",
                "primaryStrong": "#DB6E93",
                "deep": "#B04266",
                "text": "#4A2533",
                "muted": "#82606D",
                "line": "#F4D8E1",
                "flowerCenter": "#FFD488",
                "shadow": "rgba(176,66,102,.14)"
            ]) { _, new in new }
        default:
            return base.merging([
                "bg": "#FDF2F7",
                "surfaceSoft": "#FBE4EE",
                "surface2": "#FDF0F5",
                "primary": "#F06FA7",
                "primaryStrong": "#E2417F",
                "deep": "#B01B58",
                "text": "#421527",
                "muted": "#885B6D",
                "line": "#F2CEDF",
                "flowerCenter": "#FFC966",
                "shadow": "rgba(176,27,88,.16)"
            ]) { _, new in new }
        }
    }
}

private struct MotionPrefs: Codable {
    var motion: Bool
    var petals: Bool
    var shimmer: Bool
    var seenTabs: [String]
}

extension Color {
    init?(hex: String) {
        var normalized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasPrefix("#") {
            normalized.removeFirst()
        }
        guard normalized.count == 6, let value = UInt64(normalized, radix: 16) else {
            return nil
        }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
