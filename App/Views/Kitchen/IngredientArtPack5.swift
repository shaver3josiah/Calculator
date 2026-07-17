import SwiftUI

// Pack 5 — the produce basket, same "storybook grocery" language as Pack 1.
// Each struct draws in normalized Canvas space (fractions of `size`) with no
// fixed frames, so the caller can size it anywhere 40→120pt.
// Flat fills + strokes only: no gradients, text, SF Symbols, or app deps.

// MARK: - Shared palette + helpers

private enum Pack5Palette {
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.42)
    static let ink = Color(red: 0.33, green: 0.20, blue: 0.16)
    static let leaf = Color(red: 0.36, green: 0.58, blue: 0.32)
    static let leafDeep = Color(red: 0.26, green: 0.44, blue: 0.26)
    static let red = Color(red: 0.85, green: 0.28, blue: 0.28)
    static let orange = Color(red: 0.95, green: 0.58, blue: 0.24)
    static let yellow = Color(red: 0.96, green: 0.83, blue: 0.4)
    static let earth = Color(red: 0.78, green: 0.62, blue: 0.44)

    static var stroke: Color { ink.opacity(0.35) }

    /// Outline width: 2.8% of the smaller dimension, floored at 1.2pt.
    static func line(_ s: CGSize) -> CGFloat { max(1.2, min(s.width, s.height) * 0.028) }

    /// Simple pointed leaf: two quad curves meeting at a tip.
    static func leafPath(from base: CGPoint, to tip: CGPoint, belly: CGFloat) -> Path {
        let mid = CGPoint(x: (base.x + tip.x) / 2, y: (base.y + tip.y) / 2)
        let dx = tip.x - base.x, dy = tip.y - base.y
        let n = CGPoint(x: mid.x - dy * belly, y: mid.y + dx * belly)
        let n2 = CGPoint(x: mid.x + dy * belly, y: mid.y - dx * belly)
        var p = Path()
        p.move(to: base)
        p.addQuadCurve(to: tip, control: n)
        p.addQuadCurve(to: base, control: n2)
        return p
    }
}

// MARK: - 1. Apple — round body, stem, leaf

struct AppleArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            let body = Path(ellipseIn: CGRect(x: w * 0.22, y: h * 0.28, width: w * 0.56, height: h * 0.56))
            ctx.fill(body, with: .color(Pack5Palette.red))
            ctx.stroke(body, with: .color(Pack5Palette.stroke), lineWidth: lw)
            // dimple at the top
            var dimple = Path()
            dimple.move(to: CGPoint(x: w * 0.42, y: h * 0.3))
            dimple.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.3), control: CGPoint(x: w * 0.5, y: h * 0.36))
            ctx.stroke(dimple, with: .color(Pack5Palette.stroke), lineWidth: lw * 0.7)
            // stem
            var stem = Path()
            stem.move(to: CGPoint(x: w * 0.5, y: h * 0.3))
            stem.addQuadCurve(to: CGPoint(x: w * 0.54, y: h * 0.14), control: CGPoint(x: w * 0.5, y: h * 0.2))
            ctx.stroke(stem, with: .color(Pack5Palette.ink.opacity(0.6)), lineWidth: lw)
            // leaf
            let leaf = Pack5Palette.leafPath(from: CGPoint(x: w * 0.54, y: h * 0.2),
                                             to: CGPoint(x: w * 0.72, y: h * 0.12), belly: 0.28)
            ctx.fill(leaf, with: .color(Pack5Palette.leaf))
            // charm: gold sheen dot
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.32, y: h * 0.38, width: w * 0.07, height: w * 0.07)),
                     with: .color(Pack5Palette.gold.opacity(0.8)))
        }
    }
}

// MARK: - 2. Bananas — pair of curved crescents joined at the crown

struct BananaArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            // each banana: thick curved stroke-shaped fill via two arcs
            func banana(offset: CGFloat) {
                var p = Path()
                p.move(to: CGPoint(x: w * (0.3 + offset), y: h * 0.2))
                p.addQuadCurve(to: CGPoint(x: w * (0.68 + offset), y: h * 0.78),
                               control: CGPoint(x: w * (0.18 + offset), y: h * 0.72))
                p.addQuadCurve(to: CGPoint(x: w * (0.38 + offset), y: h * 0.24),
                               control: CGPoint(x: w * (0.32 + offset), y: h * 0.84))
                p.closeSubpath()
                ctx.fill(p, with: .color(Pack5Palette.yellow))
                ctx.stroke(p, with: .color(Pack5Palette.stroke), lineWidth: lw)
            }
            banana(offset: 0.0)
            banana(offset: 0.14)
            // shared crown stub at the top
            let crown = Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.14, width: w * 0.2, height: h * 0.1),
                             cornerSize: CGSize(width: w * 0.02, height: w * 0.02))
            ctx.fill(crown, with: .color(Pack5Palette.earth))
            ctx.stroke(crown, with: .color(Pack5Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold freckle
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.42, y: h * 0.55, width: w * 0.05, height: w * 0.05)),
                     with: .color(Pack5Palette.gold))
        }
    }
}

// MARK: - 3. Strawberry — heart-ish berry, green cap, seed specks

struct StrawberryArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            var berry = Path()
            berry.move(to: CGPoint(x: w * 0.24, y: h * 0.36))
            berry.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.88), control: CGPoint(x: w * 0.24, y: h * 0.76))
            berry.addQuadCurve(to: CGPoint(x: w * 0.76, y: h * 0.36), control: CGPoint(x: w * 0.76, y: h * 0.76))
            berry.addQuadCurve(to: CGPoint(x: w * 0.24, y: h * 0.36), control: CGPoint(x: w * 0.5, y: h * 0.26))
            ctx.fill(berry, with: .color(Pack5Palette.red))
            ctx.stroke(berry, with: .color(Pack5Palette.stroke), lineWidth: lw)

            // green cap: three pointed sepals
            for i in 0..<3 {
                let x0 = w * (0.34 + 0.12 * CGFloat(i))
                let sepal = Pack5Palette.leafPath(from: CGPoint(x: x0, y: h * 0.32),
                                                  to: CGPoint(x: x0 + w * 0.04, y: h * 0.16), belly: 0.3)
                ctx.fill(sepal, with: .color(Pack5Palette.leaf))
            }
            // seed specks
            let seeds: [(CGFloat, CGFloat)] = [(0.4, 0.48), (0.56, 0.46), (0.48, 0.58), (0.38, 0.64), (0.58, 0.62)]
            for (fx, fy) in seeds {
                ctx.fill(Path(ellipseIn: CGRect(x: w * fx, y: h * fy, width: w * 0.035, height: h * 0.05)),
                         with: .color(Pack5Palette.cream))
            }
            // charm: one gold seed
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.48, y: h * 0.7, width: w * 0.035, height: h * 0.05)),
                     with: .color(Pack5Palette.gold))
        }
    }
}

// MARK: - 4. Blueberries — bowl of dots

struct BlueberriesArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            let blue = Color(red: 0.32, green: 0.4, blue: 0.66)
            // berries heaped above the rim
            let pts: [(CGFloat, CGFloat)] = [(0.34, 0.36), (0.48, 0.3), (0.62, 0.36), (0.41, 0.44), (0.55, 0.44)]
            for (fx, fy) in pts {
                let b = Path(ellipseIn: CGRect(x: w * fx - w * 0.07, y: h * fy - w * 0.07, width: w * 0.14, height: w * 0.14))
                ctx.fill(b, with: .color(blue))
                ctx.stroke(b, with: .color(Pack5Palette.stroke), lineWidth: lw * 0.7)
            }
            // bowl: half-ellipse
            var bowl = Path()
            bowl.move(to: CGPoint(x: w * 0.18, y: h * 0.48))
            bowl.addLine(to: CGPoint(x: w * 0.82, y: h * 0.48))
            bowl.addQuadCurve(to: CGPoint(x: w * 0.18, y: h * 0.48), control: CGPoint(x: w * 0.5, y: h * 1.02))
            bowl.closeSubpath()
            ctx.fill(bowl, with: .color(Pack5Palette.cream))
            ctx.stroke(bowl, with: .color(Pack5Palette.stroke), lineWidth: lw)
            // charm: gold band on the bowl
            var band = Path()
            band.move(to: CGPoint(x: w * 0.26, y: h * 0.6))
            band.addQuadCurve(to: CGPoint(x: w * 0.74, y: h * 0.6), control: CGPoint(x: w * 0.5, y: h * 0.68))
            ctx.stroke(band, with: .color(Pack5Palette.gold), lineWidth: lw)
        }
    }
}

// MARK: - 5. Raspberries — cluster of bumpy drupelets + leaf

struct RaspberriesArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            let pink = Color(red: 0.82, green: 0.3, blue: 0.45)
            // one raspberry = rounded body + drupelet dots
            func raspberry(cx: CGFloat, cy: CGFloat, s: CGFloat) {
                let body = Path(ellipseIn: CGRect(x: w * cx - w * s / 2, y: h * cy - h * s / 2,
                                                  width: w * s, height: h * s * 1.05))
                ctx.fill(body, with: .color(pink))
                ctx.stroke(body, with: .color(Pack5Palette.stroke), lineWidth: lw)
                let dots: [(CGFloat, CGFloat)] = [(-0.12, -0.08), (0.12, -0.08), (0, 0.05), (-0.1, 0.16), (0.1, 0.16)]
                for (dx, dy) in dots {
                    ctx.fill(Path(ellipseIn: CGRect(x: w * (cx + dx * s / 0.4) - w * 0.02,
                                                    y: h * (cy + dy * s / 0.4) - w * 0.02,
                                                    width: w * 0.04, height: w * 0.04)),
                             with: .color(.white.opacity(0.35)))
                }
            }
            raspberry(cx: 0.36, cy: 0.5, s: 0.32)
            raspberry(cx: 0.66, cy: 0.62, s: 0.28)
            // leaf on the bigger one
            let leaf = Pack5Palette.leafPath(from: CGPoint(x: w * 0.36, y: h * 0.32),
                                             to: CGPoint(x: w * 0.52, y: h * 0.18), belly: 0.3)
            ctx.fill(leaf, with: .color(Pack5Palette.leaf))
            // charm: gold drupelet
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.33, y: h * 0.46, width: w * 0.04, height: w * 0.04)),
                     with: .color(Pack5Palette.gold))
        }
    }
}

// MARK: - 6. Orange — round with pore texture + leaf

struct OrangeArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            let body = Path(ellipseIn: CGRect(x: w * 0.22, y: h * 0.26, width: w * 0.56, height: h * 0.56))
            ctx.fill(body, with: .color(Pack5Palette.orange))
            ctx.stroke(body, with: .color(Pack5Palette.stroke), lineWidth: lw)
            // pore specks
            let pores: [(CGFloat, CGFloat)] = [(0.36, 0.44), (0.5, 0.38), (0.6, 0.5), (0.42, 0.58), (0.56, 0.64)]
            for (fx, fy) in pores {
                ctx.fill(Path(ellipseIn: CGRect(x: w * fx, y: h * fy, width: w * 0.025, height: w * 0.025)),
                         with: .color(Pack5Palette.ink.opacity(0.2)))
            }
            // stem nub + leaf
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.47, y: h * 0.22, width: w * 0.06, height: w * 0.05)),
                     with: .color(Pack5Palette.leafDeep))
            let leaf = Pack5Palette.leafPath(from: CGPoint(x: w * 0.52, y: h * 0.24),
                                             to: CGPoint(x: w * 0.72, y: h * 0.14), belly: 0.28)
            ctx.fill(leaf, with: .color(Pack5Palette.leaf))
            ctx.stroke(leaf, with: .color(Pack5Palette.stroke), lineWidth: lw * 0.6)
            // charm: gold sheen dot
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.33, y: h * 0.35, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack5Palette.gold.opacity(0.8)))
        }
    }
}

// MARK: - 7. Lime — whole + cut half with segment lines

struct LimeArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            let rind = Color(red: 0.42, green: 0.62, blue: 0.3)
            let flesh = Color(red: 0.78, green: 0.88, blue: 0.55)
            // whole lime behind
            let whole = Path(ellipseIn: CGRect(x: w * 0.14, y: h * 0.3, width: w * 0.42, height: h * 0.4))
            ctx.fill(whole, with: .color(rind))
            ctx.stroke(whole, with: .color(Pack5Palette.stroke), lineWidth: lw)

            // cut half in front: rind ring + flesh + segments
            let cx = w * 0.62, cy = h * 0.58, r = w * 0.24
            let outer = Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
            ctx.fill(outer, with: .color(rind))
            ctx.stroke(outer, with: .color(Pack5Palette.stroke), lineWidth: lw)
            let inner = Path(ellipseIn: CGRect(x: cx - r * 0.82, y: cy - r * 0.82, width: r * 1.64, height: r * 1.64))
            ctx.fill(inner, with: .color(flesh))
            var segs = Path()
            for i in 0..<6 {
                let a = CGFloat(i) * .pi / 3
                segs.move(to: CGPoint(x: cx, y: cy))
                segs.addLine(to: CGPoint(x: cx + cos(a) * r * 0.78, y: cy + sin(a) * r * 0.78))
            }
            ctx.stroke(segs, with: .color(.white.opacity(0.8)), lineWidth: lw * 0.8)
            // charm: gold pip
            ctx.fill(Path(ellipseIn: CGRect(x: cx + r * 0.25, y: cy - r * 0.45, width: w * 0.04, height: w * 0.04)),
                     with: .color(Pack5Palette.gold))
        }
    }
}

// MARK: - 8. Avocado — halved with pit

struct AvocadoArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            let skin = Color(red: 0.24, green: 0.36, blue: 0.2)
            let flesh = Color(red: 0.82, green: 0.87, blue: 0.6)
            let pit = Color(red: 0.62, green: 0.42, blue: 0.26)
            // pear-shaped half: narrow top, round bottom
            func avoBody(cx: CGFloat, scale: CGFloat) -> Path {
                var p = Path()
                p.move(to: CGPoint(x: w * cx, y: h * 0.14))
                p.addQuadCurve(to: CGPoint(x: w * (cx - 0.19 * scale), y: h * 0.62),
                               control: CGPoint(x: w * (cx - 0.13 * scale), y: h * 0.28))
                p.addQuadCurve(to: CGPoint(x: w * (cx + 0.19 * scale), y: h * 0.62),
                               control: CGPoint(x: w * cx, y: h * 1.02))
                p.addQuadCurve(to: CGPoint(x: w * cx, y: h * 0.14),
                               control: CGPoint(x: w * (cx + 0.13 * scale), y: h * 0.28))
                return p
            }
            // whole half (skin only) behind, flesh half in front
            let back = avoBody(cx: 0.32, scale: 0.9)
            ctx.fill(back, with: .color(skin))
            ctx.stroke(back, with: .color(Pack5Palette.stroke), lineWidth: lw)
            let front = avoBody(cx: 0.64, scale: 1.0)
            ctx.fill(front, with: .color(skin))
            ctx.stroke(front, with: .color(Pack5Palette.stroke), lineWidth: lw)
            // flesh inset, then the pit
            var fleshP = Path()
            fleshP.move(to: CGPoint(x: w * 0.64, y: h * 0.2))
            fleshP.addQuadCurve(to: CGPoint(x: w * 0.49, y: h * 0.62), control: CGPoint(x: w * 0.53, y: h * 0.3))
            fleshP.addQuadCurve(to: CGPoint(x: w * 0.79, y: h * 0.62), control: CGPoint(x: w * 0.64, y: h * 0.94))
            fleshP.addQuadCurve(to: CGPoint(x: w * 0.64, y: h * 0.2), control: CGPoint(x: w * 0.75, y: h * 0.3))
            ctx.fill(fleshP, with: .color(flesh))
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.55, y: h * 0.5, width: w * 0.18, height: w * 0.18)),
                     with: .color(pit))
            // charm: gold glint on the pit
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.58, y: h * 0.53, width: w * 0.045, height: w * 0.045)),
                     with: .color(Pack5Palette.gold))
        }
    }
}

// MARK: - 9. Carrot — tapered root with fronds

struct CarrotArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            // tapered root, tilted
            var root = Path()
            root.move(to: CGPoint(x: w * 0.34, y: h * 0.3))
            root.addQuadCurve(to: CGPoint(x: w * 0.74, y: h * 0.84), control: CGPoint(x: w * 0.4, y: h * 0.66))
            root.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.24), control: CGPoint(x: w * 0.72, y: h * 0.5))
            root.closeSubpath()
            ctx.fill(root, with: .color(Pack5Palette.orange))
            ctx.stroke(root, with: .color(Pack5Palette.stroke), lineWidth: lw)
            // rib lines
            var ribs = Path()
            ribs.move(to: CGPoint(x: w * 0.44, y: h * 0.42))
            ribs.addLine(to: CGPoint(x: w * 0.54, y: h * 0.4))
            ribs.move(to: CGPoint(x: w * 0.52, y: h * 0.56))
            ribs.addLine(to: CGPoint(x: w * 0.62, y: h * 0.54))
            ctx.stroke(ribs, with: .color(Pack5Palette.ink.opacity(0.25)), lineWidth: lw * 0.7)
            // fronds: three green strokes fanning up
            let tips: [(CGFloat, CGFloat)] = [(0.24, 0.08), (0.4, 0.04), (0.54, 0.1)]
            for (fx, fy) in tips {
                var f = Path()
                f.move(to: CGPoint(x: w * 0.45, y: h * 0.28))
                f.addQuadCurve(to: CGPoint(x: w * fx, y: h * fy), control: CGPoint(x: w * (fx + 0.08), y: h * 0.2))
                ctx.stroke(f, with: .color(Pack5Palette.leaf), lineWidth: lw * 1.2)
            }
            // charm: gold speck at the frond base
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.43, y: h * 0.25, width: w * 0.05, height: w * 0.05)),
                     with: .color(Pack5Palette.gold))
        }
    }
}

// MARK: - 10. Celery — bundle of stalks with leafy tops

struct CeleryArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            let pale = Color(red: 0.72, green: 0.82, blue: 0.5)
            // three stalks: slim rounded rects fanning slightly
            let stalks: [(CGFloat, CGFloat)] = [(0.32, 0.3), (0.45, 0.24), (0.58, 0.3)]
            for (fx, fy) in stalks {
                let s = Path(roundedRect: CGRect(x: w * fx, y: h * fy, width: w * 0.12, height: h * 0.58),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
                ctx.fill(s, with: .color(pale))
                ctx.stroke(s, with: .color(Pack5Palette.stroke), lineWidth: lw)
                // rib groove
                var groove = Path()
                groove.move(to: CGPoint(x: w * (fx + 0.06), y: h * (fy + 0.06)))
                groove.addLine(to: CGPoint(x: w * (fx + 0.06), y: h * (fy + 0.5)))
                ctx.stroke(groove, with: .color(Pack5Palette.leaf.opacity(0.4)), lineWidth: lw * 0.7)
                // leafy top
                let leaf = Pack5Palette.leafPath(from: CGPoint(x: w * (fx + 0.06), y: h * fy),
                                                 to: CGPoint(x: w * (fx + 0.1), y: h * (fy - 0.14)), belly: 0.4)
                ctx.fill(leaf, with: .color(Pack5Palette.leaf))
            }
            // charm: gold tie band around the bundle
            ctx.fill(Path(CGRect(x: w * 0.3, y: h * 0.66, width: w * 0.42, height: h * 0.05)),
                     with: .color(Pack5Palette.gold))
        }
    }
}

// MARK: - 11. Potato — two spuds with eye dimples

struct PotatoArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            let spud1 = Path(ellipseIn: CGRect(x: w * 0.14, y: h * 0.3, width: w * 0.46, height: h * 0.36))
            let spud2 = Path(ellipseIn: CGRect(x: w * 0.42, y: h * 0.52, width: w * 0.42, height: h * 0.32))
            for s in [spud1, spud2] {
                ctx.fill(s, with: .color(Pack5Palette.earth))
                ctx.stroke(s, with: .color(Pack5Palette.stroke), lineWidth: lw)
            }
            // eye dimples: short curved ticks
            let eyes: [(CGFloat, CGFloat)] = [(0.28, 0.42), (0.44, 0.38), (0.36, 0.54), (0.56, 0.62), (0.68, 0.68)]
            for (fx, fy) in eyes {
                var e = Path()
                e.move(to: CGPoint(x: w * fx, y: h * fy))
                e.addQuadCurve(to: CGPoint(x: w * (fx + 0.05), y: h * fy),
                               control: CGPoint(x: w * (fx + 0.025), y: h * (fy + 0.03)))
                ctx.stroke(e, with: .color(Pack5Palette.ink.opacity(0.3)), lineWidth: lw * 0.7)
            }
            // charm: gold speck
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.5, y: h * 0.46, width: w * 0.05, height: w * 0.05)),
                     with: .color(Pack5Palette.gold))
        }
    }
}

// MARK: - 12. Sweet potato — long tapered spud, warm copper skin

struct SweetPotatoArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            let copper = Color(red: 0.72, green: 0.4, blue: 0.3)
            // long tapered body on a diagonal, pointed both ends
            var body = Path()
            body.move(to: CGPoint(x: w * 0.16, y: h * 0.34))
            body.addQuadCurve(to: CGPoint(x: w * 0.84, y: h * 0.66), control: CGPoint(x: w * 0.42, y: h * 0.78))
            body.addQuadCurve(to: CGPoint(x: w * 0.16, y: h * 0.34), control: CGPoint(x: w * 0.58, y: h * 0.22))
            ctx.fill(body, with: .color(copper))
            ctx.stroke(body, with: .color(Pack5Palette.stroke), lineWidth: lw)
            // lengthwise skin lines
            var lines = Path()
            lines.move(to: CGPoint(x: w * 0.3, y: h * 0.42))
            lines.addQuadCurve(to: CGPoint(x: w * 0.66, y: h * 0.56), control: CGPoint(x: w * 0.48, y: h * 0.44))
            lines.move(to: CGPoint(x: w * 0.34, y: h * 0.54))
            lines.addQuadCurve(to: CGPoint(x: w * 0.62, y: h * 0.64), control: CGPoint(x: w * 0.48, y: h * 0.62))
            ctx.stroke(lines, with: .color(Pack5Palette.ink.opacity(0.2)), lineWidth: lw * 0.7)
            // charm: gold sheen dot
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.4, y: h * 0.44, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack5Palette.gold.opacity(0.8)))
        }
    }
}

// MARK: - 13. Bell pepper — lobed body, stem cap

struct BellPepperArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            // body: wide rounded form with two lobe grooves
            var body = Path()
            body.move(to: CGPoint(x: w * 0.5, y: h * 0.26))
            body.addQuadCurve(to: CGPoint(x: w * 0.22, y: h * 0.56), control: CGPoint(x: w * 0.2, y: h * 0.26))
            body.addQuadCurve(to: CGPoint(x: w * 0.38, y: h * 0.86), control: CGPoint(x: w * 0.22, y: h * 0.82))
            body.addQuadCurve(to: CGPoint(x: w * 0.62, y: h * 0.86), control: CGPoint(x: w * 0.5, y: h * 0.92))
            body.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.56), control: CGPoint(x: w * 0.78, y: h * 0.82))
            body.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.26), control: CGPoint(x: w * 0.8, y: h * 0.26))
            ctx.fill(body, with: .color(Pack5Palette.red))
            ctx.stroke(body, with: .color(Pack5Palette.stroke), lineWidth: lw)
            // lobe grooves
            var grooves = Path()
            grooves.move(to: CGPoint(x: w * 0.4, y: h * 0.3))
            grooves.addQuadCurve(to: CGPoint(x: w * 0.38, y: h * 0.84), control: CGPoint(x: w * 0.34, y: h * 0.56))
            grooves.move(to: CGPoint(x: w * 0.6, y: h * 0.3))
            grooves.addQuadCurve(to: CGPoint(x: w * 0.62, y: h * 0.84), control: CGPoint(x: w * 0.66, y: h * 0.56))
            ctx.stroke(grooves, with: .color(Pack5Palette.ink.opacity(0.2)), lineWidth: lw * 0.7)
            // stem cap
            var stem = Path()
            stem.move(to: CGPoint(x: w * 0.46, y: h * 0.28))
            stem.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.1), control: CGPoint(x: w * 0.44, y: h * 0.16))
            ctx.stroke(stem, with: .color(Pack5Palette.leafDeep), lineWidth: lw * 1.6)
            // charm: gold sheen dot
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.32, y: h * 0.42, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack5Palette.gold.opacity(0.8)))
        }
    }
}

// MARK: - 14. Cucumber — whole + slice

struct CucumberArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            let rind = Color(red: 0.3, green: 0.5, blue: 0.28)
            let flesh = Color(red: 0.86, green: 0.92, blue: 0.72)
            // whole cuke: long rounded capsule on a diagonal
            var cuke = Path()
            cuke.move(to: CGPoint(x: w * 0.14, y: h * 0.34))
            cuke.addQuadCurve(to: CGPoint(x: w * 0.7, y: h * 0.58), control: CGPoint(x: w * 0.38, y: h * 0.6))
            cuke.addQuadCurve(to: CGPoint(x: w * 0.66, y: h * 0.44), control: CGPoint(x: w * 0.78, y: h * 0.5))
            cuke.addQuadCurve(to: CGPoint(x: w * 0.14, y: h * 0.34), control: CGPoint(x: w * 0.4, y: h * 0.34))
            ctx.fill(cuke, with: .color(rind))
            ctx.stroke(cuke, with: .color(Pack5Palette.stroke), lineWidth: lw)

            // slice: rind ring + pale flesh + seed dots
            let cx = w * 0.66, cy = h * 0.72, r = w * 0.17
            let outer = Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
            ctx.fill(outer, with: .color(rind))
            ctx.stroke(outer, with: .color(Pack5Palette.stroke), lineWidth: lw)
            ctx.fill(Path(ellipseIn: CGRect(x: cx - r * 0.8, y: cy - r * 0.8, width: r * 1.6, height: r * 1.6)),
                     with: .color(flesh))
            for i in 0..<3 {
                let a = CGFloat(i) * 2 * .pi / 3 - .pi / 2
                ctx.fill(Path(ellipseIn: CGRect(x: cx + cos(a) * r * 0.4 - w * 0.015,
                                                y: cy + sin(a) * r * 0.4 - w * 0.015,
                                                width: w * 0.03, height: w * 0.03)),
                         with: .color(rind.opacity(0.5)))
            }
            // charm: gold seed at the slice center
            ctx.fill(Path(ellipseIn: CGRect(x: cx - w * 0.02, y: cy - w * 0.02, width: w * 0.04, height: w * 0.04)),
                     with: .color(Pack5Palette.gold))
        }
    }
}

// MARK: - 15. Spinach — bunch of broad leaves

struct SpinachArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            // three broad leaves fanning from a stem point
            let base = CGPoint(x: w * 0.5, y: h * 0.86)
            let tips: [(CGFloat, CGFloat, CGFloat)] = [(0.24, 0.2, 0.24), (0.5, 0.1, 0.28), (0.76, 0.2, 0.24)]
            for (i, (fx, fy, belly)) in tips.enumerated() {
                let leaf = Pack5Palette.leafPath(from: base, to: CGPoint(x: w * fx, y: h * fy), belly: belly)
                ctx.fill(leaf, with: .color(i == 1 ? Pack5Palette.leaf : Pack5Palette.leafDeep))
                ctx.stroke(leaf, with: .color(Pack5Palette.stroke), lineWidth: lw * 0.8)
                // midrib
                var rib = Path()
                rib.move(to: base)
                rib.addLine(to: CGPoint(x: w * (0.5 + (fx - 0.5) * 0.7), y: h * (0.86 + (fy - 0.86) * 0.7)))
                ctx.stroke(rib, with: .color(Pack5Palette.cream.opacity(0.5)), lineWidth: lw * 0.6)
            }
            // charm: gold dew drop on the middle leaf
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.36, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack5Palette.gold))
        }
    }
}

// MARK: - 16. Mushroom — button pair, cream caps

struct MushroomArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            func mushroom(cx: CGFloat, cy: CGFloat, s: CGFloat) {
                // stem
                let stem = Path(roundedRect: CGRect(x: w * cx - w * s * 0.16, y: h * cy, width: w * s * 0.32, height: h * s * 0.6),
                                cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
                ctx.fill(stem, with: .color(Pack5Palette.cream))
                ctx.stroke(stem, with: .color(Pack5Palette.stroke), lineWidth: lw)
                // cap: dome
                var cap = Path()
                cap.move(to: CGPoint(x: w * (cx - s * 0.5), y: h * cy))
                cap.addQuadCurve(to: CGPoint(x: w * (cx + s * 0.5), y: h * cy),
                                 control: CGPoint(x: w * cx, y: h * (cy - s * 0.9)))
                cap.closeSubpath()
                ctx.fill(cap, with: .color(Color(red: 0.9, green: 0.85, blue: 0.76)))
                ctx.stroke(cap, with: .color(Pack5Palette.stroke), lineWidth: lw)
            }
            mushroom(cx: 0.36, cy: 0.5, s: 0.5)
            mushroom(cx: 0.68, cy: 0.62, s: 0.38)
            // charm: gold fleck on the big cap
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.32, y: h * 0.36, width: w * 0.05, height: w * 0.05)),
                     with: .color(Pack5Palette.gold))
        }
    }
}

// MARK: - 17. Corn — cob with husk pulled back

struct CornArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            // cob: tall rounded capsule
            let cob = Path(roundedRect: CGRect(x: w * 0.38, y: h * 0.12, width: w * 0.24, height: h * 0.6),
                           cornerSize: CGSize(width: w * 0.12, height: w * 0.12))
            ctx.fill(cob, with: .color(Pack5Palette.yellow))
            ctx.stroke(cob, with: .color(Pack5Palette.stroke), lineWidth: lw)
            // kernel grid dots
            for row in 0..<4 {
                for col in 0..<2 {
                    ctx.fill(Path(ellipseIn: CGRect(x: w * (0.42 + 0.09 * CGFloat(col)),
                                                    y: h * (0.18 + 0.12 * CGFloat(row)),
                                                    width: w * 0.05, height: w * 0.05)),
                             with: .color(Pack5Palette.gold))
                }
            }
            // husk leaves pulled down either side
            let huskL = Pack5Palette.leafPath(from: CGPoint(x: w * 0.42, y: h * 0.6),
                                              to: CGPoint(x: w * 0.2, y: h * 0.92), belly: 0.3)
            let huskR = Pack5Palette.leafPath(from: CGPoint(x: w * 0.58, y: h * 0.6),
                                              to: CGPoint(x: w * 0.8, y: h * 0.92), belly: -0.3)
            let huskM = Pack5Palette.leafPath(from: CGPoint(x: w * 0.5, y: h * 0.64),
                                              to: CGPoint(x: w * 0.5, y: h * 0.96), belly: 0.34)
            for husk in [huskL, huskR, huskM] {
                ctx.fill(husk, with: .color(Pack5Palette.leaf))
                ctx.stroke(husk, with: .color(Pack5Palette.stroke), lineWidth: lw * 0.8)
            }
        }
    }
}

// MARK: - 18. Peas — open pod with a row of peas

struct PeasArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack5Palette.line(size)
            let podGreen = Color(red: 0.42, green: 0.62, blue: 0.3)
            // open pod: crescent boat
            var pod = Path()
            pod.move(to: CGPoint(x: w * 0.14, y: h * 0.44))
            pod.addQuadCurve(to: CGPoint(x: w * 0.86, y: h * 0.44), control: CGPoint(x: w * 0.5, y: h * 0.94))
            pod.addQuadCurve(to: CGPoint(x: w * 0.14, y: h * 0.44), control: CGPoint(x: w * 0.5, y: h * 0.6))
            ctx.fill(pod, with: .color(podGreen))
            ctx.stroke(pod, with: .color(Pack5Palette.stroke), lineWidth: lw)
            // peas sitting in the pod
            for i in 0..<4 {
                let fx = 0.26 + 0.16 * CGFloat(i)
                let p = Path(ellipseIn: CGRect(x: w * fx - w * 0.075, y: h * 0.4 - w * 0.075, width: w * 0.15, height: w * 0.15))
                ctx.fill(p, with: .color(Pack5Palette.leaf))
                ctx.stroke(p, with: .color(Pack5Palette.stroke), lineWidth: lw * 0.8)
            }
            // stem curl at the pod tip
            var curl = Path()
            curl.move(to: CGPoint(x: w * 0.14, y: h * 0.44))
            curl.addQuadCurve(to: CGPoint(x: w * 0.08, y: h * 0.28), control: CGPoint(x: w * 0.04, y: h * 0.4))
            ctx.stroke(curl, with: .color(podGreen), lineWidth: lw)
            // charm: one gold pea
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.74 - w * 0.05, y: h * 0.4 - w * 0.05, width: w * 0.1, height: w * 0.1)),
                     with: .color(Pack5Palette.gold))
        }
    }
}

// MARK: - Registration

enum Pack5Registry {
    /// exact lowercase names (including common plurals/variants) -> art
    static let exact: [String: () -> AnyView] = [
        "apple": { AnyView(AppleArt()) },
        "apples": { AnyView(AppleArt()) },
        "banana": { AnyView(BananaArt()) },
        "bananas": { AnyView(BananaArt()) },
        "strawberry": { AnyView(StrawberryArt()) },
        "strawberries": { AnyView(StrawberryArt()) },
        "blueberry": { AnyView(BlueberriesArt()) },
        "blueberries": { AnyView(BlueberriesArt()) },
        "raspberry": { AnyView(RaspberriesArt()) },
        "raspberries": { AnyView(RaspberriesArt()) },
        "orange": { AnyView(OrangeArt()) },
        "oranges": { AnyView(OrangeArt()) },
        "lime": { AnyView(LimeArt()) },
        "limes": { AnyView(LimeArt()) },
        "avocado": { AnyView(AvocadoArt()) },
        "avocados": { AnyView(AvocadoArt()) },
        "carrot": { AnyView(CarrotArt()) },
        "carrots": { AnyView(CarrotArt()) },
        "celery": { AnyView(CeleryArt()) },
        "potato": { AnyView(PotatoArt()) },
        "potatoes": { AnyView(PotatoArt()) },
        "sweet potato": { AnyView(SweetPotatoArt()) },
        "sweet potatoes": { AnyView(SweetPotatoArt()) },
        "bell pepper": { AnyView(BellPepperArt()) },
        "bell peppers": { AnyView(BellPepperArt()) },
        "red pepper": { AnyView(BellPepperArt()) },
        "green pepper": { AnyView(BellPepperArt()) },
        "cucumber": { AnyView(CucumberArt()) },
        "cucumbers": { AnyView(CucumberArt()) },
        "spinach": { AnyView(SpinachArt()) },
        "baby spinach": { AnyView(SpinachArt()) },
        "mushroom": { AnyView(MushroomArt()) },
        "mushrooms": { AnyView(MushroomArt()) },
        "corn": { AnyView(CornArt()) },
        "sweet corn": { AnyView(CornArt()) },
        "peas": { AnyView(PeasArt()) },
        "green peas": { AnyView(PeasArt()) },
        "pea": { AnyView(PeasArt()) },
    ]
    /// contains-keywords -> art. Keep keywords SPECIFIC (two words when one word would hijack unrelated ingredients).
    /// "corn" and "apple" are exact-only on purpose: keyword "corn" would hijack
    /// cornstarch/cornmeal/corn syrup, and keyword "apple" would hijack pineapple.
    static let keywords: [(String, () -> AnyView)] = [
        ("sweet potato", { AnyView(SweetPotatoArt()) }),
        ("bell pepper", { AnyView(BellPepperArt()) }),
        ("corn on the cob", { AnyView(CornArt()) }),
        ("sweet corn", { AnyView(CornArt()) }),
        ("blueberr", { AnyView(BlueberriesArt()) }),
        ("strawberr", { AnyView(StrawberryArt()) }),
        ("raspberr", { AnyView(RaspberriesArt()) }),
        ("cucumber", { AnyView(CucumberArt()) }),
        ("mushroom", { AnyView(MushroomArt()) }),
        ("spinach", { AnyView(SpinachArt()) }),
        ("avocado", { AnyView(AvocadoArt()) }),
        ("banana", { AnyView(BananaArt()) }),
        ("celery", { AnyView(CeleryArt()) }),
        ("carrot", { AnyView(CarrotArt()) }),
        ("potato", { AnyView(PotatoArt()) }),
        ("orange", { AnyView(OrangeArt()) }),
        ("lime", { AnyView(LimeArt()) }),
        ("peas", { AnyView(PeasArt()) }),
    ]
}
