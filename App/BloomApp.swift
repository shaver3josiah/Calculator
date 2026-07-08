import SwiftUI
import BloomCore

@main
struct BloomApp: App {
    @State private var themeStore = ThemeStore()
    @State private var historyStore: HistoryStore
    @State private var soundStore: SoundStore
    @State private var listsStore = ListsStore()
    @State private var kitchenStore = KitchenStore()
    @State private var musicStore = MusicStore()
    @State private var calcStore: CalcStore
    @State private var projectionStore = ProjectionStore()
    @State private var budgetStore = BudgetStore()

    init() {
        let history = HistoryStore()
        let sounds = SoundStore()
        _historyStore = State(initialValue: history)
        _soundStore = State(initialValue: sounds)
        _calcStore = State(initialValue: CalcStore(history: history, sounds: sounds))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .environment(themeStore)
                .environment(historyStore)
                .environment(soundStore)
                .environment(listsStore)
                .environment(kitchenStore)
                .environment(musicStore)
                .environment(calcStore)
                .environment(projectionStore)
                .environment(budgetStore)
        }
    }
}
