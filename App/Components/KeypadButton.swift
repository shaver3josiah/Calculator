import SwiftUI

struct KeypadButton: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(SoundStore.self) private var soundStore

    var label: String
    var soundEvent: String
    var isAccent: Bool = false
    var isStrong: Bool = false
    var action: () -> Void

    @State private var isPressed = false
    @State private var feedbackTrigger = false

    var body: some View {
        Button {
            feedbackTrigger.toggle()
            action()
        } label: {
            Text(label)
                .font(bloomNumber(22, weight: .medium))
                .foregroundStyle(labelColor)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: themeStore.radius * 0.6))
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger) { _, _ in
            soundStore.hapticsEnabled
        }
    }

    private var backgroundColor: Color {
        if isStrong { return themeStore.color("primaryStrong") }
        if isAccent { return themeStore.color("surface2") }
        return themeStore.color("surfaceSoft")
    }

    private var labelColor: Color {
        if isStrong { return .white }
        return themeStore.color("text")
    }
}
