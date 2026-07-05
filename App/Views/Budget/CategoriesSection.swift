import SwiftUI
import BloomCore

struct CategoriesSection: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @State private var showAddCat = false
    @State private var importTarget: Int?
    @State private var showImportList = false

    var body: some View {
        VStack(spacing: 12) {
            ForEach(store.month.cats.indices, id: \.self) { index in
                categoryCard(index)
            }
            Button {
                showAddCat = true
            } label: {
                Text("+ Add a category")
                    .font(bloomBody(14, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
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
                        Button {
                            store.addRow(to: index)
                        } label: {
                            Text("+ Add item")
                                .font(bloomBody(13, weight: .semibold))
                                .foregroundStyle(theme.color("primaryStrong"))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Button {
                            importTarget = index
                            showImportList = true
                        } label: {
                            Text("\u{21E9} Import a list")
                                .font(bloomBody(13, weight: .semibold))
                                .foregroundStyle(theme.color("muted"))
                        }
                        .buttonStyle(.plain)
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
                store.toggleCategoryOpen(index)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.color("muted"))
                    .rotationEffect(.degrees(category.open ? 90 : 0))
            }
            .buttonStyle(.plain)

            Toggle(isOn: catSelectAllBinding(index)) {
                EmptyView()
            }
            .labelsHidden()
            .tint(theme.color("primaryStrong"))
            .frame(width: 22)

            TextField("Category", text: catNameBinding(index))
                .font(bloomBody(15, weight: .semibold))
                .foregroundStyle(theme.color("text"))

            HStack(spacing: 4) {
                reorderButton(systemName: "chevron.up") { store.reorderCategory(index, direction: -1) }
                reorderButton(systemName: "chevron.down") { store.reorderCategory(index, direction: 1) }
            }

            Text(Formatters.money(BudgetMath.catTotal(category)))
                .font(bloomNumber(14, weight: .semibold))
                .foregroundStyle(theme.color("deep"))

            if category.items.isEmpty {
                Button {
                    store.deleteCategory(index)
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(theme.color("muted"))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove category")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            store.toggleCategoryOpen(index)
        }
    }

    private func rowView(category categoryIndex: Int, row rowIndex: Int) -> some View {
        HStack(spacing: 8) {
            Toggle(isOn: rowSelBinding(categoryIndex, rowIndex)) {
                EmptyView()
            }
            .labelsHidden()
            .tint(theme.color("primaryStrong"))
            .frame(width: 22)

            TextField("Item", text: rowNameBinding(categoryIndex, rowIndex))
                .font(bloomBody(14))
                .foregroundStyle(theme.color("text"))

            TextField("0", text: rowAmountBinding(categoryIndex, rowIndex))
                .keyboardType(.decimalPad)
                .font(bloomBody(14))
                .frame(width: 64)
                .multilineTextAlignment(.trailing)

            reorderButton(systemName: "chevron.up") { store.reorderRow(category: categoryIndex, row: rowIndex, direction: -1) }
            reorderButton(systemName: "chevron.down") { store.reorderRow(category: categoryIndex, row: rowIndex, direction: 1) }

            Button {
                store.deleteRow(category: categoryIndex, row: rowIndex)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.color("muted"))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove item")
        }
    }

    private func reorderButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(theme.color("muted"))
        }
        .buttonStyle(.plain)
    }

    private func catSelectAllBinding(_ index: Int) -> Binding<Bool> {
        Binding(
            get: {
                let items = store.month.cats[index].items
                return !items.isEmpty && items.allSatisfy { $0.sel }
            },
            set: { store.setCategorySelectAll(index, on: $0) }
        )
    }

    private func catNameBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { store.month.cats[index].n },
            set: { store.renameCategory(index, name: $0) }
        )
    }

    private func rowSelBinding(_ categoryIndex: Int, _ rowIndex: Int) -> Binding<Bool> {
        Binding(
            get: { store.month.cats[categoryIndex].items[rowIndex].sel },
            set: { store.updateRow(category: categoryIndex, row: rowIndex, sel: $0) }
        )
    }

    private func rowNameBinding(_ categoryIndex: Int, _ rowIndex: Int) -> Binding<String> {
        Binding(
            get: { store.month.cats[categoryIndex].items[rowIndex].n },
            set: { store.updateRow(category: categoryIndex, row: rowIndex, name: $0) }
        )
    }

    private func rowAmountBinding(_ categoryIndex: Int, _ rowIndex: Int) -> Binding<String> {
        Binding(
            get: { Formatters.plain(store.month.cats[categoryIndex].items[rowIndex].a) },
            set: { store.updateRow(category: categoryIndex, row: rowIndex, amount: Double($0) ?? 0) }
        )
    }
}
