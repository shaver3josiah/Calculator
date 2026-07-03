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
        .frame(height: 140)
    }

    private var clampedFraction: Double {
        min(max(fraction, 0), 1)
    }
}
