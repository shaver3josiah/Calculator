import SwiftUI

/// Songwriting mode — a clean full-screen page for writing a whole song:
/// chords AND lyrics, block by block, each block named (verse / chorus /
/// bridge …). Every section plays with the app's soft piano, and Preview folds
/// the workspace away into the finished lead sheet.
///
/// Full-screen by design (nothing else on the page competing), but everything
/// scrolls — the keyboard never traps her.
struct SongwriterView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(MusicStore.self) private var music
    @Environment(SoundStore.self) private var sound
    @Environment(SongBook.self) private var book
    @Environment(\.dismiss) private var dismiss

    @State private var song = Song()
    @State private var loaded = false
    @State private var previewing = false
    @State private var saveTask: Task<Void, Never>? = nil
    @State private var showSongs = false
    @FocusState private var focusedField: UUID?

    var body: some View {
        ZStack {
            theme.color("bg").ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                Divider().overlay(theme.color("line"))
                if previewing {
                    previewPage
                        .transition(.opacity)
                } else {
                    editorPage
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            guard !loaded else { return }
            song = book.mostRecentOrNew()
            loaded = true
            music.warmUp()      // first chord is instant
        }
        // Debounced autosave: her words are never a keystroke away from lost,
        // but the file isn't rewritten on every letter either.
        .onChange(of: song) { _, _ in scheduleSave() }
        .onDisappear {
            saveTask?.cancel()
            music.stopAll()
            book.upsert(song)
        }
        .sheet(isPresented: $showSongs) { songListSheet }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                book.upsert(song)
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(theme.color("surfaceSoft")))
            }
            .buttonStyle(TactilePressStyle(cornerRadius: 999))
            .accessibilityLabel("Close songwriting")

            TextField(
                "Name your song",
                text: $song.title,
                prompt: Text("Name your song").foregroundStyle(theme.color("muted"))
            )
            .font(bloomScript(26))
            .foregroundStyle(theme.color("deep"))
            .textInputAutocapitalization(.words)
            .disabled(previewing)

            Button {
                withAnimation(BloomMotion.glide) { previewing.toggle() }
                sound.play("modeswitch")
            } label: {
                Label(previewing ? "Edit" : "Preview", systemImage: previewing ? "pencil" : "eye")
                    .font(bloomBody(13, weight: .semibold))
                    .foregroundStyle(previewing ? Color.white : theme.color("primaryStrong"))
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                    .background(
                        Capsule().fill(previewing ? theme.color("primaryStrong") : theme.color("surfaceSoft"))
                    )
            }
            .buttonStyle(TactilePressStyle(cornerRadius: 999))
            .discoverable("song.preview", cornerRadius: 999)

            Menu {
                Button {
                    book.upsert(song)
                    song = Song()
                } label: { Label("New song", systemImage: "plus") }
                Button { showSongs = true } label: { Label("My songs", systemImage: "books.vertical") }
                ShareLink(item: song.shareText) { Label("Share this song", systemImage: "square.and.arrow.up") }
                Divider()
                Button(role: .destructive) {
                    book.delete(song.id)
                    song = book.mostRecentOrNew()
                } label: { Label("Delete this song", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(theme.color("surfaceSoft")))
            }
            .accessibilityLabel("Song options")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Editor

    private var editorPage: some View {
        ScrollView {
            VStack(spacing: 14) {
                if song.sections.isEmpty { emptyHint }
                ForEach($song.sections) { $section in
                    sectionCard($section)
                }
                addRow
                Text("Chords play with the same soft piano as the rest of the app. Everything saves itself.")
                    .font(bloomBody(11))
                    .foregroundStyle(theme.color("muted"))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var emptyHint: some View {
        VStack(spacing: 6) {
            Image(systemName: "music.quarternote.3")
                .font(.system(size: 26))
                .foregroundStyle(theme.color("primary"))
            Text("A blank page")
                .font(bloomBody(16, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
            Text("Add a verse to begin.")
                .font(bloomBody(13))
                .foregroundStyle(theme.color("muted"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private func sectionCard(_ section: Binding<SongSection>) -> some View {
        // Snapshot identity/value up front: the row's own menu can delete it,
        // and reading section.wrappedValue after that mutation is a crash.
        let sid = section.wrappedValue.id
        let value = section.wrappedValue
        let kind = value.kind
        let label = song.label(for: value)
        let voices = ChordParser.parseText(value.chords)
        return VStack(alignment: .leading, spacing: 10) {
            // Header: what this block IS — tap to change it to a chorus, a
            // bridge, anything.
            HStack(spacing: 8) {
                Menu {
                    ForEach(SongSectionKind.allCases) { k in
                        Button {
                            section.wrappedValue.kind = k
                            sound.play("modeswitch")
                        } label: {
                            Label(k.label, systemImage: k.symbol)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle().fill(theme.color(kind.token)).frame(width: 8, height: 8)
                        Text(label)
                            .font(bloomBody(13, weight: .bold))
                            .foregroundStyle(theme.color("deep"))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(theme.color("muted"))
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(Capsule().fill(theme.color("surfaceSoft")))
                }
                .accessibilityLabel("Section type: \(label)")
                .accessibilityHint("Change this block to a verse, chorus, or bridge")

                Spacer(minLength: 0)

                Button {
                    music.playSequence(voices)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(voices.isEmpty ? theme.color("muted") : theme.color("primaryStrong"))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(theme.color("surfaceSoft")))
                }
                .buttonStyle(TactilePressStyle(cornerRadius: 999))
                .disabled(voices.isEmpty)
                .accessibilityLabel("Play this section's chords")

                Menu {
                    Button { duplicate(id: sid) } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                    Button { move(id: sid, by: -1) } label: { Label("Move up", systemImage: "arrow.up") }
                    Button { move(id: sid, by: 1) } label: { Label("Move down", systemImage: "arrow.down") }
                    Divider()
                    Button(role: .destructive) {
                        withAnimation(BloomMotion.springSoft) {
                            song.sections.removeAll { $0.id == sid }
                        }
                    } label: { Label("Delete section", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.color("muted"))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Section options")
            }

            // Chords
            VStack(alignment: .leading, spacing: 4) {
                Text("CHORDS")
                    .font(bloomBody(9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(theme.color("muted"))
                TextField(
                    "C  G  Am  F",
                    text: section.chords,
                    prompt: Text("C  G  Am  F").foregroundStyle(theme.color("muted"))
                )
                .font(bloomNumber(15, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .inputAccessories(section.chords, compact: true)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surfaceSoft")))
            }

            // Lyrics
            VStack(alignment: .leading, spacing: 4) {
                Text("LYRICS")
                    .font(bloomBody(9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(theme.color("muted"))
                TextField(
                    "Write your words here…",
                    text: section.lyrics,
                    prompt: Text("Write your words here…").foregroundStyle(theme.color("muted")),
                    axis: .vertical
                )
                .font(bloomBody(15))
                .foregroundStyle(theme.color("text"))
                .lineLimit(3...14)
                .lineSpacing(4)
                .focused($focusedField, equals: section.wrappedValue.id)
                .inputAccessories(section.lyrics, alignment: .top)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surfaceSoft")))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                .fill(theme.color("surface"))
                .shadow(color: theme.color("shadow"), radius: 10, y: 5)
        )
        // A hairline in the section's own color: the page reads as structure.
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                .stroke(theme.color(kind.token).opacity(0.28), lineWidth: 1)
        )
    }

    /// The three she reaches for get one tap each; the rest live behind "More".
    private var addRow: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(SongSectionKind.headline) { kind in
                    Button { add(kind) } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text(kind.label)
                                .font(bloomBody(13, weight: .semibold))
                                .lineLimit(1).minimumScaleFactor(0.85)
                        }
                        .foregroundStyle(theme.color("deep"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(theme.color("surface"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(theme.color(kind.token).opacity(0.45), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(TactilePressStyle(cornerRadius: 14))
                    .discoverable("song.add.\(kind.rawValue)", cornerRadius: 14)
                    .accessibilityLabel("Add a \(kind.label.lowercased())")
                }
            }
            Menu {
                ForEach(SongSectionKind.extras) { kind in
                    Button { add(kind) } label: { Label(kind.label, systemImage: kind.symbol) }
                }
            } label: {
                Text("More parts — intro, pre-chorus, outro")
                    .font(bloomBody(12, weight: .medium))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
            }
        }
    }

    // MARK: - Preview

    private var previewPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.displayTitle)
                        .font(bloomScript(34))
                        .foregroundStyle(theme.color("deep"))
                    Text(structureLine)
                        .font(bloomBody(11, weight: .medium))
                        .tracking(0.6)
                        .foregroundStyle(theme.color("muted"))
                }

                if song.sections.allSatisfy({ $0.isEmpty }) {
                    Text("Nothing written yet — tap Edit and give her a first line.")
                        .font(bloomBody(14))
                        .foregroundStyle(theme.color("muted"))
                        .padding(.top, 20)
                } else {
                    ForEach(song.sections.filter { !$0.isEmpty }) { section in
                        previewSection(section)
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        music.isPlaying ? music.stopAll() : music.playSequence(song.allVoices)
                    } label: {
                        Label(music.isPlaying ? "Stop" : "Play the whole song",
                              systemImage: music.isPlaying ? "stop.fill" : "play.fill")
                            .font(bloomBody(15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Capsule().fill(theme.color("primaryStrong")))
                    }
                    .buttonStyle(TactilePressStyle(cornerRadius: 999))
                    .disabled(song.allVoices.isEmpty)
                    .opacity(song.allVoices.isEmpty ? 0.5 : 1)

                    ShareLink(item: song.shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(theme.color("primaryStrong"))
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(theme.color("surfaceSoft")))
                    }
                    .accessibilityLabel("Share this song")
                }
                .padding(.top, 6)
            }
            .padding(20)
            .padding(.bottom, 40)
        }
    }

    private func previewSection(_ section: SongSection) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(theme.color(section.kind.token)).frame(width: 7, height: 7)
                Text(song.label(for: section).uppercased())
                    .font(bloomBody(11, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(theme.color(section.kind == .chorus ? "primaryStrong" : "muted"))
                Spacer(minLength: 0)
                Button {
                    music.playSequence(ChordParser.parseText(section.chords))
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(theme.color("primaryStrong"))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(section.chords.trimmingCharacters(in: .whitespaces).isEmpty ? 0 : 1)
                .accessibilityLabel("Play \(song.label(for: section))")
            }
            if !section.chords.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(section.chords)
                    .font(bloomNumber(15, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
            }
            if !section.lyrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(section.lyrics)
                    .font(bloomBody(15))
                    .foregroundStyle(theme.color("text"))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.color(section.kind == .chorus ? "surface2" : "surface"))
        )
    }

    /// "VERSE · CHORUS · VERSE · BRIDGE · CHORUS" — the song's shape in one line.
    private var structureLine: String {
        let parts = song.sections.filter { !$0.isEmpty }.map { $0.kind.label.uppercased() }
        return parts.isEmpty ? "YOUR SONG" : parts.joined(separator: " · ")
    }

    // MARK: - My songs

    private var songListSheet: some View {
        NavigationStack {
            List {
                ForEach(book.songs) { s in
                    Button {
                        book.upsert(song)     // keep the one she's leaving
                        song = s
                        showSongs = false
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.displayTitle)
                                .font(bloomBody(15, weight: .semibold))
                                .foregroundStyle(theme.color("text"))
                            Text(s.sections.filter { !$0.isEmpty }.map { $0.kind.label }.joined(separator: " · "))
                                .font(bloomBody(11))
                                .foregroundStyle(theme.color("muted"))
                                .lineLimit(1)
                        }
                    }
                }
                // Resolve ids BEFORE deleting — book.songs shifts under each
                // removal, so index-at-a-time deletion would read past the end.
                .onDelete { offsets in
                    let ids = offsets.map { book.songs[$0].id }
                    for id in ids { book.delete(id) }
                }
                if book.songs.isEmpty {
                    Text("Your songs will live here.")
                        .font(bloomBody(14))
                        .foregroundStyle(theme.color("muted"))
                }
            }
            .navigationTitle("My songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showSongs = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Actions

    private func add(_ kind: SongSectionKind) {
        let new = SongSection(kind: kind)
        withAnimation(BloomMotion.springSoft) { song.sections.append(new) }
        sound.play("modeswitch")
        focusedField = new.id
    }

    private func duplicate(id: UUID) {
        guard let idx = song.sections.firstIndex(where: { $0.id == id }) else { return }
        var copy = song.sections[idx]
        copy.id = UUID()
        withAnimation(BloomMotion.springSoft) { song.sections.insert(copy, at: idx + 1) }
    }

    private func move(id: UUID, by delta: Int) {
        guard let idx = song.sections.firstIndex(where: { $0.id == id }) else { return }
        let target = idx + delta
        guard song.sections.indices.contains(target) else { return }
        withAnimation(BloomMotion.springSoft) { song.sections.swapAt(idx, target) }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            book.upsert(song)
        }
    }
}
