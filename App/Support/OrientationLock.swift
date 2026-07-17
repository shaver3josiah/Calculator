import SwiftUI
import UIKit

/// Her screen-rotation choice. The Info.plist already ships all four
/// orientations, so runtime can only ever NARROW that set — never widen it.
enum OrientationPref: String, CaseIterable {
    case auto, portrait, landscape

    var label: String {
        switch self {
        case .auto: return "Automatic"
        case .portrait: return "Portrait"
        case .landscape: return "Landscape"
        }
    }

    var symbol: String {
        switch self {
        case .auto: return "arrow.clockwise"
        case .portrait: return "rectangle.portrait"
        case .landscape: return "rectangle"
        }
    }

    var mask: UIInterfaceOrientationMask {
        switch self {
        case .auto: return .all
        case .portrait: return .portrait
        case .landscape: return .landscape
        }
    }
}

/// The app had no delegate at all (pure SwiftUI). UIKit asks exactly one object
/// which orientations are allowed, and this is the only place it will look.
final class BloomAppDelegate: NSObject, UIApplicationDelegate {
    static var mask: UIInterfaceOrientationMask = .all

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        BloomAppDelegate.mask
    }
}

enum OrientationLock {
    /// Narrow the allowed orientations and make the system re-ask NOW. Without
    /// the nudge below, a new lock only bites the next time she physically
    /// turns the phone — she'd tap "Portrait" in landscape and nothing moves.
    @MainActor static func apply(_ pref: OrientationPref) {
        BloomAppDelegate.mask = pref.mask
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            // Failures are legitimate — her phone's own rotation lock can refuse.
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: pref.mask))
            windowScene.keyWindow?.rootViewController?
                .setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}
