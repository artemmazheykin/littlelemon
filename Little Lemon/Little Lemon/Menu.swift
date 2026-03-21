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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Little Lemon")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Chicago")
                .font(.title2)
            
            Text("Menu")
            
            TextField("Search menu", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            FetchedObjects(
                predicate: buildPredicate(),
                sortDescriptors: buildSortDescriptors()
            ) { (dishes: [Dish]) in
                List {
                    ForEach(dishes, id: \.self) { dish in
                        HStack {
                            Text("\(dish.title ?? "") - $\(dish.price ?? "")")
                            
                            AsyncImage(url: URL(string: dish.image ?? "")) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 50, height: 50)
                        }
                    }
                }
            }
        }
        .onAppear {
            let request = Dish.fetchRequest()
            let count = (try? viewContext.count(for: request)) ?? 0
            
            if count == 0 {
                getMenuData()
            }
        }
    }
    
    func buildSortDescriptors() -> [NSSortDescriptor] {
        return [
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
