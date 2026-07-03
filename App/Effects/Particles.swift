import SwiftUI

struct ParticleSpec {
    var seedTime: Double
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var rotation: Double
    var rotationSpeed: Double
    var size: Double
    var colorIndex: Int
    var lifetime: Double
}

private func makeSparkle(index: Int, baseTime: Double) -> ParticleSpec {
    var rng = SeededGenerator(seed: index &* 7919 &+ 13)
    return ParticleSpec(
        seedTime: baseTime + Double.random(in: 0...2.4, using: &rng),
        x: Double.random(in: 0...1, using: &rng),
        y: Double.random(in: 0.16...0.84, using: &rng),
        vx: Double.random(in: -0.35...0.35, using: &rng),
        vy: Double.random(in: -1.1...(-0.3), using: &rng),
        rotation: Double.random(in: 0...360, using: &rng),
        rotationSpeed: Double.random(in: -170...170, using: &rng),
        size: Double.random(in: 6...15, using: &rng),
        colorIndex: index,
        lifetime: Double.random(in: 1.3...2.5, using: &rng)
    )
}

private func makePetal(index: Int, baseTime: Double, originX: Double, originY: Double) -> ParticleSpec {
    var rng = SeededGenerator(seed: index &* 4451 &+ 31)
    let angle = Double(index) / 18.0 * 2 * .pi + Double.random(in: -0.2...0.2, using: &rng)
    return ParticleSpec(
        seedTime: baseTime,
        x: originX,
        y: originY,
        vx: cos(angle) * Double.random(in: 0.5...1, using: &rng),
        vy: sin(angle) * Double.random(in: 0.5...1, using: &rng),
        rotation: Double.random(in: 0...360, using: &rng),
        rotationSpeed: Double.random(in: -220...220, using: &rng),
        size: Double.random(in: 8...15, using: &rng),
        colorIndex: index,
        lifetime: Double.random(in: 0.7...1.15, using: &rng)
    )
}

private func makeRainDrop(index: Int, baseTime: Double) -> ParticleSpec {
    var rng = SeededGenerator(seed: index &* 2609 &+ 5)
    return ParticleSpec(
        seedTime: baseTime - Double.random(in: 0...5, using: &rng),
        x: Double.random(in: 0...1, using: &rng),
        y: 0,
        vx: 0,
        vy: 0,
        rotation: Double.random(in: 0...360, using: &rng),
        rotationSpeed: Double.random(in: -55...55, using: &rng),
        size: Double.random(in: 10...19, using: &rng),
        colorIndex: index,
        lifetime: Double.random(in: 3.6...6.2, using: &rng)
    )
}

private func drawPetal(_ ctx: inout GraphicsContext, spec: ParticleSpec, x: Double, y: Double, rotationDeg: Double, alpha: Double, color: Color) {
    var layer = ctx
    layer.opacity = alpha
    layer.translateBy(x: x, y: y)
    layer.rotate(by: .degrees(rotationDeg))
    let rect = CGRect(x: -spec.size / 2, y: -spec.size / 3, width: spec.size, height: spec.size * 0.66)
    layer.fill(Path(ellipseIn: rect), with: .color(color))
}

struct SparkleFieldView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let colorTokens: [String]

    private static let poolSize = 24
    @State private var pool: [ParticleSpec] = []
    @State private var baseTime: Double = 0

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            TimelineView(.animation) { context in
                Canvas { ctx, size in
                    let now = context.date.timeIntervalSinceReferenceDate
                    for spec in pool {
                        let cycle = spec.lifetime + 0.6
                        let elapsed = (now - spec.seedTime).truncatingRemainder(dividingBy: cycle)
                        guard elapsed >= 0, elapsed < spec.lifetime else { continue }
                        let t = elapsed / spec.lifetime
                        let px = spec.x * size.width + spec.vx * elapsed * 60
                        let py = spec.y * size.height + spec.vy * elapsed * 60
                        let alpha = 1.0 - t
                        let rot = spec.rotation + spec.rotationSpeed * elapsed
                        let token = colorTokens[spec.colorIndex % max(colorTokens.count, 1)]
                        drawPetal(&ctx, spec: spec, x: px, y: py, rotationDeg: rot, alpha: alpha, color: theme.color(token))
                    }
                }
            }
            .onAppear(perform: seed)
        }
    }

    private func seed() {
        guard pool.isEmpty else { return }
        let now = Date.timeIntervalSinceReferenceDate
        baseTime = now
        pool = (0..<Self.poolSize).map { makeSparkle(index: $0, baseTime: now) }
    }
}

struct PetalBurstView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let trigger: Int
    let originX: Double
    let originY: Double

    private static let count = 18
    @State private var pool: [ParticleSpec] = []

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            TimelineView(.animation) { context in
                Canvas { ctx, size in
                    let now = context.date.timeIntervalSinceReferenceDate
                    for spec in pool {
                        let age = now - spec.seedTime
                        guard age >= 0, age < spec.lifetime else { continue }
                        let t = age / spec.lifetime
                        let ease = 1 - pow(1 - t, 2)
                        let px = spec.x * size.width + spec.vx * ease * 140
                        let py = spec.y * size.height + spec.vy * ease * 140 + 60 * t * t
                        let alpha = 1.0 - t
                        let rot = spec.rotation + spec.rotationSpeed * age
                        let token = ["primary", "primaryStrong", "flowerCenter"][spec.colorIndex % 3]
                        drawPetal(&ctx, spec: spec, x: px, y: py, rotationDeg: rot, alpha: alpha, color: theme.color(token))
                    }
                }
            }
            .onChange(of: trigger) { _, _ in spawnBurst() }
            .onAppear(perform: spawnBurst)
        }
    }

    private func spawnBurst() {
        let now = Date.timeIntervalSinceReferenceDate
        pool = (0..<Self.count).map { makePetal(index: $0, baseTime: now, originX: originX, originY: originY) }
    }
}

struct PetalRainView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let count = 22
    @State private var pool: [ParticleSpec] = []

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            TimelineView(.animation) { context in
                Canvas { ctx, size in
                    let now = context.date.timeIntervalSinceReferenceDate
                    for spec in pool {
                        let elapsed = (now - spec.seedTime).truncatingRemainder(dividingBy: spec.lifetime)
                        let clamped = elapsed < 0 ? elapsed + spec.lifetime : elapsed
                        let t = clamped / spec.lifetime
                        let px = spec.x * size.width + sin(t * 6 + spec.rotation) * 18
                        let py = t * (size.height + 40) - 20
                        let rot = spec.rotation + spec.rotationSpeed * clamped
                        let token = ["primary", "primaryStrong"][spec.colorIndex % 2]
                        drawPetal(&ctx, spec: spec, x: px, y: py, rotationDeg: rot, alpha: 0.85, color: theme.color(token))
                    }
                }
            }
            .onAppear(perform: seed)
        }
    }

    private func seed() {
        guard pool.isEmpty else { return }
        let now = Date.timeIntervalSinceReferenceDate
        pool = (0..<Self.count).map { makeRainDrop(index: $0, baseTime: now) }
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
