import SwiftUI

// Pack 7 — dairy, protein & the spice rack, same "storybook grocery" idiom
// as Pack 1. Normalized Canvas space (fractions of `size`), flat fills +
// strokes only, one warm/gold charm per item. No text, symbols, or app deps.

// MARK: - Shared palette + helpers

private enum Pack7Palette {
    static let kraft = Color(red: 0.85, green: 0.74, blue: 0.58)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.42)
    static let ink = Color(red: 0.33, green: 0.20, blue: 0.16)
    static let meatPink = Color(red: 0.93, green: 0.6, blue: 0.55)

    static var stroke: Color { ink.opacity(0.35) }

    /// Outline width: 2.8% of the smaller dimension, floored at 1.2pt.
    static func line(_ s: CGSize) -> CGFloat { max(1.2, min(s.width, s.height) * 0.028) }

    /// Simple leaf: two quad curves meeting at a tip, used by the herb jars.
    static func leaf(at c: CGPoint, len: CGFloat, angle: CGFloat) -> Path {
        let tip = CGPoint(x: c.x + len * cos(angle), y: c.y + len * sin(angle))
        let side = len * 0.45
        let perp = angle + .pi / 2
        var p = Path()
        p.move(to: c)
        p.addQuadCurve(to: tip, control: CGPoint(x: (c.x + tip.x) / 2 + side * cos(perp),
                                                 y: (c.y + tip.y) / 2 + side * sin(perp)))
        p.addQuadCurve(to: c, control: CGPoint(x: (c.x + tip.x) / 2 - side * cos(perp),
                                               y: (c.y + tip.y) / 2 - side * sin(perp)))
        p.closeSubpath()
        return p
    }
}

/// Chili powder, paprika (and their cumin/turmeric/cayenne stand-ins) share
/// one glass spice jar; only the powder color changes.
private struct SpiceJarCanvas: View {
    let powder: Color

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            let jar = Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.26, width: w * 0.4, height: h * 0.62),
                           cornerSize: CGSize(width: w * 0.07, height: w * 0.07))
            // powder fill first, then a pale glass headroom band on top
            ctx.fill(jar, with: .color(powder))
            ctx.fill(Path(CGRect(x: w * 0.3, y: h * 0.26, width: w * 0.4, height: h * 0.12)),
                     with: .color(Color(red: 0.92, green: 0.94, blue: 0.95)))
            ctx.stroke(jar, with: .color(Pack7Palette.stroke), lineWidth: lw)

            let cap = Path(roundedRect: CGRect(x: w * 0.32, y: h * 0.12, width: w * 0.36, height: h * 0.14),
                           cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(cap, with: .color(Pack7Palette.ink))
            ctx.stroke(cap, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.8)

            let label = Path(roundedRect: CGRect(x: w * 0.36, y: h * 0.5, width: w * 0.28, height: h * 0.2),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Pack7Palette.cream))
            ctx.stroke(label, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold dot on label
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.56, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack7Palette.gold))
        }
    }
}

/// Herb jar shared by the rack: same jar, different green + leaf mark.
/// `sprig: true` swaps the leaf for a needled rosemary/thyme sprig, and
/// `fresh: true` adds a loose leaf beside the jar for fresh basil.
private struct HerbJarCanvas: View {
    let green: Color
    var sprig: Bool = false
    var fresh: Bool = false

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            let jar = Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.26, width: w * 0.4, height: h * 0.62),
                           cornerSize: CGSize(width: w * 0.07, height: w * 0.07))
            ctx.fill(jar, with: .color(green.opacity(0.85)))
            ctx.fill(Path(CGRect(x: w * 0.3, y: h * 0.26, width: w * 0.4, height: h * 0.12)),
                     with: .color(Color(red: 0.92, green: 0.94, blue: 0.95)))
            ctx.stroke(jar, with: .color(Pack7Palette.stroke), lineWidth: lw)

            let cap = Path(roundedRect: CGRect(x: w * 0.32, y: h * 0.12, width: w * 0.36, height: h * 0.14),
                           cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(cap, with: .color(Pack7Palette.kraft))
            ctx.stroke(cap, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.8)

            let label = Path(roundedRect: CGRect(x: w * 0.36, y: h * 0.48, width: w * 0.28, height: h * 0.22),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Pack7Palette.cream))
            ctx.stroke(label, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.8)

            if sprig {
                // needled sprig on the label instead of a leaf
                var stem = Path()
                stem.move(to: CGPoint(x: w * 0.5, y: h * 0.66))
                stem.addLine(to: CGPoint(x: w * 0.5, y: h * 0.51))
                ctx.stroke(stem, with: .color(green), lineWidth: lw * 0.8)
                for i in 0..<3 {
                    let y = h * (0.63 - 0.04 * CGFloat(i))
                    var pair = Path()
                    pair.move(to: CGPoint(x: w * 0.45, y: y - h * 0.02))
                    pair.addLine(to: CGPoint(x: w * 0.5, y: y))
                    pair.addLine(to: CGPoint(x: w * 0.55, y: y - h * 0.02))
                    ctx.stroke(pair, with: .color(green), lineWidth: lw * 0.7)
                }
            } else {
                ctx.fill(Pack7Palette.leaf(at: CGPoint(x: w * 0.44, y: h * 0.64), len: w * 0.14, angle: -.pi / 3),
                         with: .color(green))
            }
            if fresh {
                // loose fresh leaf resting by the jar's foot
                ctx.fill(Pack7Palette.leaf(at: CGPoint(x: w * 0.72, y: h * 0.88), len: w * 0.18, angle: -.pi / 4),
                         with: .color(green))
            }
            // charm: gold dot in the label corner
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.57, y: h * 0.5, width: w * 0.05, height: w * 0.05)),
                     with: .color(Pack7Palette.gold))
        }
    }
}

// MARK: - 1. Yogurt — tapered cup, foil peeled back

struct YogurtArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            // tapered cup body
            var cup = Path()
            cup.move(to: CGPoint(x: w * 0.24, y: h * 0.3))
            cup.addLine(to: CGPoint(x: w * 0.76, y: h * 0.3))
            cup.addLine(to: CGPoint(x: w * 0.68, y: h * 0.86))
            cup.addLine(to: CGPoint(x: w * 0.32, y: h * 0.86))
            cup.closeSubpath()
            ctx.fill(cup, with: .color(Color(red: 0.94, green: 0.8, blue: 0.85)))
            ctx.stroke(cup, with: .color(Pack7Palette.stroke), lineWidth: lw)

            // foil lid, half still on
            let foil = Path(ellipseIn: CGRect(x: w * 0.2, y: h * 0.24, width: w * 0.6, height: h * 0.12))
            ctx.fill(foil, with: .color(Color(red: 0.8, green: 0.82, blue: 0.86)))
            ctx.stroke(foil, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.8)
            // peeled corner curling up (charm in gold)
            var peel = Path()
            peel.move(to: CGPoint(x: w * 0.72, y: h * 0.28))
            peel.addQuadCurve(to: CGPoint(x: w * 0.86, y: h * 0.12), control: CGPoint(x: w * 0.88, y: h * 0.26))
            ctx.stroke(peel, with: .color(Pack7Palette.gold), lineWidth: lw * 1.2)

            let label = Path(roundedRect: CGRect(x: w * 0.36, y: h * 0.46, width: w * 0.28, height: h * 0.22),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Pack7Palette.cream))
            ctx.stroke(label, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.8)
        }
    }
}

// MARK: - 2. Ice cream — pint tub, lid ajar

struct IceCreamArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            var tub = Path()
            tub.move(to: CGPoint(x: w * 0.24, y: h * 0.34))
            tub.addLine(to: CGPoint(x: w * 0.76, y: h * 0.34))
            tub.addLine(to: CGPoint(x: w * 0.7, y: h * 0.88))
            tub.addLine(to: CGPoint(x: w * 0.3, y: h * 0.88))
            tub.closeSubpath()
            ctx.fill(tub, with: .color(Color(red: 0.85, green: 0.72, blue: 0.82)))
            ctx.stroke(tub, with: .color(Pack7Palette.stroke), lineWidth: lw)

            // lid ajar: tilted rounded slab above the rim
            var lid = Path(roundedRect: CGRect(x: -w * 0.29, y: -h * 0.06, width: w * 0.58, height: h * 0.12),
                           cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            lid = lid.applying(CGAffineTransform(rotationAngle: -0.18)
                .concatenating(CGAffineTransform(translationX: w * 0.52, y: h * 0.22)))
            ctx.fill(lid, with: .color(Pack7Palette.cream))
            ctx.stroke(lid, with: .color(Pack7Palette.stroke), lineWidth: lw)

            let band = Path(CGRect(x: w * 0.27, y: h * 0.5, width: w * 0.46, height: h * 0.2))
            ctx.fill(band, with: .color(Pack7Palette.cream))
            ctx.stroke(band, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold scoop dot on the band
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.45, y: h * 0.55, width: w * 0.1, height: w * 0.1)),
                     with: .color(Pack7Palette.gold))
        }
    }
}

// MARK: - 3. Coconut milk — can with palm mark

struct CoconutMilkArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            let body = Path(CGRect(x: w * 0.26, y: h * 0.24, width: w * 0.48, height: h * 0.6))
            ctx.fill(body, with: .color(Color(red: 0.76, green: 0.79, blue: 0.82)))
            ctx.stroke(body, with: .color(Pack7Palette.stroke), lineWidth: lw)

            let lid = Path(ellipseIn: CGRect(x: w * 0.24, y: h * 0.16, width: w * 0.52, height: h * 0.15))
            ctx.fill(lid, with: .color(Color(red: 0.66, green: 0.69, blue: 0.72)))
            ctx.stroke(lid, with: .color(Pack7Palette.stroke), lineWidth: lw)

            let label = Path(CGRect(x: w * 0.26, y: h * 0.4, width: w * 0.48, height: h * 0.32))
            ctx.fill(label, with: .color(Pack7Palette.cream))
            ctx.stroke(label, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.8)

            // palm mark: trunk + three arcing fronds
            let palm = Color(red: 0.36, green: 0.55, blue: 0.4)
            var trunk = Path()
            trunk.move(to: CGPoint(x: w * 0.5, y: h * 0.68))
            trunk.addLine(to: CGPoint(x: w * 0.5, y: h * 0.52))
            ctx.stroke(trunk, with: .color(palm), lineWidth: lw)
            for dx in [CGFloat(-0.12), 0, 0.12] {
                var frond = Path()
                frond.move(to: CGPoint(x: w * 0.5, y: h * 0.52))
                frond.addQuadCurve(to: CGPoint(x: w * (0.5 + dx), y: h * 0.46),
                                   control: CGPoint(x: w * (0.5 + dx * 0.6), y: h * 0.44))
                ctx.stroke(frond, with: .color(palm), lineWidth: lw * 0.8)
            }
            // charm: gold coconut dot at the trunk's foot
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.53, y: h * 0.64, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack7Palette.gold))
        }
    }
}

// MARK: - 4. Almond milk — gable-top carton (also stands in for oat milk)

struct AlmondMilkArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            let box = Path(CGRect(x: w * 0.28, y: h * 0.3, width: w * 0.44, height: h * 0.58))
            ctx.fill(box, with: .color(Pack7Palette.cream))
            ctx.stroke(box, with: .color(Pack7Palette.stroke), lineWidth: lw)

            var roof = Path()
            roof.move(to: CGPoint(x: w * 0.28, y: h * 0.3))
            roof.addLine(to: CGPoint(x: w * 0.5, y: h * 0.12))
            roof.addLine(to: CGPoint(x: w * 0.72, y: h * 0.3))
            roof.closeSubpath()
            ctx.fill(roof, with: .color(Color(red: 0.75, green: 0.62, blue: 0.48)))
            ctx.stroke(roof, with: .color(Pack7Palette.stroke), lineWidth: lw)

            let label = Path(roundedRect: CGRect(x: w * 0.34, y: h * 0.44, width: w * 0.32, height: h * 0.3),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Color(red: 0.93, green: 0.87, blue: 0.78)))
            ctx.stroke(label, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold almond (tilted oval) on the label
            var almond = Path(ellipseIn: CGRect(x: -w * 0.06, y: -w * 0.04, width: w * 0.12, height: w * 0.08))
            almond = almond.applying(CGAffineTransform(rotationAngle: -0.6)
                .concatenating(CGAffineTransform(translationX: w * 0.5, y: h * 0.59)))
            ctx.fill(almond, with: .color(Pack7Palette.gold))
            ctx.stroke(almond, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.6)
        }
    }
}

// MARK: - 5. Bacon — three wavy strips

struct BaconArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let meat = Color(red: 0.76, green: 0.32, blue: 0.28)
            // three wavy strips, each a thick stroked wave with a cream fat line
            for i in 0..<3 {
                let y = h * (0.28 + 0.24 * CGFloat(i))
                var strip = Path()
                strip.move(to: CGPoint(x: w * 0.12, y: y))
                strip.addCurve(to: CGPoint(x: w * 0.5, y: y),
                               control1: CGPoint(x: w * 0.24, y: y - h * 0.08),
                               control2: CGPoint(x: w * 0.38, y: y + h * 0.08))
                strip.addCurve(to: CGPoint(x: w * 0.88, y: y),
                               control1: CGPoint(x: w * 0.62, y: y - h * 0.08),
                               control2: CGPoint(x: w * 0.76, y: y + h * 0.08))
                ctx.stroke(strip, with: .color(meat), style: StrokeStyle(lineWidth: h * 0.13, lineCap: .round))
                ctx.stroke(strip, with: .color(Pack7Palette.cream), style: StrokeStyle(lineWidth: h * 0.035, lineCap: .round))
            }
            // charm: gold sizzle dot off the top strip
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.8, y: h * 0.12, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack7Palette.gold))
        }
    }
}

// MARK: - 6. Sausage — pair of links

struct SausageArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            let sausage = Color(red: 0.72, green: 0.36, blue: 0.26)
            // two capsule links angled toward each other
            for (angle, tx, ty) in [(CGFloat(-0.35), CGFloat(0.36), CGFloat(0.42)), (0.35, 0.64, 0.62)] {
                var link = Path(roundedRect: CGRect(x: -w * 0.24, y: -h * 0.1, width: w * 0.48, height: h * 0.2),
                                cornerSize: CGSize(width: h * 0.1, height: h * 0.1))
                link = link.applying(CGAffineTransform(rotationAngle: angle)
                    .concatenating(CGAffineTransform(translationX: w * tx, y: h * ty)))
                ctx.fill(link, with: .color(sausage))
                ctx.stroke(link, with: .color(Pack7Palette.stroke), lineWidth: lw)
            }
            // twist tie between the links (charm in gold)
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.46, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack7Palette.gold))
            ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.46, width: w * 0.08, height: w * 0.08)),
                       with: .color(Pack7Palette.stroke), lineWidth: lw * 0.6)
        }
    }
}

// MARK: - 7. Ham — steak slice with bone dot

struct HamArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            let slice = Path(ellipseIn: CGRect(x: w * 0.14, y: h * 0.24, width: w * 0.72, height: h * 0.56))
            ctx.fill(slice, with: .color(Pack7Palette.meatPink))
            ctx.stroke(slice, with: .color(Pack7Palette.stroke), lineWidth: lw)

            // fat rim: inner ellipse line
            let rim = Path(ellipseIn: CGRect(x: w * 0.2, y: h * 0.29, width: w * 0.6, height: h * 0.46))
            ctx.stroke(rim, with: .color(Pack7Palette.cream), lineWidth: lw)

            // round bone in the center
            let bone = Path(ellipseIn: CGRect(x: w * 0.42, y: h * 0.44, width: w * 0.16, height: w * 0.16))
            ctx.fill(bone, with: .color(Pack7Palette.cream))
            ctx.stroke(bone, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold marrow dot inside the bone
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.47, y: h * 0.485, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack7Palette.gold))
        }
    }
}

// MARK: - 8. Turkey — drumstick

struct TurkeyArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            let roast = Color(red: 0.78, green: 0.5, blue: 0.28)
            // meaty teardrop pointing up-left, bone down-right
            var meat = Path()
            meat.move(to: CGPoint(x: w * 0.58, y: h * 0.56))
            meat.addQuadCurve(to: CGPoint(x: w * 0.18, y: h * 0.32), control: CGPoint(x: w * 0.52, y: h * 0.02))
            meat.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.56), control: CGPoint(x: w * 0.06, y: h * 0.66))
            meat.closeSubpath()
            ctx.fill(meat, with: .color(roast))
            ctx.stroke(meat, with: .color(Pack7Palette.stroke), lineWidth: lw)

            // bone: shaft + two knuckle circles
            var shaft = Path()
            shaft.move(to: CGPoint(x: w * 0.56, y: h * 0.54))
            shaft.addLine(to: CGPoint(x: w * 0.76, y: h * 0.76))
            ctx.stroke(shaft, with: .color(Pack7Palette.cream), style: StrokeStyle(lineWidth: w * 0.08, lineCap: .round))
            ctx.stroke(shaft, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.5)
            for (fx, fy) in [(0.76, 0.68), (0.68, 0.8)] {
                let knuckle = Path(ellipseIn: CGRect(x: w * CGFloat(fx), y: h * CGFloat(fy), width: w * 0.13, height: w * 0.13))
                ctx.fill(knuckle, with: .color(Pack7Palette.cream))
                ctx.stroke(knuckle, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.7)
            }
            // charm: gold glaze dot on the meat
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.3, y: h * 0.3, width: w * 0.07, height: w * 0.07)),
                     with: .color(Pack7Palette.gold))
        }
    }
}

// MARK: - 9. Shrimp — curled pair

struct ShrimpArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            let coral = Color(red: 0.94, green: 0.55, blue: 0.42)
            // two curled bodies: thick 240-degree arcs with tail fans
            let arcs: [(CGFloat, CGFloat, CGFloat)] = [(0.34, 0.36, 0.18), (0.64, 0.64, 0.16)]
            for (fx, fy, r) in arcs {
                let c = CGPoint(x: w * fx, y: h * fy)
                var bodyArc = Path()
                bodyArc.addArc(center: c, radius: w * r, startAngle: .degrees(-40),
                               endAngle: .degrees(200), clockwise: false)
                ctx.stroke(bodyArc, with: .color(coral), style: StrokeStyle(lineWidth: w * r * 0.7, lineCap: .round))
                // tail fan: small triangle at the arc's start
                let startRad: CGFloat = CGFloat(-40) * .pi / 180
                let tailAt = CGPoint(x: c.x + w * r * cos(startRad), y: c.y + w * r * sin(startRad))
                var tail = Path()
                tail.move(to: tailAt)
                tail.addLine(to: CGPoint(x: tailAt.x + w * 0.1, y: tailAt.y - h * 0.03))
                tail.addLine(to: CGPoint(x: tailAt.x + w * 0.06, y: tailAt.y + h * 0.07))
                tail.closeSubpath()
                ctx.fill(tail, with: .color(coral))
                ctx.stroke(tail, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.6)
            }
            // charm: gold eye dot on the front shrimp
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.18, y: h * 0.3, width: w * 0.05, height: w * 0.05)),
                     with: .color(Pack7Palette.gold))
        }
    }
}

// MARK: - 10. Salmon — fillet with grain lines (stands in for generic fish)

struct SalmonArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            let flesh = Color(red: 0.95, green: 0.55, blue: 0.42)
            // rounded fillet wedge: wide at left, narrowing right
            var fillet = Path()
            fillet.move(to: CGPoint(x: w * 0.14, y: h * 0.34))
            fillet.addQuadCurve(to: CGPoint(x: w * 0.86, y: h * 0.44), control: CGPoint(x: w * 0.55, y: h * 0.24))
            fillet.addQuadCurve(to: CGPoint(x: w * 0.8, y: h * 0.66), control: CGPoint(x: w * 0.9, y: h * 0.56))
            fillet.addQuadCurve(to: CGPoint(x: w * 0.14, y: h * 0.72), control: CGPoint(x: w * 0.45, y: h * 0.82))
            fillet.closeSubpath()
            ctx.fill(fillet, with: .color(flesh))
            ctx.stroke(fillet, with: .color(Pack7Palette.stroke), lineWidth: lw)

            // grain lines: cream arcs sweeping across the flesh
            for i in 0..<3 {
                let x = w * (0.3 + 0.18 * CGFloat(i))
                var grain = Path()
                grain.move(to: CGPoint(x: x, y: h * 0.36))
                grain.addQuadCurve(to: CGPoint(x: x - w * 0.06, y: h * 0.68), control: CGPoint(x: x - w * 0.12, y: h * 0.5))
                ctx.stroke(grain, with: .color(Pack7Palette.cream), lineWidth: lw)
            }
            // charm: gold dot at the thick end
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.2, y: h * 0.46, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack7Palette.gold))
        }
    }
}

// MARK: - 11. Tuna — squat can with ring pull

struct TunaCanArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            let tin = Color(red: 0.76, green: 0.79, blue: 0.82)
            // squat cylinder: short body + big lid ellipse
            let body = Path(CGRect(x: w * 0.18, y: h * 0.44, width: w * 0.64, height: h * 0.3))
            ctx.fill(body, with: .color(tin))
            ctx.stroke(body, with: .color(Pack7Palette.stroke), lineWidth: lw)
            let base = Path(ellipseIn: CGRect(x: w * 0.18, y: h * 0.62, width: w * 0.64, height: h * 0.24))
            ctx.fill(base, with: .color(tin))
            ctx.stroke(base, with: .color(Pack7Palette.stroke), lineWidth: lw)

            let lid = Path(ellipseIn: CGRect(x: w * 0.18, y: h * 0.3, width: w * 0.64, height: h * 0.28))
            ctx.fill(lid, with: .color(Color(red: 0.86, green: 0.88, blue: 0.9)))
            ctx.stroke(lid, with: .color(Pack7Palette.stroke), lineWidth: lw)

            // ring pull: gold ring + tab line (charm)
            let ring = Path(ellipseIn: CGRect(x: w * 0.44, y: h * 0.38, width: w * 0.14, height: h * 0.1))
            ctx.stroke(ring, with: .color(Pack7Palette.gold), lineWidth: lw * 1.2)
            var tab = Path()
            tab.move(to: CGPoint(x: w * 0.51, y: h * 0.38))
            tab.addLine(to: CGPoint(x: w * 0.51, y: h * 0.34))
            ctx.stroke(tab, with: .color(Pack7Palette.gold), lineWidth: lw)
        }
    }
}

// MARK: - 12. Tofu — block on tray, cubes cut

struct TofuArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            // shallow tray
            let tray = Path(roundedRect: CGRect(x: w * 0.12, y: h * 0.62, width: w * 0.76, height: h * 0.2),
                            cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(tray, with: .color(Color(red: 0.72, green: 0.78, blue: 0.82)))
            ctx.stroke(tray, with: .color(Pack7Palette.stroke), lineWidth: lw)

            // main block, still uncut
            let block = Path(roundedRect: CGRect(x: w * 0.18, y: h * 0.34, width: w * 0.42, height: h * 0.3),
                             cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(block, with: .color(.white.opacity(0.95)))
            ctx.stroke(block, with: .color(Pack7Palette.stroke), lineWidth: lw)

            // two cut cubes beside the block
            for (fx, fy) in [(0.64, 0.46), (0.74, 0.5)] {
                let cube = Path(roundedRect: CGRect(x: w * CGFloat(fx), y: h * CGFloat(fy), width: w * 0.13, height: w * 0.13),
                                cornerSize: CGSize(width: w * 0.02, height: w * 0.02))
                ctx.fill(cube, with: .color(.white.opacity(0.95)))
                ctx.stroke(cube, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.8)
            }
            // cut line on the block face
            var cut = Path()
            cut.move(to: CGPoint(x: w * 0.39, y: h * 0.34))
            cut.addLine(to: CGPoint(x: w * 0.39, y: h * 0.64))
            ctx.stroke(cut, with: .color(Pack7Palette.ink.opacity(0.2)), lineWidth: lw * 0.7)
            // charm: gold sesame dot on the tray lip
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.68, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack7Palette.gold))
        }
    }
}

// MARK: - 13. Matcha — green tin with whisk dot

struct MatchaArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack7Palette.line(size)
            let matcha = Color(red: 0.45, green: 0.62, blue: 0.4)
            let body = Path(roundedRect: CGRect(x: w * 0.28, y: h * 0.3, width: w * 0.44, height: h * 0.56),
                            cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(body, with: .color(matcha))
            ctx.stroke(body, with: .color(Pack7Palette.stroke), lineWidth: lw)

            let lid = Path(roundedRect: CGRect(x: w * 0.26, y: h * 0.18, width: w * 0.48, height: h * 0.12),
                           cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(lid, with: .color(Color(red: 0.32, green: 0.46, blue: 0.3)))
            ctx.stroke(lid, with: .color(Pack7Palette.stroke), lineWidth: lw)

            let label = Path(roundedRect: CGRect(x: w * 0.36, y: h * 0.46, width: w * 0.28, height: h * 0.24),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Pack7Palette.cream))
            ctx.stroke(label, with: .color(Pack7Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold whisk dot — dot with tiny tines fanning up
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.58, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack7Palette.gold))
            for dx in [CGFloat(-0.03), 0, 0.03] {
                var tine = Path()
                tine.move(to: CGPoint(x: w * (0.5 + dx * 0.5), y: h * 0.58))
                tine.addLine(to: CGPoint(x: w * (0.5 + dx), y: h * 0.52))
                ctx.stroke(tine, with: .color(Pack7Palette.gold), lineWidth: lw * 0.7)
            }
        }
    }
}

// MARK: - 14/15. Chili powder & paprika — shared spice jar, different powder

struct ChiliPowderArt: View {
    var body: some View {
        SpiceJarCanvas(powder: Color(red: 0.78, green: 0.24, blue: 0.18))
    }
}

struct PaprikaArt: View {
    var body: some View {
        SpiceJarCanvas(powder: Color(red: 0.72, green: 0.34, blue: 0.16))
    }
}

// MARK: - 16-19. The herb rack — shared jar, different green + leaf mark

struct OreganoArt: View {
    var body: some View {
        HerbJarCanvas(green: Color(red: 0.45, green: 0.55, blue: 0.35))
    }
}

struct BasilArt: View {
    var body: some View {
        HerbJarCanvas(green: Color(red: 0.32, green: 0.6, blue: 0.36), fresh: true)
    }
}

struct ParsleyArt: View {
    var body: some View {
        HerbJarCanvas(green: Color(red: 0.4, green: 0.65, blue: 0.42))
    }
}

struct RosemaryArt: View {
    var body: some View {
        HerbJarCanvas(green: Color(red: 0.42, green: 0.52, blue: 0.44), sprig: true)
    }
}

// MARK: - Registration table

enum Pack7Registry {
    /// exact lowercase names (including common plurals/variants) -> art
    static let exact: [String: () -> AnyView] = [
        "yogurt": { AnyView(YogurtArt()) },
        "greek yogurt": { AnyView(YogurtArt()) },
        "plain yogurt": { AnyView(YogurtArt()) },
        "ice cream": { AnyView(IceCreamArt()) },
        "vanilla ice cream": { AnyView(IceCreamArt()) },
        "coconut milk": { AnyView(CoconutMilkArt()) },
        "almond milk": { AnyView(AlmondMilkArt()) },
        "oat milk": { AnyView(AlmondMilkArt()) },
        "bacon": { AnyView(BaconArt()) },
        "sausage": { AnyView(SausageArt()) },
        "sausages": { AnyView(SausageArt()) },
        "ham": { AnyView(HamArt()) },
        "turkey": { AnyView(TurkeyArt()) },
        "ground turkey": { AnyView(TurkeyArt()) },
        "shrimp": { AnyView(ShrimpArt()) },
        "prawns": { AnyView(ShrimpArt()) },
        "salmon": { AnyView(SalmonArt()) },
        "fish": { AnyView(SalmonArt()) },
        "tuna": { AnyView(TunaCanArt()) },
        "canned tuna": { AnyView(TunaCanArt()) },
        "tofu": { AnyView(TofuArt()) },
        "matcha": { AnyView(MatchaArt()) },
        "chili powder": { AnyView(ChiliPowderArt()) },
        "chilli powder": { AnyView(ChiliPowderArt()) },
        "paprika": { AnyView(PaprikaArt()) },
        "smoked paprika": { AnyView(PaprikaArt()) },
        "oregano": { AnyView(OreganoArt()) },
        "dried oregano": { AnyView(OreganoArt()) },
        "basil": { AnyView(BasilArt()) },
        "fresh basil": { AnyView(BasilArt()) },
        "dried basil": { AnyView(BasilArt()) },
        "parsley": { AnyView(ParsleyArt()) },
        "fresh parsley": { AnyView(ParsleyArt()) },
        "dried parsley": { AnyView(ParsleyArt()) },
        "rosemary": { AnyView(RosemaryArt()) },
        "thyme": { AnyView(RosemaryArt()) },
        "cayenne": { AnyView(ChiliPowderArt()) },
        "cumin": { AnyView(PaprikaArt()) },
        "turmeric": { AnyView(PaprikaArt()) },
        "chili flakes": { AnyView(ChiliPowderArt()) },
        "red pepper flakes": { AnyView(ChiliPowderArt()) },
    ]
    /// contains-keywords -> art. Keep keywords SPECIFIC (two words when one
    /// word would hijack unrelated ingredients). "ham" is exact-only above:
    /// as a contains-keyword it would hijack "graham crackers"/"hamburger".
    static let keywords: [(String, () -> AnyView)] = [
        ("red pepper flakes", { AnyView(ChiliPowderArt()) }),
        ("greek yogurt", { AnyView(YogurtArt()) }),
        ("coconut milk", { AnyView(CoconutMilkArt()) }),
        ("chili powder", { AnyView(ChiliPowderArt()) }),
        ("chilli powder", { AnyView(ChiliPowderArt()) }),
        ("almond milk", { AnyView(AlmondMilkArt()) }),
        ("chili flakes", { AnyView(ChiliPowderArt()) }),
        ("ice cream", { AnyView(IceCreamArt()) }),
        ("oat milk", { AnyView(AlmondMilkArt()) }),
        ("turmeric", { AnyView(PaprikaArt()) }),
        ("cayenne", { AnyView(ChiliPowderArt()) }),
        ("paprika", { AnyView(PaprikaArt()) }),
        ("oregano", { AnyView(OreganoArt()) }),
        ("rosemary", { AnyView(RosemaryArt()) }),
        ("parsley", { AnyView(ParsleyArt()) }),
        ("sausage", { AnyView(SausageArt()) }),
        ("turkey", { AnyView(TurkeyArt()) }),
        ("salmon", { AnyView(SalmonArt()) }),
        ("shrimp", { AnyView(ShrimpArt()) }),
        ("matcha", { AnyView(MatchaArt()) }),
        ("yogurt", { AnyView(YogurtArt()) }),
        ("bacon", { AnyView(BaconArt()) }),
        ("basil", { AnyView(BasilArt()) }),
        ("thyme", { AnyView(RosemaryArt()) }),
        ("cumin", { AnyView(PaprikaArt()) }),
        ("tofu", { AnyView(TofuArt()) }),
        ("tuna", { AnyView(TunaCanArt()) }),
    ]
}
