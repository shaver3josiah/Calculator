import SwiftUI
import BloomCore

struct PantryView: View {
    @Environment(ThemeStore.self) private var theme

    @State private var searchText = ""
    @State private var activeGroup = "All"
    @State private var foods: [Food] = []

    private var groups: [String] {
        ["All"] + FoodLibrary.groups()
    }

    private var filteredFoods: [Food] {
        foods.filter { food in
            let matchesGroup = activeGroup == "All" || food.group == activeGroup
            let matchesSearch = searchText.isEmpty || food.name.localizedCaseInsensitiveContains(searchText)
            return matchesGroup && matchesSearch
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            pillRow
            countLabel
            foodGrid
        }
        .background(theme.color("bg"))
        .onAppear {
            if foods.isEmpty {
                foods = FoodLibrary.load()
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.color("muted"))
            TextField("Search foods", text: $searchText)
                .font(bloomBody(15))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surfaceSoft")))
        .padding(16)
    }

    private var pillRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(groups, id: \.self) { group in
                    Button(group) {
                        activeGroup = group
                    }
                    .font(bloomBody(13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 999)
                            .fill(activeGroup == group ? theme.color("primary") : theme.color("surfaceSoft"))
                    )
                    .foregroundStyle(activeGroup == group ? .white : theme.color("text"))
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var countLabel: some View {
        Text("\(filteredFoods.count) of \(foods.count) foods")
            .font(bloomBody(12))
            .foregroundStyle(theme.color("muted"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }

    private var foodGrid: some View {
        ScrollView {
            if filteredFoods.isEmpty {
                Text("No foods match. Try another search.")
                    .font(bloomBody(14))
                    .foregroundStyle(theme.color("muted"))
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                    ForEach(filteredFoods) { food in
                        FoodCard(food: food)
                    }
                }
                .padding(16)
            }
        }
    }
}

private struct FoodCard: View {
    @Environment(ThemeStore.self) private var theme
    let food: Food

    var body: some View {
        VStack(spacing: 6) {
            Text(food.glyph)
                .font(.system(size: 32))
            Text(food.name)
                .font(bloomBody(13, weight: .medium))
                .foregroundStyle(theme.color("text"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(food.measure)
                .font(bloomBody(11))
                .foregroundStyle(theme.color("muted"))
            Text(food.group)
                .font(bloomBody(10, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 999).fill(theme.color("surface2")))
                .foregroundStyle(theme.color("primaryStrong"))
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(theme.color("surface")))
    }
}
