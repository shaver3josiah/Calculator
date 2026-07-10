import SwiftUI
import BloomCore
import UIKit

struct VisualizePanel: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var store
    @Environment(ListsStore.self) private var lists
    @Environment(SoundStore.self) private var sound
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var rawText = ""
    @State private var scale: Double = 1.0
    @State private var customScale = ""
    @State private var useCustom = false
    @State private var parsed: [ParsedIngredient] = []
    @State private var failed: [String] = []
    @State private var placements: [Placement] = []
    @FocusState private var textFocused: Bool

    // Pinch-zoom / pan state for the countertop. `*Base` hold the value committed
    // at the end of the last gesture so the next one composes on top of it.
    @State private var zoom: CGFloat = 1
    @State private var zoomBase: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var panBase: CGSize = .zero

    private static let counterHeight: CGFloat = 300

    private static let artNames: Set<String> = [
        "croissant", "cupcake", "honeypot", "hotbev", "shortcake", "teacup"
    ]

    /// Volume / weight / vague-portion measures. Everything measured in one of
    /// these is *bulk* (one labeled graphic); units NOT in this set — nil or a
    /// discrete-portion word like "clove"/"slice" — are *countable*.
    private static let measureUnits: Set<String> = [
        "tsp", "tbsp", "cup", "oz", "fl oz", "lb", "g", "kg", "mL", "L",
        "pinch", "can", "pkg", "stick"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Paste recipe text", text: $rawText, prompt: Text("Paste recipe text").foregroundColor(theme.color("muted")), axis: .vertical)
                .font(bloomBody(14))
                .foregroundStyle(theme.color("text"))
                .lineLimit(4...8)
                .focused($textFocused)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surface")))

            scalePicker

            Button {
                parseText()
            } label: {
                Text("Visualize")
                    .font(bloomBody(14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 999).fill(theme.color("primaryStrong")))
                    .foregroundStyle(.white)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            finishPicker
            countertop

            if !parsed.isEmpty || !failed.isEmpty {
                Button("Add to shopping list") {
                    addAllToList()
                }
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(theme.color("primaryStrong"))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
        .onChange(of: scale) { _, _ in placements = buildPlacements() }
    }

    // MARK: - Scale picker

    private var scalePicker: some View {
        HStack(spacing: 10) {
            ForEach([0.5, 1.0, 2.0], id: \.self) { value in
                Button {
                    useCustom = false
                    scale = value
                } label: {
                    Text(scaleLabel(value))
                        .font(bloomBody(13, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 999)
                                .fill(!useCustom && scale == value ? theme.color("primaryStrong") : theme.color("surfaceSoft"))
                        )
                        .foregroundStyle(!useCustom && scale == value ? .white : theme.color("text"))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            TextField("custom", text: $customScale, prompt: Text("custom").foregroundColor(theme.color("muted")))
                .keyboardType(.decimalPad)
                .font(bloomBody(13))
                .foregroundStyle(theme.color("text"))
                .frame(width: 56)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.color("surfaceSoft")))
                .onChange(of: customScale) { _, newValue in
                    if let v = Double(newValue), v > 0 {
                        useCustom = true
                        scale = v
                    }
                }
        }
    }

    private func scaleLabel(_ value: Double) -> String {
        value == 0.5 ? "0.5x" : value == 1.0 ? "1x" : "2x"
    }

    // MARK: - Finish picker

    private var finishPicker: some View {
        HStack(spacing: 8) {
            finishChip(.marble, "Marble")
            finishChip(.wood, "Wood")
            Spacer()
        }
    }

    private func finishChip(_ finish: CounterFinish, _ label: String) -> some View {
        let active = store.counterFinish == finish
        return Button {
            store.counterFinish = finish
            sound.play("tap1")
        } label: {
            Text(label)
                .font(bloomBody(12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(active ? theme.color("primaryStrong") : theme.color("surfaceSoft")))
                .foregroundStyle(active ? .white : theme.color("text"))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Countertop (surface + mise en place + zoom)

    private var countertop: some View {
        GeometryReader { geo in
            ZStack {
                CounterFinishView(finish: store.counterFinish)
                if placements.isEmpty {
                    Text("Paste a recipe and tap Visualize to set the counter.")
                        .font(bloomBody(12))
                        .foregroundStyle(theme.color("muted"))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 220)
                } else {
                    miseView(placements, in: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            // scaleEffect + offset are visual-only; the trailing fixed .frame
            // re-establishes the container box so .clipShape crops the zoomed
            // content to the counter rather than letting it spill into the page.
            .scaleEffect(zoom, anchor: .center)
            .offset(pan)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            .contentShape(Rectangle())
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(theme.color("line"), lineWidth: 1)
            )
            // Pinch never conflicts with the outer ScrollView (two fingers).
            .gesture(magnifyGesture(size: geo.size))
            // ponytail: pan drag is disabled at zoom 1 (mask .subviews) so the
            // one-finger scroll of the page wins; it only claims the touch once
            // zoomed in. Cleanest way to not fight the out-of-scope ScrollView.
            .highPriorityGesture(panGesture(size: geo.size), including: zoom > 1 ? .all : .subviews)
            .onTapGesture(count: 2) { resetZoom() }
        }
        .frame(height: Self.counterHeight)
    }

    private func miseView(_ items: [Placement], in size: CGSize) -> some View {
        let cols = max(1, min(items.count, Int(size.width / 96)))
        let rows = max(1, Int((Double(items.count) / Double(cols)).rounded(.up)))
        let cellW = size.width / CGFloat(cols)
        let cellH = min((size.height - 20) / CGFloat(rows), 120)
        let contentH = cellH * CGFloat(rows)
        let topInset = max(14, (size.height - contentH) / 2)
        let artBase = min(max(min(cellW, cellH) * 0.42, 24), 46)

        return ZStack {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let col = index % cols
                let row = index / cols
                let j = jitter(index)
                placementView(item, artSize: artBase, rotation: j.rot)
                    .position(
                        x: cellW * (CGFloat(col) + 0.5) + j.x,
                        y: topInset + cellH * (CGFloat(row) + 0.5) + j.y
                    )
            }
        }
    }

    /// Seeded hand-placed jitter for a mise-en-place item: ±4pt offset, ±6°
    /// rotation. Seeded by index so items never shuffle between renders.
    private func jitter(_ index: Int) -> (x: CGFloat, y: CGFloat, rot: Double) {
        var rng = SeededGenerator(seed: index &* 2999 &+ 17)
        return (
            CGFloat(Double.random(in: -4...4, using: &rng)),
            CGFloat(Double.random(in: -4...4, using: &rng)),
            Double.random(in: -6...6, using: &rng)
        )
    }

    private func placementView(_ item: Placement, artSize: CGFloat, rotation: Double) -> some View {
        VStack(spacing: 4) {
            clusterView(item, base: artSize)
                .rotationEffect(.degrees(rotation))
            captionView(item)
        }
    }

    /// One graphic per copy, arranged in a compact pile (≤12 drawn), with a
    /// "×N" badge when the real count runs past the 12-copy display cap.
    private func clusterView(_ item: Placement, base: CGFloat) -> some View {
        let display = min(item.count, 12)
        let per = display <= 3 ? display : Int(Double(display).squareRoot().rounded(.up))
        let rowCount = max(1, Int((Double(display) / Double(max(1, per))).rounded(.up)))
        let copySize = display <= 1 ? base : max(16, base * (display <= 4 ? 0.66 : 0.5))

        return VStack(spacing: 1) {
            ForEach(0..<rowCount, id: \.self) { r in
                HStack(spacing: 1) {
                    ForEach(0..<max(1, per), id: \.self) { c in
                        let k = r * per + c
                        if k < display {
                            artUnit(glyph: item.glyph, artKey: item.artKey, size: copySize)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if item.count > 12 {
                Text("×\(item.count)")
                    .font(bloomBody(9, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(theme.color("primaryStrong")))
                    .foregroundStyle(.white)
                    .offset(x: 6, y: -4)
            }
        }
    }

    private func captionView(_ item: Placement) -> some View {
        VStack(spacing: 0) {
            Text(item.name)
                .font(bloomBody(11, weight: .semibold))
                .foregroundStyle(theme.color("text"))
                .lineLimit(1)
            if !item.qtyLabel.isEmpty {
                Text(item.qtyLabel)
                    .font(bloomBody(10))
                    .foregroundStyle(theme.color("deep"))
                    .lineLimit(1)
            }
        }
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.75)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .frame(maxWidth: 104)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.color("surface").opacity(0.86))
        )
        .shadow(color: Color.black.opacity(0.12), radius: 2, y: 1)
    }

    @ViewBuilder
    private func artUnit(glyph: String, artKey: String?, size: CGFloat) -> some View {
        if let key = artKey, Self.artNames.contains(key), let uiImage = Self.loadArt(key) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Text(glyph)
                .font(.system(size: size))
        }
    }

    // MARK: - Zoom / pan gestures

    private func magnifyGesture(size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = min(max(zoomBase * value.magnification, 1), 3)
                pan = clampPan(pan, size: size)
            }
            .onEnded { _ in
                zoomBase = zoom
                if zoom <= 1.001 {
                    pan = .zero
                    panBase = .zero
                } else {
                    panBase = pan
                }
            }
    }

    private func panGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard zoom > 1 else { return }
                let raw = CGSize(
                    width: panBase.width + value.translation.width,
                    height: panBase.height + value.translation.height
                )
                pan = clampPan(raw, size: size)
            }
            .onEnded { _ in panBase = pan }
    }

    /// Keep the scaled content from being dragged fully off the counter. With a
    /// centered scaleEffect the content overhangs by (zoom-1)*dimension/2 a side.
    private func clampPan(_ p: CGSize, size: CGSize) -> CGSize {
        let maxX = (zoom - 1) * size.width / 2
        let maxY = (zoom - 1) * size.height / 2
        return CGSize(
            width: min(max(p.width, -maxX), maxX),
            height: min(max(p.height, -maxY), maxY)
        )
    }

    private func resetZoom() {
        if theme.motionEnabled && !reduceMotion {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                zoom = 1; zoomBase = 1; pan = .zero; panBase = .zero
            }
        } else {
            zoom = 1; zoomBase = 1; pan = .zero; panBase = .zero
        }
    }

    // MARK: - Placement building

    private struct Placement: Identifiable {
        let id: Int
        let glyph: String
        let artKey: String?
        let name: String
        let qtyLabel: String
        let count: Int
    }

    private func buildPlacements() -> [Placement] {
        var out: [Placement] = []
        var idx = 0
        for ing in parsed {
            let scaled = RecipeParse.scale(ing, by: scale)
            let food = FoodLibrary.match(ing.name)
            out.append(Placement(
                id: idx,
                glyph: food?.glyph ?? "🥣",
                artKey: food?.artKey,
                name: food?.name ?? scaled.name.capitalized,
                qtyLabel: scaledLabel(scaled),
                count: Self.copyCount(for: scaled)
            ))
            idx += 1
        }
        for line in failed {
            out.append(Placement(
                id: idx,
                glyph: "🧺",
                artKey: nil,
                name: line.capitalized,
                qtyLabel: "as written",
                count: 1
            ))
            idx += 1
        }
        return out
    }

    /// Countability rule for the mise-en-place counter.
    ///
    /// Returns how many copies of an ingredient's graphic to lay on the counter.
    /// An ingredient is *countable* — one graphic per unit — when it denotes a
    /// discrete whole thing: a whole-ish quantity ≥ 1 whose unit is either absent
    /// ("2 eggs") or a discrete-portion word ("3 cloves", "2 slices"), and NOT a
    /// volume/weight measure. Anything measured in a cup, spoon, or on a scale
    /// (cups, tsp, tbsp, grams, mL, pinches, cans, packages, sticks) is *bulk*
    /// and returns 1: two flour piles would misread as "2 cups", so bulk shows a
    /// single labeled graphic instead. Non-whole quantities (1½) are treated as
    /// bulk too. The returned count is uncapped; the view draws at most 12 copies
    /// and badges any remainder as "×N".
    private static func copyCount(for ing: ParsedIngredient) -> Int {
        guard let qty = ing.qty, qty >= 0.5 else { return 1 }
        if let unit = ing.unit, measureUnits.contains(unit) { return 1 }
        // Only duplicate near-whole counts; 1.5 eggs → a single labeled graphic.
        guard abs(qty - qty.rounded()) <= 0.2 else { return 1 }
        return max(1, Int(qty.rounded()))
    }

    private func scaledLabel(_ ing: ParsedIngredient) -> String {
        guard let qty = ing.qty else { return ing.unit ?? "" }
        let qtyText = RecipeParse.fmtQty(qty)
        guard let unit = ing.unit else { return qtyText }
        return "\(qtyText) \(unit)"
    }

    // MARK: - Art loading

    private static var artCache: [String: UIImage] = [:]

    private static func loadArt(_ key: String) -> UIImage? {
        if let cached = artCache[key] {
            return cached
        }
        guard let resolved = resolveArt(key) else {
            return nil
        }
        artCache[key] = resolved
        return resolved
    }

    private static func resolveArt(_ key: String) -> UIImage? {
        if let named = UIImage(named: key) {
            return named
        }
        let subdirectories = ["FoodArt/png", "Resources/FoodArt/png"]
        for subdirectory in subdirectories {
            if let url = Bundle.main.url(forResource: key, withExtension: "png", subdirectory: subdirectory),
               let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                return image
            }
        }
        if let url = Bundle.main.url(forResource: key, withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        return nil
    }

    // MARK: - Actions

    private func parseText() {
        textFocused = false
        let lines = rawText.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        var good: [ParsedIngredient] = []
        var bad: [String] = []
        for line in lines {
            if let ing = RecipeParse.parseLine(line) {
                good.append(ing)
            } else {
                bad.append(line)
            }
        }
        parsed = good
        failed = bad
        placements = buildPlacements()
        resetZoom()
        sound.play("tap1")
        theme.triggerCurtain()
    }

    private func addAllToList() {
        for ing in parsed {
            let scaled = RecipeParse.scale(ing, by: scale)
            let rawQty = scaled.qty ?? 1
            let roundedQty = (rawQty * 100).rounded() / 100
            let displayName = foldedIngredientName(scaled)
            lists.addIngredient(name: displayName, qty: roundedQty)
        }
        for line in failed {
            lists.addIngredient(name: line, qty: 1)
        }
        sound.play("success")
    }

    private func foldedIngredientName(_ ing: ParsedIngredient) -> String {
        guard let unit = ing.unit else {
            return ing.name
        }
        return "\(ing.name) (\(unit))"
    }
}

// MARK: - Procedural counter finishes

/// Static, seeded procedural counter surfaces drawn with a single Canvas each.
/// Seeds are fixed constants so veins/planks/knots never shift between renders.
private struct CounterFinishView: View {
    let finish: CounterFinish

    var body: some View {
        Canvas { context, size in
            switch finish {
            case .marble: Self.drawMarble(context, size)
            case .wood: Self.drawWood(context, size)
            }
        }
    }

    private static func drawMarble(_ ctx: GraphicsContext, _ size: CGSize) {
        let full = Path(CGRect(origin: .zero, size: size))
        // Warm-white base.
        ctx.fill(full, with: .color(Color(red: 0.972, green: 0.965, blue: 0.952)))

        // 3 faint meandering gray veins.
        for v in 0..<3 {
            var rng = SeededGenerator(seed: v &* 8231 &+ 101)
            var path = Path()
            let startY = size.height * CGFloat(Double.random(in: 0.15...0.85, using: &rng))
            path.move(to: CGPoint(x: -12, y: startY))
            let segs = 4
            var x: CGFloat = 0
            for s in 0..<segs {
                let nx = size.width * CGFloat(s + 1) / CGFloat(segs) + 12
                let ny = size.height * CGFloat(Double.random(in: 0.1...0.9, using: &rng))
                let cx = (x + nx) / 2
                let cy = size.height * CGFloat(Double.random(in: 0.1...0.9, using: &rng))
                path.addQuadCurve(to: CGPoint(x: nx, y: ny), control: CGPoint(x: cx, y: cy))
                x = nx
            }
            ctx.stroke(
                path,
                with: .color(Color(white: 0.45).opacity(0.14 + 0.03 * Double(v))),
                lineWidth: CGFloat(1.6 - 0.3 * Double(v))
            )
        }

        // Subtle top-leading white sheen.
        let sheen = Gradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0)])
        ctx.fill(full, with: .linearGradient(
            sheen,
            startPoint: .zero,
            endPoint: CGPoint(x: size.width * 0.7, y: size.height * 0.7)
        ))
    }

    private static func drawWood(_ ctx: GraphicsContext, _ size: CGSize) {
        let bands = 5
        let bandH = size.height / CGFloat(bands)
        let toneA = Color(red: 0.56, green: 0.40, blue: 0.24)
        let toneB = Color(red: 0.50, green: 0.35, blue: 0.20)
        let seam = Color(red: 0.30, green: 0.19, blue: 0.10).opacity(0.5)

        for b in 0..<bands {
            let rect = CGRect(x: 0, y: CGFloat(b) * bandH, width: size.width, height: bandH)
            ctx.fill(Path(rect), with: .color(b % 2 == 0 ? toneA : toneB))
            if b > 0 {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: CGFloat(b) * bandH))
                line.addLine(to: CGPoint(x: size.width, y: CGFloat(b) * bandH))
                ctx.stroke(line, with: .color(seam), lineWidth: 1.5)
            }
        }

        // A couple of seeded knots at low opacity.
        for k in 0..<2 {
            var rng = SeededGenerator(seed: k &* 5407 &+ 61)
            let kx = size.width * CGFloat(Double.random(in: 0.2...0.8, using: &rng))
            let ky = size.height * CGFloat(Double.random(in: 0.15...0.85, using: &rng))
            let rw = CGFloat(Double.random(in: 10...18, using: &rng))
            let rh = rw * 0.7
            let ring = Path(ellipseIn: CGRect(x: kx - rw, y: ky - rh, width: rw * 2, height: rh * 2))
            ctx.stroke(ring, with: .color(Color(red: 0.28, green: 0.17, blue: 0.09).opacity(0.35)), lineWidth: 2)
            let core = Path(ellipseIn: CGRect(x: kx - rw * 0.5, y: ky - rh * 0.5, width: rw, height: rh))
            ctx.fill(core, with: .color(Color(red: 0.30, green: 0.19, blue: 0.10).opacity(0.18)))
        }

        // Gentle top sheen.
        let sheen = Gradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0)])
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            sheen,
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: size.height * 0.5)
        ))
    }
}
