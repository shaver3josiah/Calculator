import SwiftUI

// Pack 6 — sauces & the pantry shelf, same "storybook grocery" idiom as Pack 1.
// Normalized Canvas space (fractions of `size`), flat fills + strokes only,
// one warm/gold charm per item. No text, symbols, images, or app deps.

// MARK: - Shared palette + helpers

private enum Pack6Palette {
    static let kraft = Color(red: 0.85, green: 0.74, blue: 0.58)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.42)
    static let ink = Color(red: 0.33, green: 0.20, blue: 0.16)
    static let ketchupRed = Color(red: 0.83, green: 0.25, blue: 0.2)

    static var stroke: Color { ink.opacity(0.35) }

    /// Outline width: 2.8% of the smaller dimension, floored at 1.2pt.
    static func line(_ s: CGSize) -> CGFloat { max(1.2, min(s.width, s.height) * 0.028) }

    /// Tapered bag body (same recipe as Pack 1's bags) so kraft sacks match.
    static func bagBody(_ s: CGSize, top: CGFloat, bottom: CGFloat,
                        halfBottom: CGFloat, taper: CGFloat) -> Path {
        let w = s.width
        let midX = w / 2
        let hb = w * halfBottom
        let ht = hb * (1 - taper)
        let c = w * 0.05
        var p = Path()
        p.move(to: CGPoint(x: midX - ht, y: top))
        p.addLine(to: CGPoint(x: midX - hb, y: bottom - c))
        p.addQuadCurve(to: CGPoint(x: midX - hb + c, y: bottom), control: CGPoint(x: midX - hb, y: bottom))
        p.addLine(to: CGPoint(x: midX + hb - c, y: bottom))
        p.addQuadCurve(to: CGPoint(x: midX + hb, y: bottom - c), control: CGPoint(x: midX + hb, y: bottom))
        p.addLine(to: CGPoint(x: midX + ht, y: top))
        p.closeSubpath()
        return p
    }

    /// Shouldered bottle: straight neck, quad-curve shoulders, rounded base.
    static func bottleBody(_ s: CGSize, neckHalf: CGFloat, bodyHalf: CGFloat,
                           neckTop: CGFloat, shoulder: CGFloat, bottom: CGFloat) -> Path {
        let midX = s.width / 2
        let nh = s.width * neckHalf, bh = s.width * bodyHalf
        let c = s.width * 0.05
        let curve = s.height * 0.08
        var p = Path()
        p.move(to: CGPoint(x: midX - nh, y: neckTop))
        p.addLine(to: CGPoint(x: midX - nh, y: shoulder - curve))
        p.addQuadCurve(to: CGPoint(x: midX - bh, y: shoulder), control: CGPoint(x: midX - bh, y: shoulder - curve))
        p.addLine(to: CGPoint(x: midX - bh, y: bottom - c))
        p.addQuadCurve(to: CGPoint(x: midX - bh + c, y: bottom), control: CGPoint(x: midX - bh, y: bottom))
        p.addLine(to: CGPoint(x: midX + bh - c, y: bottom))
        p.addQuadCurve(to: CGPoint(x: midX + bh, y: bottom - c), control: CGPoint(x: midX + bh, y: bottom))
        p.addLine(to: CGPoint(x: midX + bh, y: shoulder))
        p.addQuadCurve(to: CGPoint(x: midX + nh, y: shoulder - curve), control: CGPoint(x: midX + bh, y: shoulder - curve))
        p.addLine(to: CGPoint(x: midX + nh, y: neckTop))
        p.closeSubpath()
        return p
    }
}

/// Ketchup and mustard share one squeeze-bottle drawing; only colors change.
private struct SqueezeBottleCanvas: View {
    let fill: Color
    let labelColor: Color

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let body = Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.28, width: w * 0.4, height: h * 0.6),
                            cornerSize: CGSize(width: w * 0.08, height: w * 0.08))
            ctx.fill(body, with: .color(fill))
            ctx.stroke(body, with: .color(Pack6Palette.stroke), lineWidth: lw)

            // nozzle cone + tip
            var cone = Path()
            cone.move(to: CGPoint(x: w * 0.36, y: h * 0.28))
            cone.addLine(to: CGPoint(x: w * 0.46, y: h * 0.14))
            cone.addLine(to: CGPoint(x: w * 0.54, y: h * 0.14))
            cone.addLine(to: CGPoint(x: w * 0.64, y: h * 0.28))
            cone.closeSubpath()
            ctx.fill(cone, with: .color(fill))
            ctx.stroke(cone, with: .color(Pack6Palette.stroke), lineWidth: lw)
            let tip = Path(roundedRect: CGRect(x: w * 0.455, y: h * 0.07, width: w * 0.09, height: h * 0.07),
                           cornerSize: CGSize(width: w * 0.02, height: w * 0.02))
            ctx.fill(tip, with: .color(fill))
            ctx.stroke(tip, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)

            let label = Path(roundedRect: CGRect(x: w * 0.36, y: h * 0.44, width: w * 0.28, height: h * 0.24),
                             cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(label, with: .color(labelColor))
            ctx.stroke(label, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold dot on label
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.52, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack6Palette.gold))
        }
    }
}

// MARK: - 1. Ketchup — red squeeze bottle

struct KetchupArt: View {
    var body: some View {
        SqueezeBottleCanvas(fill: Pack6Palette.ketchupRed, labelColor: Pack6Palette.cream)
    }
}

// MARK: - 2. Mustard — yellow squeeze bottle

struct MustardArt: View {
    var body: some View {
        SqueezeBottleCanvas(fill: Color(red: 0.93, green: 0.76, blue: 0.28), labelColor: Pack6Palette.cream)
    }
}

// MARK: - 3. Mayo — squat jar, cream fill, wide lid

struct MayoArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let jar = Path(roundedRect: CGRect(x: w * 0.26, y: h * 0.3, width: w * 0.48, height: h * 0.58),
                           cornerSize: CGSize(width: w * 0.08, height: w * 0.08))
            ctx.fill(jar, with: .color(Pack6Palette.cream))
            ctx.stroke(jar, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let lid = Path(roundedRect: CGRect(x: w * 0.24, y: h * 0.16, width: w * 0.52, height: h * 0.14),
                           cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(lid, with: .color(Color(red: 0.62, green: 0.68, blue: 0.74)))
            ctx.stroke(lid, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let label = Path(roundedRect: CGRect(x: w * 0.32, y: h * 0.46, width: w * 0.36, height: h * 0.26),
                             cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(label, with: .color(Color(red: 0.85, green: 0.9, blue: 0.95)))
            ctx.stroke(label, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold dot on label
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.55, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack6Palette.gold))
        }
    }
}

// MARK: - 4. Soy sauce — little dark bottle, red cap

struct SoySauceArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let body = Pack6Palette.bottleBody(size, neckHalf: 0.08, bodyHalf: 0.2,
                                               neckTop: h * 0.2, shoulder: h * 0.42, bottom: h * 0.88)
            ctx.fill(body, with: .color(Color(red: 0.26, green: 0.18, blue: 0.14)))
            ctx.stroke(body, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let cap = Path(roundedRect: CGRect(x: w * 0.4, y: h * 0.1, width: w * 0.2, height: h * 0.12),
                           cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(cap, with: .color(Pack6Palette.ketchupRed))
            ctx.stroke(cap, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)

            let label = Path(roundedRect: CGRect(x: w * 0.36, y: h * 0.52, width: w * 0.28, height: h * 0.22),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Pack6Palette.cream))
            ctx.stroke(label, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold dot on label
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.59, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack6Palette.gold))
        }
    }
}

// MARK: - 5. Vinegar — tall slim bottle, pale fill line

struct VinegarArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let body = Pack6Palette.bottleBody(size, neckHalf: 0.07, bodyHalf: 0.16,
                                               neckTop: h * 0.14, shoulder: h * 0.4, bottom: h * 0.9)
            ctx.fill(body, with: .color(Color(red: 0.93, green: 0.93, blue: 0.88)))
            ctx.stroke(body, with: .color(Pack6Palette.stroke), lineWidth: lw)

            // liquid line inside the body (flat fill, no gradient)
            ctx.fill(Path(CGRect(x: w * 0.34, y: h * 0.52, width: w * 0.32, height: h * 0.34)),
                     with: .color(Color(red: 0.96, green: 0.88, blue: 0.7).opacity(0.8)))

            let cap = Path(roundedRect: CGRect(x: w * 0.42, y: h * 0.06, width: w * 0.16, height: h * 0.09),
                           cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(cap, with: .color(Pack6Palette.kraft))
            ctx.stroke(cap, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold droplet dot at the shoulder
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.43, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack6Palette.gold))
        }
    }
}

// MARK: - 6. Hot sauce — small bottle, fiery label dot

struct HotSauceArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let body = Pack6Palette.bottleBody(size, neckHalf: 0.08, bodyHalf: 0.17,
                                               neckTop: h * 0.24, shoulder: h * 0.46, bottom: h * 0.88)
            ctx.fill(body, with: .color(Color(red: 0.87, green: 0.36, blue: 0.22)))
            ctx.stroke(body, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let cap = Path(roundedRect: CGRect(x: w * 0.41, y: h * 0.14, width: w * 0.18, height: h * 0.12),
                           cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(cap, with: .color(Color(red: 0.4, green: 0.55, blue: 0.35)))
            ctx.stroke(cap, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)

            let label = Path(roundedRect: CGRect(x: w * 0.37, y: h * 0.54, width: w * 0.26, height: h * 0.22),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Pack6Palette.cream))
            ctx.stroke(label, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)
            // charm: fiery red-on-gold dot pair
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.44, y: h * 0.59, width: w * 0.12, height: w * 0.12)),
                     with: .color(Pack6Palette.gold))
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.47, y: h * 0.605, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack6Palette.ketchupRed))
        }
    }
}

// MARK: - 7. BBQ sauce — rounded wide bottle, dark fill

struct BBQSauceArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let body = Pack6Palette.bottleBody(size, neckHalf: 0.1, bodyHalf: 0.26,
                                               neckTop: h * 0.18, shoulder: h * 0.4, bottom: h * 0.88)
            ctx.fill(body, with: .color(Color(red: 0.36, green: 0.2, blue: 0.13)))
            ctx.stroke(body, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let cap = Path(roundedRect: CGRect(x: w * 0.38, y: h * 0.08, width: w * 0.24, height: h * 0.12),
                           cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(cap, with: .color(Pack6Palette.ink))
            ctx.stroke(cap, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)

            let label = Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.5, width: w * 0.4, height: h * 0.26),
                             cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(label, with: .color(Pack6Palette.kraft))
            ctx.stroke(label, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold flame-ish dot on label
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.45, y: h * 0.58, width: w * 0.1, height: w * 0.1)),
                     with: .color(Pack6Palette.gold))
        }
    }
}

// MARK: - 8. Broth — gable-top carton, steam curl on label

struct BrothArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let box = Path(CGRect(x: w * 0.28, y: h * 0.3, width: w * 0.44, height: h * 0.58))
            ctx.fill(box, with: .color(Pack6Palette.cream))
            ctx.stroke(box, with: .color(Pack6Palette.stroke), lineWidth: lw)

            // gabled roof with a ridge cap
            var roof = Path()
            roof.move(to: CGPoint(x: w * 0.28, y: h * 0.3))
            roof.addLine(to: CGPoint(x: w * 0.5, y: h * 0.12))
            roof.addLine(to: CGPoint(x: w * 0.72, y: h * 0.3))
            roof.closeSubpath()
            ctx.fill(roof, with: .color(Pack6Palette.kraft))
            ctx.stroke(roof, with: .color(Pack6Palette.stroke), lineWidth: lw)
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.44, y: h * 0.08, width: w * 0.12, height: h * 0.06),
                          cornerSize: CGSize(width: w * 0.02, height: w * 0.02)),
                     with: .color(Pack6Palette.gold))

            let label = Path(roundedRect: CGRect(x: w * 0.34, y: h * 0.44, width: w * 0.32, height: h * 0.3),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Color(red: 0.96, green: 0.85, blue: 0.6)))
            ctx.stroke(label, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)
            // charm: rising steam curl on the label
            var steam = Path()
            steam.move(to: CGPoint(x: w * 0.5, y: h * 0.68))
            steam.addQuadCurve(to: CGPoint(x: w * 0.46, y: h * 0.58), control: CGPoint(x: w * 0.4, y: h * 0.64))
            steam.addQuadCurve(to: CGPoint(x: w * 0.54, y: h * 0.5), control: CGPoint(x: w * 0.58, y: h * 0.56))
            ctx.stroke(steam, with: .color(Pack6Palette.ink.opacity(0.5)), lineWidth: lw)
        }
    }
}

// MARK: - 9. Coconut oil — short glass jar, white fill

struct CoconutOilArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let jar = Path(roundedRect: CGRect(x: w * 0.24, y: h * 0.34, width: w * 0.52, height: h * 0.52),
                           cornerSize: CGSize(width: w * 0.07, height: w * 0.07))
            // white oil visible through the glass
            ctx.fill(jar, with: .color(.white.opacity(0.9)))
            ctx.stroke(jar, with: .color(Pack6Palette.stroke), lineWidth: lw)

            // glass headroom band above the fill line
            ctx.fill(Path(CGRect(x: w * 0.24, y: h * 0.34, width: w * 0.52, height: h * 0.1)),
                     with: .color(Color(red: 0.9, green: 0.94, blue: 0.95)))
            var fillLine = Path()
            fillLine.move(to: CGPoint(x: w * 0.24, y: h * 0.44))
            fillLine.addLine(to: CGPoint(x: w * 0.76, y: h * 0.44))
            ctx.stroke(fillLine, with: .color(Pack6Palette.ink.opacity(0.2)), lineWidth: lw * 0.6)

            let lid = Path(roundedRect: CGRect(x: w * 0.22, y: h * 0.2, width: w * 0.56, height: h * 0.14),
                           cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(lid, with: .color(Pack6Palette.kraft))
            ctx.stroke(lid, with: .color(Pack6Palette.stroke), lineWidth: lw)
            // charm: gold dot centered on the lid
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.24, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack6Palette.gold))
        }
    }
}

// MARK: - 10. Cornstarch — box with spoon symbol

struct CornstarchArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let box = Path(roundedRect: CGRect(x: w * 0.26, y: h * 0.18, width: w * 0.48, height: h * 0.68),
                           cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(box, with: .color(Color(red: 0.96, green: 0.93, blue: 0.82)))
            ctx.stroke(box, with: .color(Pack6Palette.stroke), lineWidth: lw)

            // thin top-flap band
            ctx.fill(Path(CGRect(x: w * 0.26, y: h * 0.18, width: w * 0.48, height: h * 0.08)),
                     with: .color(Pack6Palette.ink.opacity(0.08)))
            var flap = Path()
            flap.move(to: CGPoint(x: w * 0.26, y: h * 0.26))
            flap.addLine(to: CGPoint(x: w * 0.74, y: h * 0.26))
            ctx.stroke(flap, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.7)

            // spoon symbol: bowl ellipse + handle line
            let bowl = Path(ellipseIn: CGRect(x: w * 0.4, y: h * 0.38, width: w * 0.2, height: h * 0.16))
            ctx.fill(bowl, with: .color(Pack6Palette.cream))
            ctx.stroke(bowl, with: .color(Pack6Palette.ink.opacity(0.5)), lineWidth: lw * 0.8)
            var handle = Path()
            handle.move(to: CGPoint(x: w * 0.5, y: h * 0.54))
            handle.addLine(to: CGPoint(x: w * 0.5, y: h * 0.76))
            ctx.stroke(handle, with: .color(Pack6Palette.ink.opacity(0.5)), lineWidth: lw)
            // charm: gold dot in the spoon bowl
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.42, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack6Palette.gold))
        }
    }
}

// MARK: - 11. Cornmeal — kraft bag, golden grains

struct CornmealArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let body = Pack6Palette.bagBody(size, top: h * 0.24, bottom: h * 0.9, halfBottom: 0.32, taper: 0.16)
            ctx.fill(body, with: .color(Pack6Palette.kraft))
            ctx.stroke(body, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let roll = Path(roundedRect: CGRect(x: w * 0.24, y: h * 0.1, width: w * 0.52, height: h * 0.16),
                            cornerSize: CGSize(width: h * 0.08, height: h * 0.08))
            ctx.fill(roll, with: .color(Pack6Palette.kraft))
            ctx.fill(roll, with: .color(Pack6Palette.ink.opacity(0.08)))
            ctx.stroke(roll, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let label = Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.46, width: w * 0.4, height: h * 0.28),
                             cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(label, with: .color(Pack6Palette.cream))
            ctx.stroke(label, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)
            // charm: scattered golden grain dots on the label
            let pts: [(CGFloat, CGFloat)] = [(0.4, 0.53), (0.5, 0.5), (0.6, 0.55), (0.44, 0.62), (0.56, 0.66)]
            for (fx, fy) in pts {
                ctx.fill(Path(ellipseIn: CGRect(x: w * fx - w * 0.025, y: h * fy - w * 0.025, width: w * 0.05, height: w * 0.05)),
                         with: .color(Pack6Palette.gold))
            }
        }
    }
}

// MARK: - 12. Breadcrumbs — canister, crumb speckle band

struct BreadcrumbsArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let body = Path(roundedRect: CGRect(x: w * 0.28, y: h * 0.2, width: w * 0.44, height: h * 0.68),
                            cornerSize: CGSize(width: w * 0.06, height: w * 0.06))
            ctx.fill(body, with: .color(Pack6Palette.cream))
            ctx.stroke(body, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let band = Path(CGRect(x: w * 0.28, y: h * 0.42, width: w * 0.44, height: h * 0.28))
            ctx.fill(band, with: .color(Pack6Palette.kraft.opacity(0.7)))
            ctx.stroke(band, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)

            let lid = Path(ellipseIn: CGRect(x: w * 0.26, y: h * 0.12, width: w * 0.48, height: h * 0.15))
            ctx.fill(lid, with: .color(Color(red: 0.72, green: 0.5, blue: 0.32)))
            ctx.stroke(lid, with: .color(Pack6Palette.stroke), lineWidth: lw)

            // charm: gold crumb speckles across the band
            let pts: [(CGFloat, CGFloat)] = [(0.38, 0.5), (0.5, 0.47), (0.6, 0.53), (0.44, 0.6), (0.56, 0.63)]
            for (fx, fy) in pts {
                ctx.fill(Path(ellipseIn: CGRect(x: w * fx - w * 0.02, y: h * fy - w * 0.02, width: w * 0.04, height: w * 0.04)),
                         with: .color(Pack6Palette.gold))
            }
        }
    }
}

// MARK: - 13. Tortillas — stack of rounds + one rolled

struct TortillasArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let tortilla = Color(red: 0.96, green: 0.9, blue: 0.76)
            // stack: three flattened ellipses
            for i in 0..<3 {
                let y = h * (0.78 - 0.09 * CGFloat(i))
                let disc = Path(ellipseIn: CGRect(x: w * 0.18, y: y, width: w * 0.64, height: h * 0.16))
                ctx.fill(disc, with: .color(tortilla))
                ctx.stroke(disc, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)
            }
            // one rolled tortilla resting on the stack
            let roll = Path(roundedRect: CGRect(x: w * 0.24, y: h * 0.36, width: w * 0.52, height: h * 0.18),
                            cornerSize: CGSize(width: h * 0.09, height: h * 0.09))
            ctx.fill(roll, with: .color(tortilla))
            ctx.stroke(roll, with: .color(Pack6Palette.stroke), lineWidth: lw)
            // spiral end of the roll
            let end = Path(ellipseIn: CGRect(x: w * 0.66, y: h * 0.37, width: w * 0.11, height: h * 0.16))
            ctx.fill(end, with: .color(Pack6Palette.cream))
            ctx.stroke(end, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold toast freckles on the roll
            for fx in [CGFloat(0.34), 0.46, 0.56] {
                ctx.fill(Path(ellipseIn: CGRect(x: w * fx, y: h * 0.43, width: w * 0.04, height: w * 0.04)),
                         with: .color(Pack6Palette.gold))
            }
        }
    }
}

// MARK: - 14. Bread — crusty loaf, scored top

struct BreadArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let crust = Color(red: 0.82, green: 0.6, blue: 0.34)
            // loaf: dome over a flat base
            var loaf = Path()
            loaf.move(to: CGPoint(x: w * 0.14, y: h * 0.78))
            loaf.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.26), control: CGPoint(x: w * 0.12, y: h * 0.3))
            loaf.addQuadCurve(to: CGPoint(x: w * 0.86, y: h * 0.78), control: CGPoint(x: w * 0.88, y: h * 0.3))
            loaf.addQuadCurve(to: CGPoint(x: w * 0.14, y: h * 0.78), control: CGPoint(x: w * 0.5, y: h * 0.9))
            loaf.closeSubpath()
            ctx.fill(loaf, with: .color(crust))
            ctx.stroke(loaf, with: .color(Pack6Palette.stroke), lineWidth: lw)

            // scored top: three short diagonal slashes
            for i in 0..<3 {
                let x = w * (0.34 + 0.14 * CGFloat(i))
                var cut = Path()
                cut.move(to: CGPoint(x: x, y: h * 0.42))
                cut.addLine(to: CGPoint(x: x + w * 0.08, y: h * 0.5))
                ctx.stroke(cut, with: .color(Pack6Palette.cream), lineWidth: lw)
            }
            // charm: gold flour-dust dot near the heel
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.24, y: h * 0.62, width: w * 0.07, height: w * 0.07)),
                     with: .color(Pack6Palette.gold))
        }
    }
}

// MARK: - 15. Bagel — golden ring with seeds

struct BagelArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let dough = Color(red: 0.88, green: 0.68, blue: 0.4)
            let outer = Path(ellipseIn: CGRect(x: w * 0.14, y: h * 0.18, width: w * 0.72, height: h * 0.64))
            ctx.fill(outer, with: .color(dough))
            ctx.stroke(outer, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let hole = Path(ellipseIn: CGRect(x: w * 0.4, y: h * 0.42, width: w * 0.2, height: h * 0.18))
            ctx.fill(hole, with: .color(Pack6Palette.cream))
            ctx.stroke(hole, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)

            // charm: gold seed dashes around the crown
            let seeds: [(CGFloat, CGFloat, CGFloat)] = [(0.3, 0.32, -0.4), (0.44, 0.26, 0.0),
                                                        (0.58, 0.28, 0.3), (0.7, 0.38, 0.6), (0.26, 0.46, -0.7)]
            for (fx, fy, angle) in seeds {
                var seed = Path()
                let cx = w * fx, cy = h * fy, r = w * 0.035
                seed.move(to: CGPoint(x: cx - r * cos(angle), y: cy - r * sin(angle)))
                seed.addLine(to: CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle)))
                ctx.stroke(seed, with: .color(Pack6Palette.gold), lineWidth: lw)
            }
        }
    }
}

// MARK: - 16. Crackers — box with one square cracker out

struct CrackersArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let box = Path(roundedRect: CGRect(x: w * 0.18, y: h * 0.22, width: w * 0.46, height: h * 0.64),
                           cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(box, with: .color(Color(red: 0.78, green: 0.32, blue: 0.3)))
            ctx.stroke(box, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let label = Path(roundedRect: CGRect(x: w * 0.24, y: h * 0.4, width: w * 0.34, height: h * 0.26),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Pack6Palette.cream))
            ctx.stroke(label, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)

            // one cracker leaning out beside the box
            let cracker = Path(roundedRect: CGRect(x: w * 0.6, y: h * 0.52, width: w * 0.28, height: w * 0.28),
                               cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(cracker, with: .color(Color(red: 0.93, green: 0.8, blue: 0.55)))
            ctx.stroke(cracker, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)
            // docking holes on the cracker
            for (fx, fy) in [(0.68, 0.6), (0.78, 0.6), (0.68, 0.7), (0.78, 0.7)] {
                ctx.fill(Path(ellipseIn: CGRect(x: w * CGFloat(fx), y: h * CGFloat(fy), width: w * 0.025, height: w * 0.025)),
                         with: .color(Pack6Palette.ink.opacity(0.35)))
            }
            // charm: gold dot on the box label
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.37, y: h * 0.49, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack6Palette.gold))
        }
    }
}

// MARK: - 17. Beans — tin can with bean label

struct BeansCanArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let tin = Color(red: 0.76, green: 0.79, blue: 0.82)
            let body = Path(CGRect(x: w * 0.26, y: h * 0.22, width: w * 0.48, height: h * 0.62))
            ctx.fill(body, with: .color(tin))
            ctx.stroke(body, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let lid = Path(ellipseIn: CGRect(x: w * 0.24, y: h * 0.14, width: w * 0.52, height: h * 0.15))
            ctx.fill(lid, with: .color(Color(red: 0.66, green: 0.69, blue: 0.72)))
            ctx.stroke(lid, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let label = Path(CGRect(x: w * 0.26, y: h * 0.4, width: w * 0.48, height: h * 0.3))
            ctx.fill(label, with: .color(Pack6Palette.cream))
            ctx.stroke(label, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)

            // three bean ovals on the label
            let bean = Color(red: 0.55, green: 0.24, blue: 0.2)
            for (fx, fy) in [(0.36, 0.48), (0.48, 0.55), (0.58, 0.47)] {
                let b = Path(ellipseIn: CGRect(x: w * CGFloat(fx), y: h * CGFloat(fy), width: w * 0.1, height: h * 0.07))
                ctx.fill(b, with: .color(bean))
            }
            // charm: gold rim highlight dot on the lid
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.17, width: w * 0.08, height: w * 0.05)),
                     with: .color(Pack6Palette.gold))
        }
    }
}

// MARK: - 18. Lentils — kraft bag, tiny discs spilling (also stands in for quinoa)

struct LentilsArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack6Palette.line(size)
            let body = Pack6Palette.bagBody(size, top: h * 0.22, bottom: h * 0.82, halfBottom: 0.3, taper: 0.14)
            ctx.fill(body, with: .color(Pack6Palette.kraft))
            ctx.stroke(body, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let flap = Path(roundedRect: CGRect(x: w * 0.26, y: h * 0.1, width: w * 0.48, height: h * 0.14),
                            cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(flap, with: .color(Pack6Palette.kraft))
            ctx.fill(flap, with: .color(Pack6Palette.ink.opacity(0.08)))
            ctx.stroke(flap, with: .color(Pack6Palette.stroke), lineWidth: lw)

            let label = Path(roundedRect: CGRect(x: w * 0.32, y: h * 0.4, width: w * 0.36, height: h * 0.24),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Pack6Palette.cream))
            ctx.stroke(label, with: .color(Pack6Palette.stroke), lineWidth: lw * 0.8)

            // tiny lentil discs spilling by the bag's foot
            let lentil = Color(red: 0.68, green: 0.42, blue: 0.24)
            let pts: [(CGFloat, CGFloat)] = [(0.66, 0.86), (0.74, 0.9), (0.82, 0.85), (0.7, 0.94), (0.6, 0.92)]
            for (fx, fy) in pts {
                let d = Path(ellipseIn: CGRect(x: w * fx - w * 0.03, y: h * fy - w * 0.02, width: w * 0.06, height: w * 0.04))
                ctx.fill(d, with: .color(lentil))
                ctx.stroke(d, with: .color(Pack6Palette.ink.opacity(0.25)), lineWidth: max(0.6, lw * 0.4))
            }
            // charm: gold dot on label
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.48, width: w * 0.08, height: w * 0.08)),
                     with: .color(Pack6Palette.gold))
        }
    }
}

// MARK: - Registration table

enum Pack6Registry {
    /// exact lowercase names (including common plurals/variants) -> art
    static let exact: [String: () -> AnyView] = [
        "ketchup": { AnyView(KetchupArt()) },
        "mustard": { AnyView(MustardArt()) },
        "mayo": { AnyView(MayoArt()) },
        "mayonnaise": { AnyView(MayoArt()) },
        "soy sauce": { AnyView(SoySauceArt()) },
        "vinegar": { AnyView(VinegarArt()) },
        "white vinegar": { AnyView(VinegarArt()) },
        "apple cider vinegar": { AnyView(VinegarArt()) },
        "hot sauce": { AnyView(HotSauceArt()) },
        "bbq sauce": { AnyView(BBQSauceArt()) },
        "barbecue sauce": { AnyView(BBQSauceArt()) },
        "broth": { AnyView(BrothArt()) },
        "stock": { AnyView(BrothArt()) },
        "chicken broth": { AnyView(BrothArt()) },
        "beef broth": { AnyView(BrothArt()) },
        "vegetable broth": { AnyView(BrothArt()) },
        "chicken stock": { AnyView(BrothArt()) },
        "coconut oil": { AnyView(CoconutOilArt()) },
        "cornstarch": { AnyView(CornstarchArt()) },
        "corn starch": { AnyView(CornstarchArt()) },
        "cornmeal": { AnyView(CornmealArt()) },
        "corn meal": { AnyView(CornmealArt()) },
        "breadcrumbs": { AnyView(BreadcrumbsArt()) },
        "bread crumbs": { AnyView(BreadcrumbsArt()) },
        "panko": { AnyView(BreadcrumbsArt()) },
        "tortilla": { AnyView(TortillasArt()) },
        "tortillas": { AnyView(TortillasArt()) },
        "bread": { AnyView(BreadArt()) },
        "white bread": { AnyView(BreadArt()) },
        "whole wheat bread": { AnyView(BreadArt()) },
        "bagel": { AnyView(BagelArt()) },
        "bagels": { AnyView(BagelArt()) },
        "crackers": { AnyView(CrackersArt()) },
        "beans": { AnyView(BeansCanArt()) },
        "black beans": { AnyView(BeansCanArt()) },
        "kidney beans": { AnyView(BeansCanArt()) },
        "pinto beans": { AnyView(BeansCanArt()) },
        "chickpeas": { AnyView(BeansCanArt()) },
        "garbanzo beans": { AnyView(BeansCanArt()) },
        "lentils": { AnyView(LentilsArt()) },
        "quinoa": { AnyView(LentilsArt()) },
    ]
    /// contains-keywords -> art. Keep keywords SPECIFIC (two words when one word would hijack unrelated ingredients).
    static let keywords: [(String, () -> AnyView)] = [
        ("apple cider vinegar", { AnyView(VinegarArt()) }),
        ("barbecue sauce", { AnyView(BBQSauceArt()) }),
        ("chicken broth", { AnyView(BrothArt()) }),
        ("beef broth", { AnyView(BrothArt()) }),
        ("vegetable broth", { AnyView(BrothArt()) }),
        ("chicken stock", { AnyView(BrothArt()) }),
        ("coconut oil", { AnyView(CoconutOilArt()) }),
        ("cornstarch", { AnyView(CornstarchArt()) }),
        ("corn starch", { AnyView(CornstarchArt()) }),
        ("breadcrumb", { AnyView(BreadcrumbsArt()) }),
        ("bread crumb", { AnyView(BreadcrumbsArt()) }),
        ("soy sauce", { AnyView(SoySauceArt()) }),
        ("hot sauce", { AnyView(HotSauceArt()) }),
        ("bbq sauce", { AnyView(BBQSauceArt()) }),
        ("tortilla", { AnyView(TortillasArt()) }),
        ("cornmeal", { AnyView(CornmealArt()) }),
        ("corn meal", { AnyView(CornmealArt()) }),
        ("mayonnaise", { AnyView(MayoArt()) }),
        ("chickpea", { AnyView(BeansCanArt()) }),
        ("garbanzo", { AnyView(BeansCanArt()) }),
        ("ketchup", { AnyView(KetchupArt()) }),
        ("mustard", { AnyView(MustardArt()) }),
        ("vinegar", { AnyView(VinegarArt()) }),
        ("cracker", { AnyView(CrackersArt()) }),
        ("lentil", { AnyView(LentilsArt()) }),
        ("quinoa", { AnyView(LentilsArt()) }),
        ("bagel", { AnyView(BagelArt()) }),
        ("panko", { AnyView(BreadcrumbsArt()) }),
        ("broth", { AnyView(BrothArt()) }),
        ("stock", { AnyView(BrothArt()) }),
        ("beans", { AnyView(BeansCanArt()) }),
        ("bread", { AnyView(BreadArt()) }),
        ("mayo", { AnyView(MayoArt()) }),
    ]
}
