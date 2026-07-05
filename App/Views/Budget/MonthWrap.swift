import SwiftUI
import BloomCore

struct MonthWrap: View {
    var body: some View {
        VStack(spacing: 16) {
            IncomeCard()
            StatsRow()
            CategoriesSection()
            GoalsCard()
        }
    }
}
