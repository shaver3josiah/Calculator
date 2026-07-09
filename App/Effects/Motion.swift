import SwiftUI

/// Shared motion tokens from the Bloom design system (see the Motion reference).
/// Durations are seconds; easings are the documented cubic-beziers so the app
/// matches the spec instead of scattering magic numbers across views.
enum BloomMotion {
    static let outlineDraw: Double = 0.72
    static let panelGlide: Double = 0.56
    static let shimmerHalf: Double = 1.7   // 3.4s breathe loop (autoreverses)

    /// Panel glide — expo-out, cubic-bezier(.16,1,.3,1).
    static let glide = Animation.timingCurve(0.16, 1, 0.3, 1, duration: panelGlide)
    /// Outline draw — cubic-bezier(.35,0,.15,1).
    static let draw = Animation.timingCurve(0.35, 0, 0.15, 1, duration: outlineDraw)
}

/// A glossy highlight band that sweeps once across on each `trigger` flip.
/// `intense` gives the darker-pink keys a brighter shine. Reduce-motion safe.
struct ShimmerSweep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let trigger: Bool
    var intense: Bool = false
    var cornerRadius: CGFloat = 12

    @State private var phase: CGFloat = -1.2

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            GeometryReader { geo in
                LinearGradient(
                    colors: [.clear, .white.opacity(intense ? 0.5 : 0.28), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: geo.size.width * 0.55)
                .rotationEffect(.degrees(18))
                .offset(x: phase * geo.size.width * 1.25)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .allowsHitTesting(false)
            .onChange(of: trigger) { _, _ in
                phase = -1.2
                withAnimation(.easeOut(duration: 0.5)) { phase = 1.2 }
            }
        }
    }
}

/// Ambient "jewel glint" for the single hero CTA (the `=` key). Deliberately a
/// low-contrast directional gloss that sweeps once, then rests ~4s — NOT a looping
/// opacity/breathe pulse (the AI-slop "breathing CTA" fingerprint). One element only,
/// gated behind the motion toggle + Reduce Motion, so it reads as specular material,
/// not a status indicator. See the motion-design debate in v0.1.19.
struct AmbientShimmer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var cornerRadius: CGFloat = 12
    private let period: Double = 5           // one glint every 5s
    private let sweepFraction: CGFloat = 0.22 // ~1.1s sweeping, ~3.9s parked off-screen

    @State private var t: CGFloat = 0

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            GeometryReader { geo in
                let sweep = min(t / sweepFraction, 1)   // races across, then holds off-screen right
                LinearGradient(
                    colors: [.clear, .white.opacity(0.2), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: geo.size.width * 0.5)
                .rotationEffect(.degrees(18))
                .offset(x: (-1.1 + sweep * 2.2) * geo.size.width)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.linear(duration: period).repeatForever(autoreverses: false)) {
                    t = 1
                }
            }
        }
    }
}
