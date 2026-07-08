import SwiftUI

struct VesselOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let rimInset = w * 0.06
        let baseInset = w * 0.16

        path.move(to: CGPoint(x: rect.minX + rimInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rimInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - baseInset, y: rect.maxY - h * 0.08))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + baseInset, y: rect.maxY - h * 0.08),
            control: CGPoint(x: rect.midX, y: rect.maxY + h * 0.04)
        )
        path.addLine(to: CGPoint(x: rect.minX + rimInset, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct VesselFill: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let fraction: Double
    var height: CGFloat = 140

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VesselOutline()
                    .fill(theme.color("surface"))
                VesselOutline()
                    .stroke(theme.color("line"), lineWidth: 2)

                VesselOutline()
                    .fill(
                        LinearGradient(
                            colors: [theme.color("primary"), theme.color("primaryStrong")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask(alignment: .bottom) {
                        Rectangle()
                            .frame(height: geo.size.height * clampedFraction)
                    }
                    .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.85), value: fraction)

                VesselOutline()
                    .stroke(theme.color("deep").opacity(0.25), lineWidth: 1)
            }
        }
        .frame(height: height)
    }

    private var clampedFraction: Double {
        min(max(fraction, 0), 1)
    }
}

struct ScaleDial: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.34)
        let radius = rect.height * 0.3
        var path = Path()
        path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        return path
    }
}

struct ScaleBase: Shape {
    func path(in rect: CGRect) -> Path {
        let topY = rect.minY + rect.height * 0.62
        let bottomY = rect.maxY - rect.height * 0.06
        let topInset = rect.width * 0.32
        let bottomInset = rect.width * 0.22
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + topInset, y: topY))
        path.addLine(to: CGPoint(x: rect.maxX - topInset, y: topY))
        path.addLine(to: CGPoint(x: rect.maxX - bottomInset, y: bottomY))
        path.addLine(to: CGPoint(x: rect.minX + bottomInset, y: bottomY))
        path.closeSubpath()
        return path
    }
}

struct ScaleNeedle: Shape {
    var angleDegrees: Double

    var animatableData: Double {
        get { angleDegrees }
        set { angleDegrees = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.34)
        let radius = Double(rect.height) * 0.24
        let radians = angleDegrees * Double.pi / 180
        let dx = radius * sin(radians)
        let dy = radius * cos(radians)
        let tip = CGPoint(x: center.x + CGFloat(dx), y: center.y - CGFloat(dy))
        var path = Path()
        path.move(to: center)
        path.addLine(to: tip)
        return path
    }
}

struct ScaleFill: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let fraction: Double

    var body: some View {
        GeometryReader { _ in
            ZStack {
                ScaleBase()
                    .stroke(theme.color("line"), lineWidth: 2)
                ScaleDial()
                    .fill(theme.color("surface"))
                ScaleDial()
                    .stroke(theme.color("line"), lineWidth: 2)

                ScaleNeedle(angleDegrees: needleAngle)
                    .stroke(theme.color("primaryStrong"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.85), value: fraction)

                ScaleDial()
                    .stroke(theme.color("deep").opacity(0.25), lineWidth: 1)
            }
        }
        .frame(height: 140)
    }

    private var clampedFraction: Double {
        min(max(fraction, 0), 1)
    }

    private var needleAngle: Double {
        clampedFraction * 130
    }
}
