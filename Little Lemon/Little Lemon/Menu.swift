//
//  Menu.swift
//  Little Lemon
//
//  Created by  Artem Mazheykin on 20.03.2026.
//

import SwiftUI
import CoreData

struct Menu: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"

    let categories = ["All", "Starters", "Mains", "Desserts", "Drinks"]

    
    var body: some View {
        VStack(alignment: .leading) {
            
            // HERO
            VStack(alignment: .leading, spacing: 16) {
                
                Text("Little Lemon")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.yellow)
                
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        
                        Text("Chicago")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        
                        Text("We are a family owned Mediterranean restaurant, focused on traditional recipes served with a modern twist.")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image("Hero image")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 160)
                        .clipped()
                }
                
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.black)

                    TextField("Search menu", text: $searchText)
                }
                .padding(12)
                .background(Color.white)
            }
            .padding()
            .background(Color(hex: "495E57"))

            // CATEGORIES
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == category ? Color.green : Color.gray.opacity(0.2))
                            .foregroundColor(selectedCategory == category ? .white : .black)
                            .cornerRadius(16)
                            .onTapGesture {
                                selectedCategory = category
                            }
                    }
                }
            }

            // LIST
            FetchedObjects(
                predicate: buildPredicate(),
                sortDescriptors: buildSortDescriptors()
            ) { (dishes: [Dish]) in

                List {
                    ForEach(filteredDishes(dishes), id: \.self) { dish in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(dish.title ?? "")
                                    .font(.headline)

                                Text("$\(dish.price ?? "")")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            AsyncImage(url: URL(string: dish.image ?? "")) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 60, height: 60)

                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipped()
                                        .cornerRadius(8)

//                                case .failure:
//                                    Image("profile-image-placeholder")
//                                        .resizable()
//                                        .scaledToFill()
//                                        .frame(width: 60, height: 60)
//                                        .clipped()
//                                        .cornerRadius(8)

                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(.white))
        }
        .padding()
        .onAppear {
            let request = Dish.fetchRequest()
            let count = (try? viewContext.count(for: request)) ?? 0

            if count == 0 {
                getMenuData()
            }
        }
    }

    // MARK: - FILTER LOGIC

    func filteredDishes(_ dishes: [Dish]) -> [Dish] {
        if selectedCategory == "All" {
            return dishes
        }

        return dishes.filter { dish in
            let title = dish.title?.lowercased() ?? ""

            switch selectedCategory {
            case "Starters":
                return title.contains("salad") || title.contains("bruschetta")
            case "Mains":
                return title.contains("pasta") || title.contains("fish")
            case "Desserts":
                return title.contains("dessert")
            case "Drinks":
                return title.contains("coke") || title.contains("beer")
            default:
                return true
            }
        }
    }

    func buildSortDescriptors() -> [NSSortDescriptor] {
        [
            NSSortDescriptor(
                key: "title",
                ascending: true,
                selector: #selector(NSString.localizedStandardCompare)
            )
        ]
    }

    func buildPredicate() -> NSPredicate {
        if searchText.isEmpty {
            return NSPredicate(value: true)
        } else {
            return NSPredicate(format: "title CONTAINS[cd] %@", searchText)
        }
    }

    // MARK: - DATA

    func getMenuData() {
        PersistenceController.shared.clear()

        let urlString = "https://raw.githubusercontent.com/Meta-Mobile-Developer-PC/Working-With-Data-API/main/menu.json"
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)

        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data {
                let decoder = JSONDecoder()
                let decoded = try? decoder.decode(MenuList.self, from: data)

                if let menuItems = decoded?.menu {
                    DispatchQueue.main.async {
                        for item in menuItems {
                            let dish = Dish(context: viewContext)
                            dish.title = item.title
                            dish.image = item.image
                            dish.price = item.price
                        }

                        try? viewContext.save()
                    }
                }
            }
        }

        task.resume()
    }
}

#Preview {
    Menu()
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
