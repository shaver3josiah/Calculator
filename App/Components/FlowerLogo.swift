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
