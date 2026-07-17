import SwiftUI
import BloomCore

@main
struct BloomApp: App {
    @State private var themeStore = ThemeStore()
    @State private var historyStore: HistoryStore
    @State private var soundStore: SoundStore
    @State private var listsStore = ListsStore()
    @State private var kitchenStore = KitchenStore()
    @State private var musicStore: MusicStore
    @State private var calcStore: CalcStore
    @State private var projectionStore = ProjectionStore()
    @State private var budgetStore = BudgetStore()
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
        }
    }
}
