import SwiftUI
import BloomCore

/// Row/category deletion (or a budget import replacing the month) can make SwiftUI
/// re-evaluate a stale row's binding getter with an out-of-range index — return nil
/// instead of trapping.
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/// A UISwitch has a fixed intrinsic size of 51×31pt — putting `.frame(width: 22)`
/// on it doesn't shrink it, it just centers the full-size switch in a 22pt slot
/// so it overflows ~15pt into its neighbors (visibly colliding on small phones).
/// The correct spacing math: scale the switch by s and reserve exactly 51s × 31s,
/// so the row layout is deterministic on every screen width.
private struct CompactToggle: View {
    @Environment(ThemeStore.self) private var theme
    let isOn: Binding<Bool>

    private static let scale: CGFloat = 0.7   // 51×31 → ~36×22

    var body: some View {
        Toggle(isOn: isOn) { EmptyView() }
            .labelsHidden()
            .tint(theme.color("primaryStrong"))
            .scaleEffect(Self.scale)
            .frame(width: 51 * Self.scale, height: 31 * Self.scale)
            .frame(minWidth: 44, minHeight: 44)
            // The 44pt frame alone is dead zone — a scaled UISwitch only hears
            // taps on its shrunken self. The clear overlay owns hit-testing for
            // the whole cell and toggles exactly once per tap.
            .overlay {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { isOn.wrappedValue.toggle() }
            }
    }
}

/// A plain button that traces the pink→gold `EncircleOutline` hairline once on
/// each press (~1s, then removes it) rather than leaving a resident outline.
/// Gated behind `theme.shimmerOn`. Shared by the budget tab's press moments
/// (add-category, add-item, import, month/year nav).
struct EncirclePressButton<Label: View>: View {
    @Environment(ThemeStore.self) private var theme
    var cornerRadius: CGFloat = 12
    var lineWidth: CGFloat = 1.5
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var epoch = 0
    @State private var lit = false

    var body: some View {
        Button {
            pulse()
            action()
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .overlay {
            if theme.shimmerOn, lit {
                EncircleOutline(trigger: epoch, cornerRadius: cornerRadius, lineWidth: lineWidth)
            }
        }
    }

    private func pulse() {
        guard theme.shimmerOn else { return }
        epoch += 1
        lit = true
        let current = epoch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if epoch == current { lit = false }
        }
    }
}

/// One in-flight pluck: `from` is where the item was picked up, `target` the slot
/// it would land in right now, `offset` the finger's travel, `settling` true once
/// the finger lifted and the item is gliding into its slot.
private struct PluckState {
    var category: Int?    // nil → a card is plucked; set → a row inside that category
    var from: Int
    var target: Int
    var offset: CGFloat = 0
    var settling = false
}

struct CategoriesSection: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @Environment(SoundStore.self) private var sound
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAddCat = false
    @State private var importTarget: Int?
    @State private var showImportList = false
    @State private var headerPulseIndex: Int?
    @State private var headerPulseEpoch = 0

    // MARK: Drag-reorder state
    @State private var cardDrag: PluckState?
    @State private var rowDrag: PluckState?
    /// While a card is plucked, every card folds to its header so the stack is a
    /// uniform deck of chips (like reordering pages in Revu) — the slot math stays
    /// exact and the whole month is reachable in one drag.
    @State private var deckMode = false
    /// Height of one collapsed chip's header — stable through the deck-collapse
    /// animation (unlike whole-card heights), so the slot math is exact from the
    /// first drag frame. All headers are the same fixed-control height.
    @State private var headerHeight: CGFloat = 44
    @State private var rowHeight: CGFloat = 48
    @State private var sectionSize = CGSize(width: 1, height: 1)
    // Haptic + confetti triggers
    @State private var pluckTick = 0
    @State private var slotTick = 0
    @State private var settleTick = 0
    @State private var confettiEpoch = 0
    @State private var confettiY = 0.5
    /// Frozen at burst time: the deck re-expands under the overlay, and a
    /// fraction-of-live-height origin would slide the petals with it.
    @State private var confettiHeight: CGFloat = 1

    private static let cardSpacing: CGFloat = 14
    private static let rowSpacing: CGFloat = 10
    private static let cardPadding: CGFloat = 16

    /// One collapsed deck slot: header + card padding + inter-card gap.
    private var cardSlot: CGFloat { headerHeight + Self.cardPadding * 2 + Self.cardSpacing }
    private var isReordering: Bool { cardDrag != nil || rowDrag != nil }
    private let reorderSpring = Animation.spring(response: 0.35, dampingFraction: 0.75)
    private let settleSpring = Animation.spring(response: 0.3, dampingFraction: 0.8)

    var body: some View {
        VStack(spacing: Self.cardSpacing) {
            ForEach(store.month.cats.indices, id: \.self) { index in
                categoryCard(index)
            }
            EncirclePressButton(cornerRadius: theme.radius, lineWidth: 1.5) {
                showAddCat = true
            } label: {
                Text("+ Add a category")
                    .font(bloomBody(14, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .background(RoundedRectangle(cornerRadius: theme.radius).strokeBorder(theme.color("line"), lineWidth: 1.5))
            .disabled(isReordering)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { sectionSize = $0 }
        .overlay(alignment: .top) {
            // The placement celebration — petals burst out of the exact slot the
            // card just settled into. The canvas height is frozen at burst time so
            // the deck re-expanding underneath doesn't drag the origin around.
            if theme.petalsOn {
                PetalBurstView(trigger: confettiEpoch, originX: 0.5, originY: confettiY)
                    .frame(height: confettiHeight)
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // A system interruption (call, app switch) cancels the gesture without
            // .onEnded — clear the pluck so the deck can't stick collapsed.
            guard phase != .active, isReordering else { return }
            cardDrag = nil
            rowDrag = nil
            deckMode = false
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: pluckTick) { _, _ in sound.hapticsEnabled }
        .sensoryFeedback(.selection, trigger: slotTick) { _, _ in sound.hapticsEnabled }
        .sensoryFeedback(.success, trigger: settleTick) { _, _ in sound.hapticsEnabled }
        .sheet(isPresented: $showAddCat) {
            AddCategorySheet()
        }
        .sheet(isPresented: $showImportList) {
            if let target = importTarget {
                ImportListSheet(categoryIndex: target)
            }
        }
    }

    // MARK: Cards

    private func categoryCard(_ index: Int) -> some View {
        let category = store.month.cats[index]
        let isPlucked = cardDrag?.from == index
        return VStack(spacing: 0) {
            categoryHeader(index, category: category)
            if category.open && !deckMode {
                VStack(spacing: Self.rowSpacing) {
                    ForEach(category.items.indices, id: \.self) { rowIndex in
                        rowView(category: index, row: rowIndex)
                            .offset(y: rowOffset(category: index, row: rowIndex))
                            .zIndex(rowDrag?.category == index && rowDrag?.from == rowIndex ? 5 : 0)
                    }
                    HStack {
                        EncirclePressButton(cornerRadius: 8, lineWidth: 1) {
                            store.addRow(to: index)
                        } label: {
                            Text("+ Add item")
                                .font(bloomBody(13, weight: .semibold))
                                .foregroundStyle(theme.color("primaryStrong"))
                                .frame(minHeight: 44)
                        }
                        Spacer()
                        EncirclePressButton(cornerRadius: 8, lineWidth: 1) {
                            importTarget = index
                            showImportList = true
                        } label: {
                            Text("\u{21E9} Import a list")
                                .font(bloomBody(13, weight: .semibold))
                                .foregroundStyle(theme.color("muted"))
                                .frame(minHeight: 44)
                        }
                    }
                    .padding(.top, 6)
                    // Adding/importing mid-drag would shift the indices the pluck
                    // is holding — parked until the card lands.
                    .disabled(isReordering)
                }
                .padding(.top, 12)
            }
        }
        .padding(Self.cardPadding)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
        .shadow(color: isPlucked ? theme.color("shadow") : .clear, radius: isPlucked ? 16 : 0, x: 0, y: isPlucked ? 10 : 0)
        .scaleEffect(isPlucked ? 1.03 : 1)
        .offset(y: cardOffset(index))
        .zIndex(isPlucked ? 10 : 0)
    }

    private func categoryHeader(_ index: Int, category: BudgetCategory) -> some View {
        HStack(spacing: 8) {
            Button {
                pulseHeader(index)
                store.toggleCategoryOpen(index)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.color("muted"))
                    .rotationEffect(.degrees(category.open && !deckMode ? 90 : 0))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(TactilePressStyle(cornerRadius: 10))

            CompactToggle(isOn: catSelectAllBinding(index))

            TextField("Category", text: catNameBinding(index), prompt: Text("Category").foregroundStyle(theme.color("muted")))
                .font(bloomBody(16, weight: .semibold))
                .foregroundStyle(theme.color("text"))
                .inputAccessories(catNameBinding(index), compact: true)

            // The total doubles as a generous open/close target — the whole-row
            // tap used to swallow near-misses on the (already narrow) name
            // field and collapse the card mid-edit.
            Text(Formatters.money(BudgetMath.catTotal(category)))
                .font(bloomNumber(15, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    pulseHeader(index)
                    store.toggleCategoryOpen(index)
                }

            grip(index: index, count: store.month.cats.count, isActive: cardDrag?.from == index) { translation in
                cardDragChanged(index, translation: translation)
            } ended: {
                cardDragEnded(index)
            } moveTo: { to in
                store.moveCategory(from: index, to: to)
            }
            .accessibilityLabel("Reorder \(category.n.isEmpty ? "category" : category.n)")
            .discoverable("budget.dragReorder", cornerRadius: 10)

            if category.items.isEmpty {
                Button {
                    KeyboardDismiss.now()   // commit any half-typed field before indices shift
                    store.deleteCategory(index)
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(theme.color("muted"))
                        .frame(minWidth: 40, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(TactilePressStyle(cornerRadius: 10))
                .accessibilityLabel("Remove category")
                .disabled(isReordering)
            }
        }
        .overlay {
            if theme.shimmerOn, headerPulseIndex == index {
                EncircleOutline(trigger: headerPulseEpoch, cornerRadius: 12, lineWidth: 1.5)
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
    }

    private func pulseHeader(_ index: Int) {
        guard theme.shimmerOn else { return }
        headerPulseEpoch += 1
        headerPulseIndex = index
        let epoch = headerPulseEpoch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if headerPulseEpoch == epoch { headerPulseIndex = nil }
        }
    }

    // MARK: Rows

    private func rowView(category categoryIndex: Int, row rowIndex: Int) -> some View {
        HStack(spacing: 8) {
            CompactToggle(isOn: rowSelBinding(categoryIndex, rowIndex))

            TextField("Item", text: rowNameBinding(categoryIndex, rowIndex), prompt: Text("Item").foregroundStyle(theme.color("muted")))
                .font(bloomBody(15))
                .foregroundStyle(theme.color("text"))
                .inputAccessories(rowNameBinding(categoryIndex, rowIndex), compact: true)

            DecimalField(value: rowAmountBinding(categoryIndex, rowIndex),
                         font: bloomBody(15), alignment: .trailing, width: 64)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(theme.color("surfaceSoft"))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            grip(index: rowIndex, count: store.month.cats[safe: categoryIndex]?.items.count ?? 0,
                 isActive: rowDrag?.category == categoryIndex && rowDrag?.from == rowIndex) { translation in
                rowDragChanged(category: categoryIndex, row: rowIndex, translation: translation)
            } ended: {
                rowDragEnded(category: categoryIndex, row: rowIndex)
            } moveTo: { to in
                store.moveRow(category: categoryIndex, from: rowIndex, to: to)
            }
            .accessibilityLabel("Reorder item")

            Button {
                KeyboardDismiss.now()   // commit any half-typed field before indices shift
                store.deleteRow(category: categoryIndex, row: rowIndex)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.color("muted"))
                    .frame(minWidth: 40, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(TactilePressStyle(cornerRadius: 10))
            .accessibilityLabel("Remove item")
            .disabled(isReordering)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { rowHeight = $0 }
    }

    // MARK: The pluck

    /// The grab handle that replaced the up/down arrows: press a beat, the item lifts
    /// (haptic pop), then it follows the finger with the rest of the stack flowing
    /// around it. VoiceOver keeps discrete Move up / Move down actions.
    private func grip(index: Int, count: Int, isActive: Bool,
                      changed: @escaping (CGFloat) -> Void,
                      ended: @escaping () -> Void,
                      moveTo: @escaping (Int) -> Void) -> some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(theme.color(isActive ? "primaryStrong" : "muted"))
            .frame(width: 40, height: 44)
            .contentShape(Rectangle())
            .gesture(
                LongPressGesture(minimumDuration: 0.15)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onChanged { value in
                        if case .second(true, let drag) = value {
                            changed(drag?.translation.height ?? 0)
                        }
                    }
                    .onEnded { value in
                        if case .second(true, _) = value { ended() }
                    }
            )
            .accessibilityAction(named: "Move up") { moveTo(max(0, index - 1)) }
            .accessibilityAction(named: "Move down") { moveTo(min(count - 1, index + 1)) }
    }

    private func cardOffset(_ index: Int) -> CGFloat {
        guard let d = cardDrag else { return 0 }
        if index == d.from { return clampedOffset(d, slot: cardSlot, count: store.month.cats.count) }
        if d.from < index && index <= d.target { return -cardSlot }
        if d.target <= index && index < d.from { return cardSlot }
        return 0
    }

    private func rowOffset(category: Int, row: Int) -> CGFloat {
        guard let d = rowDrag, d.category == category else { return 0 }
        let slot = rowHeight + Self.rowSpacing
        let count = store.month.cats[safe: category]?.items.count ?? 0
        if row == d.from { return clampedOffset(d, slot: slot, count: count) }
        if d.from < row && row <= d.target { return -slot }
        if d.target <= row && row < d.from { return slot }
        return 0
    }

    /// The plucked item stays inside its own list — dragging past either end holds
    /// at the last slot instead of sailing off the deck.
    private func clampedOffset(_ d: PluckState, slot: CGFloat, count: Int) -> CGFloat {
        min(max(d.offset, -CGFloat(d.from) * slot), CGFloat(count - 1 - d.from) * slot)
    }

    private func cardDragChanged(_ index: Int, translation: CGFloat) {
        if cardDrag == nil {
            guard rowDrag == nil else { return }
            KeyboardDismiss.now()   // a focused field must commit before indices move
            cardDrag = PluckState(category: nil, from: index, target: index)
            pluckTick += 1
            theme.discover("budget.dragReorder")
            withAnimation(reorderSpring) { deckMode = true }
        }
        guard var d = cardDrag, !d.settling, d.from == index else { return }
        d.offset = translation
        let count = store.month.cats.count
        let travelled = clampedOffset(d, slot: cardSlot, count: count)
        let newTarget = min(count - 1, max(0, d.from + Int((travelled / cardSlot).rounded())))
        if newTarget != d.target {
            d.target = newTarget
            slotTick += 1
            withAnimation(reorderSpring) { cardDrag = d }
        } else {
            cardDrag = d
        }
    }

    /// `index` proves ownership: with two fingers down, the OTHER grip's lift must
    /// not commit this drag.
    private func cardDragEnded(_ index: Int) {
        guard var d = cardDrag, !d.settling, d.from == index else { return }
        let slot = cardSlot
        d.settling = true
        d.offset = CGFloat(d.target - d.from) * slot
        withAnimation(settleSpring) {
            cardDrag = d
        } completion: {
            // Swap the model and drop the offsets in one animation-free frame — the
            // settled positions and the new order are pixel-identical, so nothing
            // visibly jumps — then bloom the deck back open.
            confettiHeight = max(1, sectionSize.height)
            confettiY = (Double(d.target) * slot + (slot - Self.cardSpacing) / 2) / confettiHeight
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                store.moveCategory(from: d.from, to: d.target)
                cardDrag = nil
            }
            settleTick += 1
            if d.target != d.from { confettiEpoch += 1 }
            withAnimation(reorderSpring) { deckMode = false }
        }
    }

    private func rowDragChanged(category: Int, row: Int, translation: CGFloat) {
        if rowDrag == nil {
            guard cardDrag == nil else { return }
            KeyboardDismiss.now()   // a focused field must commit before indices move
            rowDrag = PluckState(category: category, from: row, target: row)
            pluckTick += 1
        }
        guard var d = rowDrag, !d.settling, d.category == category, d.from == row else { return }
        d.offset = translation
        let slot = rowHeight + Self.rowSpacing
        let count = store.month.cats[safe: category]?.items.count ?? 0
        let travelled = clampedOffset(d, slot: slot, count: count)
        let newTarget = min(count - 1, max(0, d.from + Int((travelled / slot).rounded())))
        if newTarget != d.target {
            d.target = newTarget
            slotTick += 1
            withAnimation(reorderSpring) { rowDrag = d }
        } else {
            rowDrag = d
        }
    }

    private func rowDragEnded(category: Int, row: Int) {
        guard var d = rowDrag, !d.settling, d.category == category, d.from == row else { return }
        let slot = rowHeight + Self.rowSpacing
        d.settling = true
        d.offset = CGFloat(d.target - d.from) * slot
        withAnimation(settleSpring) {
            rowDrag = d
        } completion: {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                store.moveRow(category: category, from: d.from, to: d.target)
                rowDrag = nil
            }
            settleTick += 1
        }
    }

    // MARK: Bindings

    private func catSelectAllBinding(_ index: Int) -> Binding<Bool> {
        Binding(
            get: {
                let items = store.month.cats[safe: index]?.items ?? []
                return !items.isEmpty && items.allSatisfy { $0.sel }
            },
            set: { store.setCategorySelectAll(index, on: $0) }
        )
    }

    private func catNameBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { store.month.cats[safe: index]?.n ?? "" },
            set: { store.renameCategory(index, name: $0) }
        )
    }

    private func rowSelBinding(_ categoryIndex: Int, _ rowIndex: Int) -> Binding<Bool> {
        Binding(
            get: { store.month.cats[safe: categoryIndex]?.items[safe: rowIndex]?.sel ?? false },
            set: { store.updateRow(category: categoryIndex, row: rowIndex, sel: $0) }
        )
    }

    private func rowNameBinding(_ categoryIndex: Int, _ rowIndex: Int) -> Binding<String> {
        Binding(
            get: { store.month.cats[safe: categoryIndex]?.items[safe: rowIndex]?.n ?? "" },
            set: { store.updateRow(category: categoryIndex, row: rowIndex, name: $0) }
        )
    }

    private func rowAmountBinding(_ categoryIndex: Int, _ rowIndex: Int) -> Binding<Double> {
        Binding(
            get: { store.month.cats[safe: categoryIndex]?.items[safe: rowIndex]?.a ?? 0 },
            set: { store.updateRow(category: categoryIndex, row: rowIndex, amount: $0) }
        )
    }
}
