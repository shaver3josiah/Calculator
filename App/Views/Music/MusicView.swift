import SwiftUI

struct MusicView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(MusicStore.self) private var store
    @Environment(SoundStore.self) private var sound

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                introText
                textBox
                sampleChips
                loadButton
                keyChordToggles

                if !store.chords.isEmpty {
                    controls
                    chordPads
                }
            }
            .padding(16)
        }
        .background(theme.color("bg"))
    }

    private var introText: some View {
        Text("Paste piano chords and hear them bloom as soft grand-piano sounds. Everything plays offline.")
            .font(bloomBody(14))
            .foregroundStyle(theme.color("muted"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var textBox: some View {
        TextField(
            "Paste chords, e.g.   C  G  Am  F      (Dm7 G7 Cmaj7 and C/E also work)",
            text: chordTextBinding,
            prompt: Text("Paste chords, e.g.   C  G  Am  F      (Dm7 G7 Cmaj7 and C/E also work)")
                .foregroundColor(theme.color("muted")),
            axis: .vertical
        )
        .font(bloomBody(14))
        .lineLimit(3...6)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surface")))
    }

    private var sampleChips: some View {
        HStack(spacing: 8) {
            Text("TRY")
                .font(bloomBody(11, weight: .semibold))
                .foregroundStyle(theme.color("muted"))
            ForEach(MusicStore.samples, id: \.0) { key, label in
                Button(label) {
                    store.loadSample(key)
                }
                .font(bloomBody(12, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 999).fill(theme.color("surfaceSoft")))
            }
        }
    }

    private var loadButton: some View {
        Button("Load chords") {
            store.loadChords()
            sound.play("modeswitch")
        }
        .font(bloomBody(15, weight: .semibold))
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 999).fill(theme.color("primary")))
        .foregroundStyle(.white)
    }

    private var keyChordToggles: some View {
        VStack(spacing: 10) {
            Toggle(isOn: playOnKeysBinding) {
                Text("Play chords on calculator keys")
                    .font(bloomBody(15, weight: .medium))
                    .foregroundStyle(theme.color("text"))
            }
            Toggle(isOn: cycleOnTabSwitchBinding) {
                Text("Cycle chords on tab switch")
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

    private var controls: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    store.isPlaying ? store.stopAll() : store.playAll()
                } label: {
                    Label(store.isPlaying ? "Stop" : "Play", systemImage: store.isPlaying ? "stop.fill" : "play.fill")
                }
                .font(bloomBody(14, weight: .semibold))
                Spacer()
                Toggle("Strum", isOn: strumBinding)
                    .font(bloomBody(13))
                    .fixedSize()
            }

            HStack {
                Text("Tempo")
                    .font(bloomBody(13))
                    .foregroundStyle(theme.color("muted"))
                Slider(value: tempoBinding, in: 50...170)
                Text("\(Int(store.tempo))")
                    .font(bloomNumber(15))
                    .frame(width: 32)
            }

            HStack {
                Text("Transpose")
                    .font(bloomBody(13))
                    .foregroundStyle(theme.color("muted"))
                Button("-") { store.transpose -= 1 }
                Text("\(store.transpose > 0 ? "+" : "")\(store.transpose)")
                    .font(bloomNumber(15))
                    .frame(width: 40)
                Button("+") { store.transpose += 1 }
                Spacer()
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
    }

    private var chordPads: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 10)], spacing: 10) {
            ForEach(Array(store.chords.enumerated()), id: \.offset) { _, chord in
                Button(chord.symbol) {
                    store.playChord(chord)
                }
                .font(bloomNumber(16, weight: .semibold))
                .frame(width: 76, height: 56)
                .background(RoundedRectangle(cornerRadius: 14).fill(theme.color("surfaceSoft")))
                .foregroundStyle(theme.color("deep"))
            }
        }
    }

    private var chordTextBinding: Binding<String> {
        Binding(get: { store.chordText }, set: { store.chordText = $0 })
    }
    private var strumBinding: Binding<Bool> {
        Binding(get: { store.strum }, set: { store.strum = $0 })
    }
    private var tempoBinding: Binding<Double> {
        Binding(get: { store.tempo }, set: { store.tempo = $0 })
    }
    private var playOnKeysBinding: Binding<Bool> {
        Binding(get: { store.playOnKeys }, set: { store.playOnKeys = $0 })
    }
    private var cycleOnTabSwitchBinding: Binding<Bool> {
        Binding(get: { store.cycleOnTabSwitch }, set: { store.cycleOnTabSwitch = $0 })
    }
}
