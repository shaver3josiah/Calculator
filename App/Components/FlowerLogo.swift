import SwiftUI

struct FlowerLogo: View {
    @Environment(ThemeStore.self) private var themeStore
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            FlowerPetals()
                .fill(
                    LinearGradient(
                        colors: [themeStore.color("primary"), themeStore.color("primaryStrong")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Circle()
                .fill(themeStore.color("flowerCenter"))
                .frame(width: size * 0.26, height: size * 0.26)
        }
        .frame(width: size, height: size)
    }
}

private struct FlowerPetals: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let petalLength = rect.width * 0.34
        let petalWidth = rect.width * 0.22

        for i in 0..<5 {
            let angle = Angle(degrees: Double(i) * 72)
            let petalCenter = CGPoint(
                x: center.x + petalLength * 0.55 * cos(angle.radians - .pi / 2),
                y: center.y + petalLength * 0.55 * sin(angle.radians - .pi / 2)
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
