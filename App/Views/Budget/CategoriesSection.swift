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

struct CategoriesSection: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @State private var showAddCat = false
    @State private var importTarget: Int?
    @State private var showImportList = false
    @State private var headerPulseIndex: Int?
    @State private var headerPulseEpoch = 0

    var body: some View {
        VStack(spacing: 12) {
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
        }
        .sheet(isPresented: $showAddCat) {
            AddCategorySheet()
        }
        .sheet(isPresented: $showImportList) {
            if let target = importTarget {
                ImportListSheet(categoryIndex: target)
            }
        }
    }

    private func categoryCard(_ index: Int) -> some View {
        let category = store.month.cats[index]
        return VStack(spacing: 0) {
            categoryHeader(index, category: category)
            if category.open {
                VStack(spacing: 8) {
                    ForEach(category.items.indices, id: \.self) { rowIndex in
                        rowView(category: index, row: rowIndex)
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
                    .padding(.top, 4)
                }
                .padding(.top, 10)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
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
                    .rotationEffect(.degrees(category.open ? 90 : 0))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(TactilePressStyle(cornerRadius: 10))

            CompactToggle(isOn: catSelectAllBinding(index))

            TextField("Category", text: catNameBinding(index), prompt: Text("Category").foregroundStyle(theme.color("muted")))
                .font(bloomBody(15, weight: .semibold))
                .foregroundStyle(theme.color("text"))
                .inputAccessories(catNameBinding(index), compact: true)

            reorderMenu(up: { store.reorderCategory(index, direction: -1) },
                        down: { store.reorderCategory(index, direction: 1) })

            // The total doubles as a generous open/close target — the whole-row
            // tap used to swallow near-misses on the (already narrow) name
            // field and collapse the card mid-edit.
            Text(Formatters.money(BudgetMath.catTotal(category)))
                .font(bloomNumber(14, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    pulseHeader(index)
                    store.toggleCategoryOpen(index)
                }

            if category.items.isEmpty {
                Button {
                    store.deleteCategory(index)
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(theme.color("muted"))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(TactilePressStyle(cornerRadius: 10))
                .accessibilityLabel("Remove category")
            }
        }
        .overlay {
            if theme.shimmerOn, headerPulseIndex == index {
                EncircleOutline(trigger: headerPulseEpoch, cornerRadius: 12, lineWidth: 1.5)
            }
        }
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

    private func rowView(category categoryIndex: Int, row rowIndex: Int) -> some View {
        HStack(spacing: 8) {
            CompactToggle(isOn: rowSelBinding(categoryIndex, rowIndex))

            TextField("Item", text: rowNameBinding(categoryIndex, rowIndex), prompt: Text("Item").foregroundStyle(theme.color("muted")))
                .font(bloomBody(14))
                .foregroundStyle(theme.color("text"))
                .inputAccessories(rowNameBinding(categoryIndex, rowIndex), compact: true)

            TextField("0", text: rowAmountBinding(categoryIndex, rowIndex), prompt: Text("0").foregroundStyle(theme.color("muted")))
                .keyboardType(.decimalPad)
                .font(bloomBody(14))
                .frame(width: 64)
                .multilineTextAlignment(.trailing)

            reorderMenu(up: { store.reorderRow(category: categoryIndex, row: rowIndex, direction: -1) },
                        down: { store.reorderRow(category: categoryIndex, row: rowIndex, direction: 1) })

            Button {
                store.deleteRow(category: categoryIndex, row: rowIndex)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.color("muted"))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(TactilePressStyle(cornerRadius: 10))
            .accessibilityLabel("Remove item")
        }
    }

    /// One 44pt reorder button instead of two chevrons — on small phones the
    /// chevron pair (92pt with spacing) starved the name field down to ~30pt,
    /// exactly while she was typing a name. A Menu keeps both directions.
    private func reorderMenu(up: @escaping () -> Void, down: @escaping () -> Void) -> some View {
        Menu {
            Button { up() } label: { Label("Move up", systemImage: "arrow.up") }
            Button { down() } label: { Label("Move down", systemImage: "arrow.down") }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.color("muted"))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Reorder")
    }

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

    private func rowAmountBinding(_ categoryIndex: Int, _ rowIndex: Int) -> Binding<String> {
        Binding(
            get: { Formatters.plain(store.month.cats[safe: categoryIndex]?.items[safe: rowIndex]?.a ?? 0) },
            set: { store.updateRow(category: categoryIndex, row: rowIndex, amount: Double($0) ?? 0) }
        )
    }
}
