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
