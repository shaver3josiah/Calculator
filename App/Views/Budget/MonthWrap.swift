import SwiftUI

struct MonthWrap: View {
    var body: some View {
        // Reads top-to-bottom as the money flows: income → give first → plan the
        // categories → the bottom line (the budget's sum, AFTER the budget) → grow
        // what that sum revealed → goals.
        VStack(spacing: 16) {
            IncomeCard()
            StewardshipCard()
            CategoriesSection()
            StatsRow()
            GrowLeftoverCard()
            GoalsCard()
        }
    }
}
