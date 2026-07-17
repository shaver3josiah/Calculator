import SwiftUI
import BloomCore

@main
struct BloomApp: App {
    @UIApplicationDelegateAdaptor(BloomAppDelegate.self) private var appDelegate
    @State private var themeStore = ThemeStore()
    @State private var historyStore: HistoryStore
    @State private var soundStore: SoundStore
    @State private var listsStore = ListsStore()
    @State private var kitchenStore = KitchenStore()
    @State private var musicStore: MusicStore
    @State private var calcStore: CalcStore
    @State private var projectionStore = ProjectionStore()
    @State private var budgetStore = BudgetStore()
    @State private var draftStore = DraftStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var songBook = SongBook()

    init() {
        let history = HistoryStore()
        let sounds = SoundStore()
        let music = MusicStore()
        sounds.digitChordHook = { [weak music] digit in
            guard let music, music.playOnKeys, !music.chords.isEmpty else { return false }
            music.playDigitChord(digit)
            return true
        }
        _historyStore = State(initialValue: history)
        _soundStore = State(initialValue: sounds)
        _musicStore = State(initialValue: music)
        _calcStore = State(initialValue: CalcStore(history: history, sounds: sounds))
        #if DEBUG
        // Exercise the ingredient-art table invariants on every debug launch —
        // the registry's _selfCheck was previously defined but never called.
        IngredientArt._selfCheck()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // Follows HER palette, not the system: keyboards, sheets and
                // share panels go dark the moment she picks the midnight garden.
                .preferredColorScheme(themeStore.isDark ? .dark : .light)
                .environment(themeStore)
                .environment(historyStore)
                .environment(soundStore)
                .environment(listsStore)
                .environment(kitchenStore)
                .environment(musicStore)
                .environment(calcStore)
                .environment(projectionStore)
                .environment(budgetStore)
                .environment(songBook)
                .environment(draftStore)
                // Leaving the app is the last guaranteed moment to write her
                // in-progress numbers down; the debounce may still be pending.
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { draftStore.flush() }
                }
                // ThemeStore's init assignment never fires its didSet, so the
                // saved lock has to be re-applied here or a relaunch forgets it.
                .task {
                    OrientationLock.apply(themeStore.orientation)
                }
        }
    }
}
