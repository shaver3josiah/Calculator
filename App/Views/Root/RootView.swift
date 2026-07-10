import SwiftUI
import BloomCore

struct RootView: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(MusicStore.self) private var musicStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedTab: BloomTab = .calc
    @State private var showThemeEditor = false
    @State private var slideForward = true
    @State private var verseMode = false

    var body: some View {
        ZStack {
            themeStore.color("bg").ignoresSafeArea()
            VStack(spacing: 0) {
                header
                content
                    .keyboardDoneBar()
                    .id(selectedTab)
                    .transition(contentTransition)
                BloomTabBar(selection: $selectedTab, onSelect: switchTab)
            }
            overlays
        }
        .onAppear { _ = themeStore.firstVisit(selectedTab.rawValue) }   // launch tab: seen, no curtain
        .fullScreenCover(isPresented: historyPresentedBinding) {
            HistoryOverlay()
        }
        .sheet(isPresented: $showThemeEditor) {
            ThemeEditorView()
        }
        .sheet(isPresented: studioPresentedBinding) {
            SoundStudioView()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            TappableFlower(size: 38, onDoubleTap: toggleVerse)
            VStack(alignment: .leading, spacing: 0) {
                Text("Hannah's")
                    .font(bloomScript(28))
                    .foregroundStyle(themeStore.color("deep"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("CALCULATOR & PROJECTIONS")
                    .font(bloomBody(9, weight: .semibold))
                    .foregroundStyle(themeStore.color("muted"))
                    .tracking(1.2)
            }
            Spacer()
            // Trailing slot: the icon buttons, or — in verse mode — the verse ticker.
            if verseMode {
                HeaderVerseTicker()
                    .transition(.opacity)
            } else {
                headerButtons
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var headerButtons: some View {
        HStack(spacing: 10) {
            iconButton(system: "speaker.wave.2") {
                soundStore.isStudioPresented = true
            }
            iconButton(system: "clock") {
                historyStore.isPresented = true
            }
            iconButton(system: "pencil") {
                showThemeEditor = true
            }
        }
    }

    private func iconButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(themeStore.color("primaryStrong"))
                .frame(width: 44, height: 44)
                .background(themeStore.color("surfaceSoft"))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .calc:
            CalcView()
        case .proj:
            ProjectionView()
        case .lists:
            ListsView()
        case .kitchen:
            KitchenView()
        case .tools:
            ToolsView()
        case .budget:
            BudgetView()
        case .music:
            MusicView()
        }
    }

    private var overlays: some View {
        ZStack {
            if themeStore.petalsOn {
                PetalCurtainView(trigger: themeStore.curtainEpoch)
                    .allowsHitTesting(false)
            }
            ToastHost()
            PoemOverlay()
            SplashOverlay()
        }
    }

    private func toggleVerse() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            verseMode.toggle()
        }
        soundStore.play("modeswitch")
    }

    // Outgoing panel glides off, incoming glides in on the expo-out glide token.
    private var contentTransition: AnyTransition {
        guard !reduceMotion, themeStore.motionEnabled else { return .opacity }
        let inEdge: Edge = slideForward ? .trailing : .leading
        let outEdge: Edge = slideForward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: inEdge).combined(with: .opacity),
            removal: .move(edge: outEdge).combined(with: .opacity)
        )
    }

    private func switchTab(_ tab: BloomTab) {
        slideForward = tabOrder(tab) >= tabOrder(selectedTab)
        if reduceMotion || !themeStore.motionEnabled {
            selectedTab = tab
        } else {
            withAnimation(BloomMotion.glide) { selectedTab = tab }
        }
        // Petal curtain only the first time she ever opens each tab.
        if themeStore.firstVisit(tab.rawValue) {
            themeStore.triggerCurtain()
        }
        guard soundStore.enabled else { return }
        if musicStore.cycleOnTabSwitch, let chord = musicStore.nextCycledChord() {
            musicStore.soundCycledChord(chord)
        } else {
            soundStore.play("modeswitch")
        }
    }

    private func tabOrder(_ tab: BloomTab) -> Int {
        BloomTab.allCases.firstIndex(of: tab) ?? 0
    }

    private var historyPresentedBinding: Binding<Bool> {
        Binding(
            get: { historyStore.isPresented },
            set: { historyStore.isPresented = $0 }
        )
    }

    private var studioPresentedBinding: Binding<Bool> {
        Binding(
            get: { soundStore.isStudioPresented },
            set: { soundStore.isStudioPresented = $0 }
        )
    }
}
