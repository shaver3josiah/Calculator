import SwiftUI

/// The Music Garden tour: a friendly step-by-step demo of the whole tab.
/// MusicView owns the state machine (typewriter, auto-advance on load, etc.);
/// this file holds the step definitions, the bottom card, and the spotlight.
enum MusicTourStep: Int, CaseIterable {
    case welcome, library, write, slide, pads, controls, piano, done

    var title: String {
        switch self {
        case .welcome: return "Welcome to the Music Garden 🌸"
        case .library: return "A whole songbook"
        case .write: return "Or write your own"
        case .slide: return "Now the fun part"
        case .pads: return "Tap to play"
        case .controls: return "Make it yours"
        case .piano: return "One note at a time"
        case .done: return "You're ready! 🌷"
        }
    }

    var message: String {
        switch self {
        case .welcome: return "Chords become soft piano here. Want the 30-second tour?"
        case .library: return "Psalms, hymns, country & old-timey classics — tap a card to browse, tap a song and it loads itself."
        case .write: return "Chords live in this box — watch me write some!"
        case .slide: return "Swipe the flower all the way to the right to load your chords."
        case .pads: return "Every pad is a chord. Tap them in any order — or let Play strum through."
        case .controls: return "Tempo, strum, loudness, transpose — twist the dials until it sounds like you."
        case .piano: return "This little piano sprinkles single notes into your song — try a twinkle."
        case .done: return "Everything plays offline. Go make something beautiful."
        }
    }

    var primaryLabel: String? {
        switch self {
        case .welcome: return "Show me!"
        case .slide: return nil   // advances itself when she loads the chords
        case .done: return "Let's play"
        default: return "Next"
        }
    }
}

/// Bottom-docked tour card: step dots, one thought at a time, big friendly buttons.
struct MusicTourCard: View {
    @Environment(ThemeStore.self) private var theme

    let step: MusicTourStep
    var onNext: () -> Void
    var onSkip: () -> Void
    var onAssist: (() -> Void)? = nil   // "Do it for me" on the slide step

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                stepDots
                Spacer()
                if step != .done {
                    Button(action: onSkip) {
                        Text("Skip")
                            .font(bloomBody(13, weight: .medium))
                            .foregroundStyle(theme.color("muted"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(step.title)
                .font(bloomBody(17, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
            Text(step.message)
                .font(bloomBody(14))
                .foregroundStyle(theme.color("text"))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                if let label = step.primaryLabel {
                    Button(action: onNext) {
                        Text(label)
                            .font(bloomBody(15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(theme.color("primaryStrong")))
                    }
                    .buttonStyle(TactilePressStyle(cornerRadius: 999))
                } else if let onAssist {
                    Button(action: onAssist) {
                        Text("Do it for me")
                            .font(bloomBody(14, weight: .semibold))
                            .foregroundStyle(theme.color("primaryStrong"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(theme.color("surfaceSoft")))
                    }
                    .buttonStyle(TactilePressStyle(cornerRadius: 999))
                }
            }
            .padding(.top, 2)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                .fill(theme.color("surface"))
                .shadow(color: theme.color("shadow"), radius: 18, y: 10)
        )
        .padding(.horizontal, 16)
    }

    private var stepDots: some View {
        HStack(spacing: 5) {
            ForEach(MusicTourStep.allCases, id: \.rawValue) { s in
                Circle()
                    .fill(theme.color(s.rawValue <= step.rawValue ? "primaryStrong" : "line"))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityLabel("Step \(step.rawValue + 1) of \(MusicTourStep.allCases.count)")
    }
}

/// Glow ring + gentle lift on the section the current tour step points at.
private struct TourSpotlightModifier: ViewModifier {
    @Environment(ThemeStore.self) private var theme
    let active: Bool
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                if active {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [theme.color("primary"), theme.color("flowerCenter")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .shadow(color: theme.color("primary").opacity(0.45), radius: 10)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .scaleEffect(active ? 1.015 : 1)
            .animation(BloomMotion.springSoft, value: active)
    }
}

extension View {
    func tourSpotlight(_ active: Bool, cornerRadius: CGFloat = 22) -> some View {
        modifier(TourSpotlightModifier(active: active, cornerRadius: cornerRadius))
    }
}
