import SwiftUI
import UIKit
import BloomCore

/// Her notebook page. A distraction-free rich editor: while she writes, the tab
/// bar and the swipe hints fall away and a formatting bar rises above the
/// keyboard (bold, italic, underline, headings, fonts). When she's done, there's
/// no Done button — she flicks the page:
///   ↑ keep   ↓ archive   → duplicate   ← delete
/// each with a little petal-fall and a word, so finishing a note feels like a
/// small spell rather than a form submit.
struct NotesEditorView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(DraftStore.self) private var drafts
    @Environment(NotesArchiveStore.self) private var archive
    @Environment(SoundStore.self) private var sound

    /// Reported up so the parent can hide the Lists/Notes/Archive tab bar while
    /// she types — the "hide the header" half of the ask.
    @Binding var composing: Bool

    @State private var controller = RichTextController()
    @State private var petalTrigger = 0
    @State private var feedbackTick = 0   // drives haptics even when petals are off
    @State private var flash: Flash?

    private struct Flash: Equatable { let word: String; let symbol: String }

    var body: some View {
        @Bindable var d = drafts
        VStack(spacing: 10) {
            if !controller.isEditing {
                header
            }
            editor
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .safeAreaInset(edge: .bottom) {
            if controller.isEditing {
                formattingBar
            }
        }
        .overlay {
            // The finish-gesture celebration: a word + symbol that blooms and fades.
            if let flash {
                flashView(flash)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            if theme.petalsOn {
                PetalBurstView(trigger: petalTrigger, originX: 0.5, originY: 0.42)
                    .allowsHitTesting(false)
            }
        }
        .sensoryFeedback(.success, trigger: feedbackTick) { _, _ in sound.hapticsEnabled }
        .onChange(of: controller.isEditing) { _, editing in
            withAnimation(BloomMotion.springSoft) { composing = editing }
        }
        .onDisappear { composing = false }
    }

    // MARK: header (hidden while typing)

    private var header: some View {
        @Bindable var d = drafts
        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                TextField("Name this note", text: $d.notes.title, prompt: Text("Name this note").foregroundStyle(theme.color("muted")))
                    .font(bloomNumber(19, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                    .frame(minHeight: 44)

                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.color("accentInk"))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .disabled(isBlank)
                .opacity(isBlank ? 0.4 : 1)

                Button {
                    newPage()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.color("accentInk"))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .discoverable("notes.new", cornerRadius: 999)
            }
            hintRow
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    /// The four flicks, spelled out. This is the whole instruction set, so it
    /// stays gentle and legible rather than hidden in a help screen.
    private var hintRow: some View {
        HStack(spacing: 12) {
            swipeHint("arrow.up", "keep")
            swipeHint("arrow.down", "archive")
            swipeHint("arrow.right", "copy")
            swipeHint("arrow.left", "delete")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private func swipeHint(_ symbol: String, _ label: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).font(.system(size: 10, weight: .bold))
            Text(label).font(bloomBody(11, weight: .medium))
        }
        .foregroundStyle(theme.color("muted"))
    }

    // MARK: editor

    private var editor: some View {
        @Bindable var d = drafts
        return RichTextEditor(
            rtf: $d.notes.rtf,
            plain: $d.notes.body,
            controller: controller,
            textColor: UIColor(theme.color("text")),
            tintColor: UIColor(theme.color("primaryStrong"))
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surfaceSoft")))
        .overlay {
            // Only when she's NOT actively typing: a clear layer that turns the
            // page into a card — a tap opens the keyboard, a flick runs an action.
            // Removed while editing so the text view owns every touch.
            if !controller.isEditing {
                Color.clear
                    .contentShape(Rectangle())
                    .overlay { if isBlank { emptyPrompt } }
                    .highPriorityGesture(directionalFlick)
                    .onTapGesture { controller.textView?.becomeFirstResponder() }
            }
        }
        .discoverable("notes.page", cornerRadius: theme.radius)
    }

    private var emptyPrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(theme.color("flowerCenter"))
            Text("Tap to write something lovely")
                .font(bloomBody(14))
                .foregroundStyle(theme.color("muted"))
        }
    }

    /// One flick, four outcomes — the axis with the larger travel wins, so a
    /// slightly-diagonal flick still reads as the direction she meant.
    private var directionalFlick: some Gesture {
        DragGesture(minimumDistance: 28)
            .onEnded { value in
                let t = value.translation
                guard max(abs(t.width), abs(t.height)) > 50 else { return }
                if abs(t.width) > abs(t.height) {
                    if t.width > 0 { duplicateNote() } else { deleteNote() }
                } else {
                    if t.height < 0 { keepNote() } else { archiveNote() }
                }
            }
    }

    // MARK: formatting bar (rises above the keyboard while typing)

    private var formattingBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                styleToggle("bold", on: controller.isBold) { controller.toggleBold() }
                styleToggle("italic", on: controller.isItalic) { controller.toggleItalic() }
                styleToggle("underline", on: controller.isUnderline) { controller.toggleUnderline() }

                divider
                outlineMenu
                fontMenu

                divider
                Button {
                    controller.textView?.resignFirstResponder()
                } label: {
                    Text("Done")
                        .font(bloomBody(14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 38)
                        .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("primaryStrong")))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Divider().overlay(theme.color("line")) }
    }

    private var divider: some View {
        Rectangle().fill(theme.color("line")).frame(width: 1, height: 24)
    }

    private func styleToggle(_ symbol: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(on ? .white : theme.color("text"))
                .frame(width: 40, height: 38)
                .background(RoundedRectangle(cornerRadius: 10).fill(on ? theme.color("primaryStrong") : theme.color("surfaceSoft")))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var outlineMenu: some View {
        Menu {
            outlineOption("Title", level: 1)
            outlineOption("Heading", level: 2)
            outlineOption("Body", level: 0)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "textformat.size")
                Text(outlineLabel).font(bloomBody(13, weight: .semibold))
            }
            .foregroundStyle(theme.color("accentInk"))
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surfaceSoft")))
        }
    }

    private func outlineOption(_ label: String, level: Int) -> some View {
        Button {
            controller.setHeading(level)
        } label: {
            if controller.headingLevel == level { Label(label, systemImage: "checkmark") } else { Text(label) }
        }
    }

    private var outlineLabel: String {
        switch controller.headingLevel { case 1: return "Title"; case 2: return "Heading"; default: return "Body" }
    }

    private var fontMenu: some View {
        Menu {
            ForEach(RichTextController.fontKeys, id: \.self) { key in
                Button {
                    controller.setFont(key)
                } label: {
                    if controller.fontKey == key { Label(RichTextController.fontLabel(key), systemImage: "checkmark") }
                    else { Text(RichTextController.fontLabel(key)) }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "character")
                Text(RichTextController.fontLabel(controller.fontKey)).font(bloomBody(13, weight: .semibold))
            }
            .foregroundStyle(theme.color("accentInk"))
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surfaceSoft")))
        }
    }

    // MARK: actions

    private var isBlank: Bool {
        drafts.notes.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && drafts.notes.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var shareText: String {
        let t = drafts.notes.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let head = t.isEmpty ? "" : t + "\n\n"
        return head + drafts.notes.body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Build an ArchivedNote from the live page, carrying the archived flag of the
    /// note it came from (so re-saving an archived note doesn't silently un-archive it).
    private func currentNote(archived: Bool? = nil) -> ArchivedNote {
        let id = drafts.notes.id ?? UUID()
        let existing = archive.note(id: id)
        var note = ArchivedNote(id: id, title: drafts.notes.title, plain: drafts.notes.body, rtf: drafts.notes.rtf)
        note.archived = archived ?? existing?.archived ?? false
        return note
    }

    private func keepNote() {
        guard !isBlank else { return nudgeEmpty() }
        if let saved = archive.save(currentNote()) { drafts.notes.id = saved.id }
        celebrate("Kept", "checkmark.seal.fill", strong: false)
    }

    private func archiveNote() {
        guard !isBlank else { return nudgeEmpty() }
        _ = archive.save(currentNote(archived: true))
        clearPage()
        celebrate("Archived", "archivebox.fill", strong: false)
    }

    private func duplicateNote() {
        guard !isBlank else { return nudgeEmpty() }
        let saved = archive.save(currentNote()) ?? currentNote()
        drafts.notes.id = saved.id
        _ = archive.duplicate(saved)
        celebrate("Duplicated", "doc.on.doc.fill", strong: false)
    }

    private func deleteNote() {
        if let id = drafts.notes.id { archive.delete(id) }
        clearPage()
        celebrate("Deleted", "trash.fill", strong: true)
    }

    private func newPage() {
        if !isBlank { _ = archive.save(currentNote()) }
        clearPage()
        sound.play("tap1")
        ToastCenter.shared.show(title: "Fresh page", message: "Your last note is safe in your notebook.")
    }

    private func clearPage() {
        drafts.notes = NotesDraft()
    }

    private func nudgeEmpty() {
        showFlash(Flash(word: "Empty", symbol: "pencil"))
    }

    private func celebrate(_ word: String, _ symbol: String, strong: Bool) {
        showFlash(Flash(word: word, symbol: symbol))
        if theme.petalsOn { petalTrigger += 1 }
        feedbackTick += 1
        theme.triggerCurtain()
        sound.play(strong ? "clear" : "success")
    }

    private func showFlash(_ f: Flash) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { flash = f }
        let mine = f
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            if flash == mine { withAnimation(.easeOut(duration: 0.3)) { flash = nil } }
        }
    }

    private func flashView(_ f: Flash) -> some View {
        VStack(spacing: 10) {
            Image(systemName: f.symbol)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(theme.color("primaryStrong"))
            Text(f.word)
                .font(bloomNumber(24, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
        }
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: theme.color("shadow"), radius: 20, y: 8)
    }
}
