import SwiftUI

struct SoundStudioView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeStore.self) private var theme
    @Environment(SoundStore.self) private var sound
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showCredits = false
    @State private var playEpoch = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Match any sound to each button. Tap a note to preview. Your choices are saved on this device.")
                        .font(bloomBody(14))
                        .foregroundStyle(theme.color("muted"))

                    togglesSection

                    groupLabel("Keypad buttons")
                    VStack(spacing: 8) {
                        ForEach(SoundStore.keypadEvents, id: \.0) { eventId, symbol in
                            eventRow(eventId: eventId, symbol: symbol)
                        }
                    }

                    groupLabel("Events")
                    VStack(spacing: 8) {
                        ForEach(SoundStore.namedEvents, id: \.0) { eventId, name in
                            eventRow(eventId: eventId, symbol: name)
                        }
                    }

                    Button("Reset to defaults") {
                        sound.resetToDefaults()
                    }
                    .font(bloomBody(14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radius)
                            .fill(theme.color("surfaceSoft"))
                    )

                    Button("Credits") {
                        showCredits = true
                    }
                    .font(bloomBody(14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radius)
                            .fill(theme.color("surface2"))
                    )
                }
                .padding(20)
            }
            .background {
                ZStack {
                    theme.color("bg")
                    if theme.motionEnabled && !reduceMotion {
                        SpinningGarden()
                    }
                }
                .ignoresSafeArea()
            }
            .overlay {
                // Every preview scatters a few petals over the studio.
                if theme.petalsOn {
                    PetalBurstView(trigger: playEpoch, originX: 0.5, originY: 0.25)
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Sound Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        FlowerLogo(size: 22)
                        Text("Sound Studio")
                            .font(bloomBody(17, weight: .semibold))
                            .foregroundStyle(theme.color("deep"))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
    }

    private var togglesSection: some View {
        VStack(spacing: 10) {
            Toggle(isOn: Binding(
                get: { sound.enabled },
                set: { sound.enabled = $0 }
            )) {
                Text("Sounds")
                    .font(bloomBody(15, weight: .medium))
                    .foregroundStyle(theme.color("text"))
            }
            Toggle(isOn: Binding(
                get: { sound.hapticsEnabled },
                set: { sound.hapticsEnabled = $0 }
            )) {
                Text("Haptics")
                    .font(bloomBody(15, weight: .medium))
                    .foregroundStyle(theme.color("text"))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surface"))
        )
        .tint(theme.color("primaryStrong"))
    }

    private func groupLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(bloomBody(11, weight: .semibold))
            .foregroundStyle(theme.color("muted"))
            .padding(.top, 4)
    }

    private func eventRow(eventId: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Text(symbol)
                .font(bloomBody(14, weight: .semibold))
                .frame(width: 64, alignment: .leading)
                .foregroundStyle(theme.color("text"))

            Picker("", selection: bindingFor(eventId)) {
                ForEach(SoundStore.optionChoices, id: \.0) { value, label in
                    Text(label).tag(value)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()

            Button {
                preview(eventId)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(theme.color("surface")))
                    .overlay(
                        Circle().stroke(
                            LinearGradient(
                                colors: [theme.color("primary"), theme.color("flowerCenter")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Preview sound")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.color("surfaceSoft"))
        )
    }

    private func preview(_ eventId: String) {
        sound.preview(currentValue(eventId))
        playEpoch += 1   // flowers bloom with every note
    }

    private func currentValue(_ eventId: String) -> String {
        sound.eventMap[eventId] ?? SoundStore.defaultMap[eventId] ?? "silent"
    }

    private func bindingFor(_ eventId: String) -> Binding<String> {
        Binding(
            get: { currentValue(eventId) },
            set: { sound.setEvent(eventId, to: $0) }
        )
    }
}

/// Faint flowers turning very slowly behind the studio — a background layer,
/// not content. Transform-only animation, so it stays cheap.
private struct SpinningGarden: View {
    var body: some View {
        GeometryReader { geo in
            SpinningFlower(size: 180, period: 70)
                .position(x: geo.size.width * 0.12, y: geo.size.height * 0.18)
            SpinningFlower(size: 130, period: 55, clockwise: false)
                .position(x: geo.size.width * 0.92, y: geo.size.height * 0.42)
            SpinningFlower(size: 210, period: 90)
                .position(x: geo.size.width * 0.20, y: geo.size.height * 0.88)
        }
        .allowsHitTesting(false)
    }
}

private struct SpinningFlower: View {
    let size: CGFloat
    let period: Double
    var clockwise: Bool = true

    @State private var spin = false

    var body: some View {
        FlowerLogo(size: size)
            .opacity(0.07)
            .rotationEffect(.degrees(spin ? (clockwise ? 360 : -360) : 0))
            .onAppear {
                withAnimation(.linear(duration: period).repeatForever(autoreverses: false)) {
                    spin = true
                }
            }
    }
}
