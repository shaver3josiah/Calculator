import SwiftUI

struct SoundStudioView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeStore.self) private var theme
    @Environment(SoundStore.self) private var sound

    @State private var showCredits = false

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
            .background(theme.color("bg"))
            .navigationTitle("Sound Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            }
            Toggle(isOn: Binding(
                get: { sound.hapticsEnabled },
                set: { sound.hapticsEnabled = $0 }
            )) {
                Text("Haptics")
                    .font(bloomBody(15, weight: .medium))
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
                sound.preview(currentValue(eventId))
            } label: {
                Image(systemName: "play.fill")
                    .foregroundStyle(theme.color("primaryStrong"))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.color("surfaceSoft"))
        )
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
