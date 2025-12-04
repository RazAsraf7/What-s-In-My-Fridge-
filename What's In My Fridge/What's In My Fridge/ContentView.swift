import SwiftUI
import CoreData

struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PantryItem.name, ascending: true)],
        animation: .default)
    private var pantryItems: FetchedResults<PantryItem>

    @State private var newItemName: String = ""

    private let recipeService = RecipeService()
    
    @State private var fetchedRecipes: [Recipe] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                
                HStack {
                    TextField("Add new ingredient...", text: $newItemName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.leading)

                    Button(action: addItem) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                    .padding(.trailing)
                    .disabled(newItemName.isEmpty)
                }
                .padding(.top)

                List {
                    ForEach(pantryItems) { item in
                        Text(item.name ?? "No name")
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
                .frame(height: 200)

                Button(action: findRecipes) {
                    Text("Find Recipes")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(pantryItems.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding([.leading, .trailing])
                .disabled(pantryItems.isEmpty || isLoading)
                

                if isLoading {
                    Spacer()
                    ProgressView("Finding recipes...")
                    Spacer()
                } else {
                    List(fetchedRecipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                            HStack {
                                AsyncImage(url: URL(string: recipe.image)) { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 70, height: 70)
                                .cornerRadius(8)
                                
                                Text(recipe.title)
                                    .font(.headline)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                
                Spacer()
            }
            .navigationTitle("My Pantry")
            .toolbar {
                // ===================================
                // --- כאן נמצא התיקון ---
                // הוספנו כפתור שמוביל לרשימת הקניות
                // ===================================
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ShoppingListView()) {
                        Image(systemName: "cart") // אייקון של עגלת קניות
                    }
                }
                
                // משאירים את כפתור העריכה למחיקת מצרכים
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
        }
    }
    
    // --- פונקציות שמירת נתונים (ללא שינוי) ---
    private func addItem() {
        withAnimation {
            let newItem = PantryItem(context: viewContext)
            newItem.name = newItemName
            saveContext()
            newItemName = ""
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            offsets.map { pantryItems[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save: \(error.localizedDescription)")
        }
    }
    
    // --- פונקציית חיפוש (ללא שינוי) ---
    private func findRecipes() {
        
        let ingredients = pantryItems.compactMap { $0.name }
        
        guard !ingredients.isEmpty else { return }
        
        print("Starting search for: \(ingredients.joined(separator: ", "))")
        
        self.isLoading = true
        self.fetchedRecipes = []
        
        recipeService.fetchRecipes(byIngredients: ingredients) { result in
            
            self.isLoading = false
            
            switch result {
            case .success(let recipes):
                self.fetchedRecipes = recipes
                print("Found \(recipes.count) recipes")
                
            case .failure(let error):
                if case .apiKeyMissing = error {
                    print("CRITICAL: API Key not found in Info.plist!")
                } else {
                    print("Error getting recipes: \(error.localizedDescription)")
                }
            }
        }
    }
}


// ----- תצוגה מקדימה (Canvas) -----
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
