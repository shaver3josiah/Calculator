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
            FlowerLogo(size: 38)
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
            headerButtons
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
            PetalCurtainView(trigger: selectedTab)
                .allowsHitTesting(false)
            ToastHost()
            PoemOverlay()
            SplashOverlay()
        }
    }

    // Outgoing panel glides off, incoming glides in on the expo-out glide token.
    private var contentTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        let inEdge: Edge = slideForward ? .trailing : .leading
        let outEdge: Edge = slideForward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: inEdge).combined(with: .opacity),
            removal: .move(edge: outEdge).combined(with: .opacity)
        )
    }

    private func switchTab(_ tab: BloomTab) {
        slideForward = tabOrder(tab) >= tabOrder(selectedTab)
        if reduceMotion {
            selectedTab = tab
        } else {
            withAnimation(BloomMotion.glide) { selectedTab = tab }
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
