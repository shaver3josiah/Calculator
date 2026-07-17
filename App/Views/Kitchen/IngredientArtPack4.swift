import SwiftUI

// Pack 4 — spreads & sweet things, same "storybook grocery" language as Pack 1.
// Each struct draws in normalized Canvas space (fractions of `size`) with no
// fixed frames, so the caller can size it anywhere 40→120pt.
// Flat fills + strokes only: no gradients, text, SF Symbols, or app deps.

// MARK: - Shared palette + helpers

private enum Pack4Palette {
    static let kraft = Color(red: 0.85, green: 0.74, blue: 0.58)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.42)
    static let ink = Color(red: 0.33, green: 0.20, blue: 0.16)
    static let berry = Color(red: 0.78, green: 0.24, blue: 0.32)
    static let tan = Color(red: 0.83, green: 0.62, blue: 0.38)
    static let cocoa = Color(red: 0.36, green: 0.22, blue: 0.14)
    static let amber = Color(red: 0.9, green: 0.6, blue: 0.2)

    static var stroke: Color { ink.opacity(0.35) }

    /// Outline width: 2.8% of the smaller dimension, floored at 1.2pt.
    static func line(_ s: CGSize) -> CGFloat { max(1.2, min(s.width, s.height) * 0.028) }

    /// Squat jar body with rounded corners; returns the body rect too so
    /// callers can place fills/labels relative to it.
    static func jar(_ s: CGSize, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> Path {
        Path(roundedRect: CGRect(x: s.width * x, y: s.height * y, width: s.width * w, height: s.height * h),
             cornerSize: CGSize(width: s.width * 0.07, height: s.width * 0.07))
    }
}

// MARK: - 1. Peanut butter — squat glass jar, tan fill, cream label with peanut

struct PeanutButterArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            let body = Pack4Palette.jar(size, x: 0.22, y: 0.28, w: 0.56, h: 0.58)
            ctx.fill(body, with: .color(Pack4Palette.tan))
            ctx.stroke(body, with: .color(Pack4Palette.stroke), lineWidth: lw)

            // lid
            let lid = Path(roundedRect: CGRect(x: w * 0.26, y: h * 0.16, width: w * 0.48, height: h * 0.14),
                           cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(lid, with: .color(Pack4Palette.berry))
            ctx.stroke(lid, with: .color(Pack4Palette.stroke), lineWidth: lw)

            // cream label with a little peanut (two lobes + waist line)
            let label = Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.46, width: w * 0.4, height: h * 0.26),
                             cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(label, with: .color(Pack4Palette.cream))
            ctx.stroke(label, with: .color(Pack4Palette.stroke), lineWidth: lw * 0.8)
            let nut1 = Path(ellipseIn: CGRect(x: w * 0.42, y: h * 0.5, width: w * 0.09, height: h * 0.09))
            let nut2 = Path(ellipseIn: CGRect(x: w * 0.48, y: h * 0.57, width: w * 0.09, height: h * 0.09))
            ctx.fill(nut1, with: .color(Pack4Palette.kraft))
            ctx.fill(nut2, with: .color(Pack4Palette.kraft))
            ctx.stroke(nut1, with: .color(Pack4Palette.stroke), lineWidth: lw * 0.6)
            ctx.stroke(nut2, with: .color(Pack4Palette.stroke), lineWidth: lw * 0.6)
            // charm: gold dot on lid
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.47, y: h * 0.2, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack4Palette.gold))
        }
    }
}

// MARK: - 2. Jam — berry-red jar, cloth-topped lid, strawberry label

struct JamArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            let body = Pack4Palette.jar(size, x: 0.24, y: 0.3, w: 0.52, h: 0.56)
            ctx.fill(body, with: .color(Pack4Palette.berry))
            ctx.stroke(body, with: .color(Pack4Palette.stroke), lineWidth: lw)

            // cloth top: scalloped cream dome over the rim
            var cloth = Path()
            cloth.move(to: CGPoint(x: w * 0.2, y: h * 0.3))
            cloth.addQuadCurve(to: CGPoint(x: w * 0.8, y: h * 0.3), control: CGPoint(x: w * 0.5, y: h * 0.08))
            cloth.addLine(to: CGPoint(x: w * 0.76, y: h * 0.36))
            cloth.addQuadCurve(to: CGPoint(x: w * 0.24, y: h * 0.36), control: CGPoint(x: w * 0.5, y: h * 0.42))
            cloth.closeSubpath()
            ctx.fill(cloth, with: .color(Pack4Palette.cream))
            ctx.stroke(cloth, with: .color(Pack4Palette.stroke), lineWidth: lw)
            // charm: gold ribbon band under the cloth
            ctx.fill(Path(CGRect(x: w * 0.24, y: h * 0.33, width: w * 0.52, height: h * 0.04)),
                     with: .color(Pack4Palette.gold))

            // label with a tiny strawberry (red heart-ish blob + green cap)
            let label = Path(roundedRect: CGRect(x: w * 0.32, y: h * 0.5, width: w * 0.36, height: h * 0.26),
                             cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(label, with: .color(Pack4Palette.cream))
            ctx.stroke(label, with: .color(Pack4Palette.stroke), lineWidth: lw * 0.8)
            let berry = Path(ellipseIn: CGRect(x: w * 0.44, y: h * 0.57, width: w * 0.12, height: h * 0.13))
            ctx.fill(berry, with: .color(Pack4Palette.berry))
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.45, y: h * 0.545, width: w * 0.1, height: h * 0.05)),
                     with: .color(Color(red: 0.36, green: 0.58, blue: 0.32)))
        }
    }
}

// MARK: - 3. Honey — honeypot with wooden dipper

struct HoneyJarArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            // round-bellied pot
            var pot = Path()
            pot.move(to: CGPoint(x: w * 0.32, y: h * 0.32))
            pot.addQuadCurve(to: CGPoint(x: w * 0.32, y: h * 0.82), control: CGPoint(x: w * 0.08, y: h * 0.57))
            pot.addQuadCurve(to: CGPoint(x: w * 0.68, y: h * 0.82), control: CGPoint(x: w * 0.5, y: h * 0.92))
            pot.addQuadCurve(to: CGPoint(x: w * 0.68, y: h * 0.32), control: CGPoint(x: w * 0.92, y: h * 0.57))
            pot.closeSubpath()
            ctx.fill(pot, with: .color(Pack4Palette.gold))
            ctx.stroke(pot, with: .color(Pack4Palette.stroke), lineWidth: lw)

            // rim
            let rim = Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.24, width: w * 0.4, height: h * 0.1),
                           cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(rim, with: .color(Pack4Palette.amber))
            ctx.stroke(rim, with: .color(Pack4Palette.stroke), lineWidth: lw)

            // wooden dipper leaning out: handle + three ridges (charm)
            var handle = Path()
            handle.move(to: CGPoint(x: w * 0.6, y: h * 0.26))
            handle.addLine(to: CGPoint(x: w * 0.78, y: h * 0.08))
            ctx.stroke(handle, with: .color(Pack4Palette.ink.opacity(0.6)), lineWidth: lw * 1.2)
            for i in 0..<3 {
                let t = CGFloat(i) * 0.045
                ctx.fill(Path(ellipseIn: CGRect(x: w * (0.68 + t), y: h * (0.14 - t), width: w * 0.07, height: w * 0.05)),
                         with: .color(Pack4Palette.kraft))
            }
            // drip line on the pot
            var drip = Path()
            drip.move(to: CGPoint(x: w * 0.42, y: h * 0.34))
            drip.addLine(to: CGPoint(x: w * 0.42, y: h * 0.48))
            ctx.stroke(drip, with: .color(Pack4Palette.amber), lineWidth: lw)
        }
    }
}

// MARK: - 4. Maple syrup — classic jug with tiny handle

struct MapleSyrupArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            // jug: narrow neck opening into a round body
            var jug = Path()
            jug.move(to: CGPoint(x: w * 0.44, y: h * 0.14))
            jug.addLine(to: CGPoint(x: w * 0.44, y: h * 0.3))
            jug.addQuadCurve(to: CGPoint(x: w * 0.24, y: h * 0.62), control: CGPoint(x: w * 0.24, y: h * 0.38))
            jug.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.88), control: CGPoint(x: w * 0.24, y: h * 0.88))
            jug.addQuadCurve(to: CGPoint(x: w * 0.76, y: h * 0.62), control: CGPoint(x: w * 0.76, y: h * 0.88))
            jug.addQuadCurve(to: CGPoint(x: w * 0.56, y: h * 0.3), control: CGPoint(x: w * 0.76, y: h * 0.38))
            jug.addLine(to: CGPoint(x: w * 0.56, y: h * 0.14))
            jug.closeSubpath()
            ctx.fill(jug, with: .color(Pack4Palette.amber))
            ctx.stroke(jug, with: .color(Pack4Palette.stroke), lineWidth: lw)

            // cap
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.41, y: h * 0.08, width: w * 0.18, height: h * 0.08),
                          cornerSize: CGSize(width: w * 0.02, height: w * 0.02)),
                     with: .color(Pack4Palette.cocoa))

            // tiny loop handle on the neck (charm-adjacent, and the jug tell)
            var loop = Path()
            loop.move(to: CGPoint(x: w * 0.56, y: h * 0.2))
            loop.addQuadCurve(to: CGPoint(x: w * 0.62, y: h * 0.32), control: CGPoint(x: w * 0.7, y: h * 0.22))
            ctx.stroke(loop, with: .color(Pack4Palette.stroke), lineWidth: lw * 1.1)

            // cream label + gold maple-dot charm
            let label = Path(ellipseIn: CGRect(x: w * 0.36, y: h * 0.52, width: w * 0.28, height: h * 0.24))
            ctx.fill(label, with: .color(Pack4Palette.cream))
            ctx.stroke(label, with: .color(Pack4Palette.stroke), lineWidth: lw * 0.8)
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.6, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack4Palette.gold))
        }
    }
}

// MARK: - 5. Chocolate bar — half in foil wrapper, scored squares showing

struct ChocolateBarArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            // bare bar (top half) with scored squares
            let bar = Path(roundedRect: CGRect(x: w * 0.28, y: h * 0.12, width: w * 0.44, height: h * 0.42),
                           cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(bar, with: .color(Pack4Palette.cocoa))
            ctx.stroke(bar, with: .color(Pack4Palette.stroke), lineWidth: lw)
            // score lines: one vertical, two horizontal
            var score = Path()
            score.move(to: CGPoint(x: w * 0.5, y: h * 0.12))
            score.addLine(to: CGPoint(x: w * 0.5, y: h * 0.54))
            score.move(to: CGPoint(x: w * 0.28, y: h * 0.26))
            score.addLine(to: CGPoint(x: w * 0.72, y: h * 0.26))
            score.move(to: CGPoint(x: w * 0.28, y: h * 0.4))
            score.addLine(to: CGPoint(x: w * 0.72, y: h * 0.4))
            ctx.stroke(score, with: .color(.black.opacity(0.25)), lineWidth: lw * 0.7)

            // foil wrapper (bottom half) with a torn zigzag edge
            var foil = Path()
            foil.move(to: CGPoint(x: w * 0.24, y: h * 0.56))
            for i in 0..<5 {
                let x0 = w * (0.24 + 0.104 * CGFloat(i))
                foil.addLine(to: CGPoint(x: x0 + w * 0.052, y: h * 0.5))
                foil.addLine(to: CGPoint(x: x0 + w * 0.104, y: h * 0.56))
            }
            foil.addLine(to: CGPoint(x: w * 0.76, y: h * 0.88))
            foil.addLine(to: CGPoint(x: w * 0.24, y: h * 0.88))
            foil.closeSubpath()
            ctx.fill(foil, with: .color(Pack4Palette.berry))
            ctx.stroke(foil, with: .color(Pack4Palette.stroke), lineWidth: lw)
            // charm: gold band on the wrapper
            ctx.fill(Path(CGRect(x: w * 0.24, y: h * 0.66, width: w * 0.52, height: h * 0.06)),
                     with: .color(Pack4Palette.gold))
        }
    }
}

// MARK: - 6. Chocolate spread — short jar, dark fill, cream band label

struct ChocolateSpreadArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            let body = Pack4Palette.jar(size, x: 0.22, y: 0.34, w: 0.56, h: 0.52)
            ctx.fill(body, with: .color(Pack4Palette.cocoa))
            ctx.stroke(body, with: .color(Pack4Palette.stroke), lineWidth: lw)

            // wide flat lid (nutella-ish silhouette)
            let lid = Path(roundedRect: CGRect(x: w * 0.24, y: h * 0.22, width: w * 0.52, height: h * 0.12),
                           cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(lid, with: .color(Pack4Palette.cream))
            ctx.stroke(lid, with: .color(Pack4Palette.stroke), lineWidth: lw)

            // cream band label across the body
            let band = Path(CGRect(x: w * 0.22, y: h * 0.48, width: w * 0.56, height: h * 0.22))
            ctx.fill(band, with: .color(Pack4Palette.cream))
            ctx.stroke(band, with: .color(Pack4Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold swirl dot pair on the band
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.4, y: h * 0.54, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack4Palette.gold))
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.52, y: h * 0.54, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack4Palette.tan))
        }
    }
}

// MARK: - 7. Marshmallow — three puffy cylinders stacked

struct MarshmallowArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            // each mallow: rounded rect body + ellipse top for the puffy read
            let spots: [(CGFloat, CGFloat)] = [(0.3, 0.52), (0.52, 0.52), (0.41, 0.24)]
            for (fx, fy) in spots {
                let bodyR = CGRect(x: w * fx, y: h * (fy + 0.06), width: w * 0.26, height: h * 0.26)
                let body = Path(roundedRect: bodyR, cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
                ctx.fill(body, with: .color(Pack4Palette.cream))
                ctx.stroke(body, with: .color(Pack4Palette.stroke), lineWidth: lw)
                let top = Path(ellipseIn: CGRect(x: w * fx, y: h * fy, width: w * 0.26, height: h * 0.13))
                ctx.fill(top, with: .color(.white.opacity(0.9)))
                ctx.stroke(top, with: .color(Pack4Palette.stroke), lineWidth: lw * 0.8)
            }
            // charm: gold toasted blush on the top mallow
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.48, y: h * 0.35, width: w * 0.08, height: w * 0.05)),
                     with: .color(Pack4Palette.gold.opacity(0.7)))
        }
    }
}

// MARK: - 8. Caramel — wrapped candy with twisted ends

struct CaramelArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            // candy body
            let body = Path(ellipseIn: CGRect(x: w * 0.3, y: h * 0.36, width: w * 0.4, height: h * 0.28))
            ctx.fill(body, with: .color(Pack4Palette.amber))
            ctx.stroke(body, with: .color(Pack4Palette.stroke), lineWidth: lw)

            // twisted ends: fan triangles either side
            var leftT = Path()
            leftT.move(to: CGPoint(x: w * 0.32, y: h * 0.5))
            leftT.addLine(to: CGPoint(x: w * 0.12, y: h * 0.36))
            leftT.addLine(to: CGPoint(x: w * 0.12, y: h * 0.64))
            leftT.closeSubpath()
            var rightT = Path()
            rightT.move(to: CGPoint(x: w * 0.68, y: h * 0.5))
            rightT.addLine(to: CGPoint(x: w * 0.88, y: h * 0.36))
            rightT.addLine(to: CGPoint(x: w * 0.88, y: h * 0.64))
            rightT.closeSubpath()
            for t in [leftT, rightT] {
                ctx.fill(t, with: .color(Pack4Palette.amber))
                ctx.stroke(t, with: .color(Pack4Palette.stroke), lineWidth: lw)
            }
            // twist pinch lines
            var pinch = Path()
            pinch.move(to: CGPoint(x: w * 0.3, y: h * 0.42))
            pinch.addLine(to: CGPoint(x: w * 0.3, y: h * 0.58))
            pinch.move(to: CGPoint(x: w * 0.7, y: h * 0.42))
            pinch.addLine(to: CGPoint(x: w * 0.7, y: h * 0.58))
            ctx.stroke(pinch, with: .color(Pack4Palette.stroke), lineWidth: lw * 0.8)
            // charm: cream sheen arc on the candy
            var sheen = Path()
            sheen.move(to: CGPoint(x: w * 0.38, y: h * 0.44))
            sheen.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.4), control: CGPoint(x: w * 0.43, y: h * 0.4))
            ctx.stroke(sheen, with: .color(Pack4Palette.cream.opacity(0.8)), lineWidth: lw * 0.8)
        }
    }
}

// MARK: - 9. Sprinkles — shaker jar with colorful specks

struct SprinklesArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            let body = Pack4Palette.jar(size, x: 0.28, y: 0.3, w: 0.44, h: 0.56)
            ctx.fill(body, with: .color(Pack4Palette.cream))
            ctx.stroke(body, with: .color(Pack4Palette.stroke), lineWidth: lw)

            // shaker cap with holes
            let cap = Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.16, width: w * 0.4, height: h * 0.16),
                           cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(cap, with: .color(Pack4Palette.berry))
            ctx.stroke(cap, with: .color(Pack4Palette.stroke), lineWidth: lw)
            for i in 0..<3 {
                ctx.fill(Path(ellipseIn: CGRect(x: w * (0.38 + 0.09 * CGFloat(i)), y: h * 0.22, width: w * 0.04, height: w * 0.04)),
                         with: .color(Pack4Palette.ink.opacity(0.3)))
            }

            // sprinkles inside: short colorful dashes at jaunty angles
            let colors = [Pack4Palette.berry, Pack4Palette.gold, Color(red: 0.36, green: 0.58, blue: 0.32),
                          Color(red: 0.4, green: 0.55, blue: 0.85), Pack4Palette.amber, Pack4Palette.berry]
            let pts: [(CGFloat, CGFloat, CGFloat)] = [(0.38, 0.48, 0.3), (0.55, 0.45, -0.5), (0.44, 0.58, 0.9),
                                                      (0.6, 0.6, 0.2), (0.36, 0.7, -0.7), (0.52, 0.74, 0.5)]
            for (i, (fx, fy, ang)) in pts.enumerated() {
                let len = w * 0.09
                var d = Path()
                d.move(to: CGPoint(x: w * fx - cos(ang) * len / 2, y: h * fy - sin(ang) * len / 2))
                d.addLine(to: CGPoint(x: w * fx + cos(ang) * len / 2, y: h * fy + sin(ang) * len / 2))
                ctx.stroke(d, with: .color(colors[i]), lineWidth: lw * 1.3)
            }
        }
    }
}

// MARK: - 10. Molasses — dark bottle, amber glint

struct MolassesArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            // bottle: neck flaring into shoulders
            var bottle = Path()
            bottle.move(to: CGPoint(x: w * 0.43, y: h * 0.16))
            bottle.addLine(to: CGPoint(x: w * 0.43, y: h * 0.32))
            bottle.addQuadCurve(to: CGPoint(x: w * 0.28, y: h * 0.48), control: CGPoint(x: w * 0.28, y: h * 0.36))
            bottle.addLine(to: CGPoint(x: w * 0.28, y: h * 0.82))
            bottle.addQuadCurve(to: CGPoint(x: w * 0.34, y: h * 0.88), control: CGPoint(x: w * 0.28, y: h * 0.88))
            bottle.addLine(to: CGPoint(x: w * 0.66, y: h * 0.88))
            bottle.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.82), control: CGPoint(x: w * 0.72, y: h * 0.88))
            bottle.addLine(to: CGPoint(x: w * 0.72, y: h * 0.48))
            bottle.addQuadCurve(to: CGPoint(x: w * 0.57, y: h * 0.32), control: CGPoint(x: w * 0.72, y: h * 0.36))
            bottle.addLine(to: CGPoint(x: w * 0.57, y: h * 0.16))
            bottle.closeSubpath()
            ctx.fill(bottle, with: .color(Pack4Palette.cocoa))
            ctx.stroke(bottle, with: .color(Pack4Palette.stroke), lineWidth: lw)

            // cap
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.4, y: h * 0.1, width: w * 0.2, height: h * 0.08),
                          cornerSize: CGSize(width: w * 0.02, height: w * 0.02)),
                     with: .color(Pack4Palette.gold))

            // cream label
            let label = Path(roundedRect: CGRect(x: w * 0.34, y: h * 0.56, width: w * 0.32, height: h * 0.2),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Pack4Palette.cream))
            ctx.stroke(label, with: .color(Pack4Palette.stroke), lineWidth: lw * 0.8)
            // charm: amber glint down the bottle shoulder
            var glint = Path()
            glint.move(to: CGPoint(x: w * 0.34, y: h * 0.44))
            glint.addLine(to: CGPoint(x: w * 0.34, y: h * 0.54))
            ctx.stroke(glint, with: .color(Pack4Palette.amber), lineWidth: lw)
        }
    }
}

// MARK: - 11. Peanuts — peanut pair in shell

struct PeanutsArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            // one peanut = two overlapping lobes pinched at the waist
            func peanut(cx: CGFloat, cy: CGFloat, s: CGFloat, tilt: CGFloat) {
                let dx = cos(tilt) * s * 0.55, dy = sin(tilt) * s * 0.55
                let lobe1 = Path(ellipseIn: CGRect(x: w * (cx - dx) - w * s * 0.5, y: h * (cy - dy) - h * s * 0.55,
                                                   width: w * s, height: h * s * 1.1))
                let lobe2 = Path(ellipseIn: CGRect(x: w * (cx + dx) - w * s * 0.5, y: h * (cy + dy) - h * s * 0.55,
                                                   width: w * s, height: h * s * 1.1))
                for lobe in [lobe1, lobe2] {
                    ctx.fill(lobe, with: .color(Pack4Palette.kraft))
                    ctx.stroke(lobe, with: .color(Pack4Palette.stroke), lineWidth: lw)
                }
                // shell ridge across the waist
                var ridge = Path()
                ridge.move(to: CGPoint(x: w * cx - w * s * 0.3, y: h * cy))
                ridge.addLine(to: CGPoint(x: w * cx + w * s * 0.3, y: h * cy))
                ctx.stroke(ridge, with: .color(Pack4Palette.ink.opacity(0.25)), lineWidth: lw * 0.7)
            }
            peanut(cx: 0.36, cy: 0.42, s: 0.22, tilt: 0.9)
            peanut(cx: 0.62, cy: 0.62, s: 0.22, tilt: 0.5)
            // charm: gold speck between them
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.5, y: h * 0.36, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack4Palette.gold))
        }
    }
}

// MARK: - 12. Almonds — small kraft bag with two almonds spilling

struct AlmondsArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            // small kraft bag, tilted-flap top
            let bag = Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.28, width: w * 0.42, height: h * 0.5),
                           cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(bag, with: .color(Pack4Palette.kraft))
            ctx.stroke(bag, with: .color(Pack4Palette.stroke), lineWidth: lw)
            let flap = Path(roundedRect: CGRect(x: w * 0.28, y: h * 0.18, width: w * 0.46, height: h * 0.12),
                            cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(flap, with: .color(Pack4Palette.kraft))
            ctx.fill(flap, with: .color(Pack4Palette.ink.opacity(0.08)))
            ctx.stroke(flap, with: .color(Pack4Palette.stroke), lineWidth: lw)

            // cream label patch
            let label = Path(roundedRect: CGRect(x: w * 0.38, y: h * 0.42, width: w * 0.26, height: h * 0.18),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Pack4Palette.cream))
            ctx.stroke(label, with: .color(Pack4Palette.stroke), lineWidth: lw * 0.8)

            // two almonds spilling by the bag foot: teardrop ovals
            let a1 = Path(ellipseIn: CGRect(x: w * 0.14, y: h * 0.74, width: w * 0.16, height: h * 0.11))
            let a2 = Path(ellipseIn: CGRect(x: w * 0.7, y: h * 0.78, width: w * 0.16, height: h * 0.11))
            for a in [a1, a2] {
                ctx.fill(a, with: .color(Pack4Palette.tan))
                ctx.stroke(a, with: .color(Pack4Palette.stroke), lineWidth: lw * 0.8)
            }
            // charm: gold stitch dot on the flap
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.48, y: h * 0.21, width: w * 0.05, height: w * 0.05)),
                     with: .color(Pack4Palette.gold))
        }
    }
}

// MARK: - 13. Walnuts — walnut whole + half

struct WalnutsArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            // whole walnut: round shell with a center seam
            let whole = Path(ellipseIn: CGRect(x: w * 0.16, y: h * 0.3, width: w * 0.36, height: h * 0.4))
            ctx.fill(whole, with: .color(Pack4Palette.kraft))
            ctx.stroke(whole, with: .color(Pack4Palette.stroke), lineWidth: lw)
            var seam = Path()
            seam.move(to: CGPoint(x: w * 0.34, y: h * 0.32))
            seam.addQuadCurve(to: CGPoint(x: w * 0.34, y: h * 0.68), control: CGPoint(x: w * 0.28, y: h * 0.5))
            ctx.stroke(seam, with: .color(Pack4Palette.ink.opacity(0.3)), lineWidth: lw * 0.7)

            // half walnut: shell cup with wavy kernel inside
            let half = Path(ellipseIn: CGRect(x: w * 0.5, y: h * 0.44, width: w * 0.36, height: h * 0.36))
            ctx.fill(half, with: .color(Pack4Palette.tan))
            ctx.stroke(half, with: .color(Pack4Palette.stroke), lineWidth: lw)
            // kernel: two wiggly lobes
            let k1 = Path(ellipseIn: CGRect(x: w * 0.55, y: h * 0.52, width: w * 0.12, height: h * 0.2))
            let k2 = Path(ellipseIn: CGRect(x: w * 0.68, y: h * 0.52, width: w * 0.12, height: h * 0.2))
            for k in [k1, k2] {
                ctx.fill(k, with: .color(Pack4Palette.cream))
                ctx.stroke(k, with: .color(Pack4Palette.ink.opacity(0.25)), lineWidth: lw * 0.6)
            }
            // charm: gold speck by the whole nut
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.24, y: h * 0.24, width: w * 0.05, height: w * 0.05)),
                     with: .color(Pack4Palette.gold))
        }
    }
}

// MARK: - 14. Raisins — little red box with heaped raisins

struct RaisinsArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack4Palette.line(size)
            // heaped raisins behind the box rim: cluster of dark purple blobs
            let raisin = Color(red: 0.36, green: 0.2, blue: 0.3)
            let pts: [(CGFloat, CGFloat)] = [(0.36, 0.3), (0.48, 0.24), (0.6, 0.3), (0.42, 0.36), (0.55, 0.36)]
            for (fx, fy) in pts {
                let r = Path(ellipseIn: CGRect(x: w * fx - w * 0.06, y: h * fy - h * 0.05, width: w * 0.12, height: h * 0.1))
                ctx.fill(r, with: .color(raisin))
                ctx.stroke(r, with: .color(Pack4Palette.stroke), lineWidth: lw * 0.6)
            }

            // little red box
            let box = Path(roundedRect: CGRect(x: w * 0.28, y: h * 0.36, width: w * 0.44, height: h * 0.5),
                           cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(box, with: .color(Pack4Palette.berry))
            ctx.stroke(box, with: .color(Pack4Palette.stroke), lineWidth: lw)

            // cream label with one raisin on it
            let label = Path(roundedRect: CGRect(x: w * 0.36, y: h * 0.5, width: w * 0.28, height: h * 0.22),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Pack4Palette.cream))
            ctx.stroke(label, with: .color(Pack4Palette.stroke), lineWidth: lw * 0.8)
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.45, y: h * 0.57, width: w * 0.1, height: h * 0.08)),
                     with: .color(raisin))
            // charm: gold dot on the box corner
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.31, y: h * 0.4, width: w * 0.05, height: w * 0.05)),
                     with: .color(Pack4Palette.gold))
        }
    }
}

// MARK: - Registration

enum Pack4Registry {
    /// exact lowercase names (including common plurals/variants) -> art
    static let exact: [String: () -> AnyView] = [
        "peanut butter": { AnyView(PeanutButterArt()) },
        "jam": { AnyView(JamArt()) },
        "strawberry jam": { AnyView(JamArt()) },
        "grape jam": { AnyView(JamArt()) },
        "raspberry jam": { AnyView(JamArt()) },
        "jelly": { AnyView(JamArt()) },
        "honey": { AnyView(HoneyJarArt()) },
        "maple syrup": { AnyView(MapleSyrupArt()) },
        "syrup": { AnyView(MapleSyrupArt()) },
        "chocolate bar": { AnyView(ChocolateBarArt()) },
        "chocolate spread": { AnyView(ChocolateSpreadArt()) },
        "nutella": { AnyView(ChocolateSpreadArt()) },
        "marshmallow": { AnyView(MarshmallowArt()) },
        "marshmallows": { AnyView(MarshmallowArt()) },
        "caramel": { AnyView(CaramelArt()) },
        "sprinkles": { AnyView(SprinklesArt()) },
        "molasses": { AnyView(MolassesArt()) },
        "peanut": { AnyView(PeanutsArt()) },
        "peanuts": { AnyView(PeanutsArt()) },
        "almond": { AnyView(AlmondsArt()) },
        "almonds": { AnyView(AlmondsArt()) },
        "walnut": { AnyView(WalnutsArt()) },
        "walnuts": { AnyView(WalnutsArt()) },
        "raisin": { AnyView(RaisinsArt()) },
        "raisins": { AnyView(RaisinsArt()) },
    ]
    /// contains-keywords -> art. Keep keywords SPECIFIC (two words when one word would hijack unrelated ingredients).
    static let keywords: [(String, () -> AnyView)] = [
        ("peanut butter", { AnyView(PeanutButterArt()) }),
        ("strawberry jam", { AnyView(JamArt()) }),
        ("maple syrup", { AnyView(MapleSyrupArt()) }),
        ("chocolate bar", { AnyView(ChocolateBarArt()) }),
        ("chocolate spread", { AnyView(ChocolateSpreadArt()) }),
        ("marshmallow", { AnyView(MarshmallowArt()) }),
        ("sprinkle", { AnyView(SprinklesArt()) }),
        ("molasses", { AnyView(MolassesArt()) }),
        ("caramel", { AnyView(CaramelArt()) }),
        ("raisin", { AnyView(RaisinsArt()) }),
        ("walnut", { AnyView(WalnutsArt()) }),
        ("almond", { AnyView(AlmondsArt()) }),
        ("jam", { AnyView(JamArt()) }),
        ("jelly", { AnyView(JamArt()) }),
        ("honey", { AnyView(HoneyJarArt()) }),
        ("syrup", { AnyView(MapleSyrupArt()) }),
        ("peanut", { AnyView(PeanutsArt()) }),
    ]
}
