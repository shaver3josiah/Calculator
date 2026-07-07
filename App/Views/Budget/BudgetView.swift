import SwiftUI
import BloomCore

struct BudgetView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @State private var showImport = false

    private let modes = ["This month", "Year view"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthBar
                HStack(spacing: 8) {
                    KTabBar(items: modes, selection: viewModeBinding)
                    ShareLink(item: store.exportText()) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.color("primaryStrong"))
                            .frame(width: 44, height: 44)
                            .background(theme.color("surfaceSoft"))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Share this month")
                    Button {
                        showImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.color("primaryStrong"))
                            .frame(width: 44, height: 44)
                            .background(theme.color("surfaceSoft"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Import a shared budget")
                }
                if store.view == "month" {
                    MonthWrap()
                } else {
                    YearWrap()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(theme.color("bg"))
        .sheet(isPresented: $showImport) {
            ImportBudgetSheet()
        }
    }

    private var viewModeBinding: Binding<String> {
        Binding(
            get: { store.view == "month" ? "This month" : "Year view" },
            set: { store.view = $0 == "This month" ? "month" : "year" }
        )
    }

    private var monthBar: some View {
        HStack {
            Button {
                store.shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(width: 44, height: 44)
                    .background(theme.color("surfaceSoft"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .opacity(store.view == "month" ? 1 : 0)
            .disabled(store.view != "month")
            .accessibilityLabel("Previous month")

            Spacer()

            Text(store.view == "month" ? store.monthLabel : "\(store.yearSel)")
                .font(bloomNumber(19, weight: .semibold))
                .foregroundStyle(theme.color("deep"))

            Spacer()

            Button {
                store.shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(width: 44, height: 44)
                    .background(theme.color("surfaceSoft"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .opacity(store.view == "month" ? 1 : 0)
            .disabled(store.view != "month")
            .accessibilityLabel("Next month")
        }
    }
}
