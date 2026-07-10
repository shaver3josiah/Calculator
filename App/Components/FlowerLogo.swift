import SwiftUI

struct FlowerLogo: View {
    @Environment(ThemeStore.self) private var themeStore
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            RosePetalRing(count: 8, lengthScale: 0.44, widthScale: 0.30, offsetFraction: 0.52)
                .fill(themeStore.color("primary").opacity(0.55))
                .rotationEffect(.degrees(6))
            RosePetalRing(count: 7, lengthScale: 0.34, widthScale: 0.24, offsetFraction: 0.50)
                .fill(themeStore.color("primary"))
                .rotationEffect(.degrees(-9))
            RosePetalRing(count: 6, lengthScale: 0.24, widthScale: 0.18, offsetFraction: 0.46)
                .fill(themeStore.color("primaryStrong"))
                .rotationEffect(.degrees(15))
            Circle()
                .fill(themeStore.color("flowerCenter"))
                .frame(width: size * 0.22, height: size * 0.22)
        }
        .frame(width: size, height: size)
    }
}

private struct RosePetalRing: Shape {
    var count: Int
    var lengthScale: CGFloat
    var widthScale: CGFloat
    var offsetFraction: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let petalLength = rect.width * lengthScale
        let petalWidth = rect.width * widthScale
        let step = 360.0 / Double(count)

        for i in 0..<count {
            let angle = Angle(degrees: Double(i) * step)
            let petalCenter = CGPoint(
                x: center.x + petalLength * offsetFraction * cos(angle.radians - .pi / 2),
                y: center.y + petalLength * offsetFraction * sin(angle.radians - .pi / 2)
            )
            let petalRect = CGRect(
                x: petalCenter.x - petalWidth / 2,
                y: petalCenter.y - petalLength / 2,
                width: petalWidth,
                height: petalLength
            )
            let petalPath = Path(ellipseIn: petalRect)
            let rotated = petalPath.applying(
                CGAffineTransform(translationX: petalCenter.x, y: petalCenter.y)
                    .rotated(by: angle.radians)
                    .translatedBy(x: -petalCenter.x, y: -petalCenter.y)
            )
            path.addPath(rotated)
        }
        return path
    }
}

// MARK: - Interactive header flower (single-tap twirl + glitter, double-tap → verse mode)

/// The header's flower wrapped with its signature tap delight. Leaves `FlowerLogo`
/// itself pure so every other call site keeps compiling unchanged.
///
/// Single tap → a spring twirl (overshoots ~360–540° and settles), a quick scale
/// pop, and a one-shot glitter burst. Double tap → `onDoubleTap` (verse mode).
/// Gesture order matters: the `count: 2` tap is attached *before* the `count: 1`
/// tap, so SwiftUI holds the single recognizer until the double fails — a genuine
/// double-tap fires only `onDoubleTap`, never the single handler.
struct TappableFlower: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(SoundStore.self) private var sound
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var size: CGFloat = 38
    var onDoubleTap: () -> Void = {}

    @State private var spin: Double = 0
    @State private var pop: CGFloat = 1
    @State private var pulse = false
    @State private var glitter = 0

    var body: some View {
        ZStack {
            FlowerLogo(size: size)
                .rotationEffect(.degrees(spin))
                .scaleEffect(pop)
                .opacity(pulse ? 0.55 : 1)
            if theme.petalsOn && !reduceMotion {
                GlitterBurst(trigger: glitter, size: size)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onDoubleTap() }
        .onTapGesture(count: 1) { singleTap() }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Hannah's flower")
    }

    private func singleTap() {
        sound.play("easteregg")
        guard theme.petalsOn, !reduceMotion else {
            // Reduce Motion / petals off: a gentle opacity pulse, no spin or glitter.
            withAnimation(.easeInOut(duration: 0.3)) { pulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) { pulse = false }
            }
            return
        }
        glitter += 1
        let turn = Double(Int.random(in: 360...540))
        withAnimation(.spring(response: 0.9, dampingFraction: 0.65)) {
            spin += turn
            pop = 1.15
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
            pop = 1
        }
    }
}

/// One-shot glitter emitter. On each `trigger` bump it flings ~16 tiny gold/pink
/// sparks (a mix of 4-point twinkles and dots) radially from the flower's center
/// with an eased-out throw, then fades + drifts them down and self-clears after
/// ~1.2s. Individually-animated lightweight views (never more than 16 alive),
/// seeded off `trigger` so no two bursts match. Mount behind `theme.petalsOn`.
struct GlitterBurst: View {
    @Environment(ThemeStore.self) private var theme
    let trigger: Int
    var size: CGFloat = 38

    @State private var sparks: [GlitterSpark] = []
    @State private var flung = false
    @State private var faded = false
    @State private var generation = 0

    private static let colorTokens = ["flowerCenter", "primary", "white"]

    var body: some View {
        ZStack {
            ForEach(sparks) { spark in
                sparkView(spark)
                    .frame(width: spark.size, height: spark.size)
                    .rotationEffect(.degrees(flung ? spark.spin : 0))
                    .offset(
                        x: flung ? cos(spark.angle) * spark.distance : 0,
                        y: flung ? sin(spark.angle) * spark.distance + spark.fall : 0
                    )
                    .scaleEffect(flung ? 0.5 : 1)
                    .opacity(faded ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in burst() }
    }

    @ViewBuilder
    private func sparkView(_ spark: GlitterSpark) -> some View {
        let fill = color(spark.colorIndex)
        if spark.isStar {
            FourPointStar().fill(fill)
        } else {
            Circle().fill(fill)
        }
    }

    private func color(_ index: Int) -> Color {
        let token = Self.colorTokens[index % Self.colorTokens.count]
        return token == "white" ? .white : theme.color(token)
    }

    private func burst() {
        guard trigger > 0 else { return }
        sparks = GlitterSpark.make(count: 16, size: size, seed: trigger)
        flung = false
        faded = false
        generation += 1
        let expected = generation
        // Establish the rest state for one frame, then throw + fade.
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.95)) { flung = true }
            withAnimation(.easeIn(duration: 0.55).delay(0.5)) { faded = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if generation == expected { sparks = [] }
        }
    }
}

private struct GlitterSpark: Identifiable {
    let id: Int
    let angle: Double
    let distance: CGFloat
    let fall: CGFloat
    let size: CGFloat
    let spin: Double
    let colorIndex: Int
    let isStar: Bool

    static func make(count: Int, size: CGFloat, seed: Int) -> [GlitterSpark] {
        (0..<count).map { i in
            var rng = SeededGenerator(seed: seed &* 2971 &+ i &* 131 &+ 17)
            let jitter = Double.random(in: -0.3...0.3, using: &rng)
            let angle = (Double(i) / Double(count)) * 2 * .pi + jitter
            let star = Double.random(in: 0...1, using: &rng) < 0.55
            return GlitterSpark(
                id: i,
                angle: angle,
                distance: size * CGFloat.random(in: 0.85...1.7, using: &rng),
                fall: size * CGFloat.random(in: 0.12...0.32, using: &rng),
                size: star ? CGFloat.random(in: 4...7, using: &rng)
                           : CGFloat.random(in: 3...5, using: &rng),
                spin: Double.random(in: -220...220, using: &rng),
                colorIndex: Int.random(in: 0...2, using: &rng),
                isStar: star
            )
        }
    }
}

/// A thin concave four-pointed twinkle used for the glitter sparks.
private struct FourPointStar: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let w = r * 0.28   // concave waist → thin sparkle arms
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - r))
        p.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: CGPoint(x: c.x + w, y: c.y - w))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: CGPoint(x: c.x + w, y: c.y + w))
        p.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: CGPoint(x: c.x - w, y: c.y + w))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: CGPoint(x: c.x - w, y: c.y - w))
        p.closeSubpath()
        return p
    }
}
