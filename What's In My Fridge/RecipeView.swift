import SwiftUI
import CoreData

struct RecipeView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PantryItem.name, ascending: true)],
        animation: .default)
    private var pantryItems: FetchedResults<PantryItem>
    
    private let recipeService = RecipeService()
    // הסרנו את כל שירותי התרגום (DeepL, LibreTranslate)
    
    @State private var fetchedRecipes: [Recipe] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                Button(action: findRecipes) {
                    Text("מצא מתכונים לפי המזווה שלי")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(pantryItems.isEmpty ? Color.gray : Color.Theme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(pantryItems.isEmpty || isLoading)
                
                if isLoading {
                    Spacer()
                    ProgressView("מחפש מתכונים...")
                    Spacer()
                } else {
                    // הצגת כרטיסי המתכונים המעוצבים
                    List(fetchedRecipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                            RecipeCardView(recipe: recipe)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("חיפוש מתכונים")
        }
    }
    
    // --- פונקציית החיפוש היציבה והסינכרונית ---
    // בתוך RecipeView.swift
    
    // בתוך RecipeView.swift, החלף את הפונקציה findRecipes()

    private func findRecipes() {
        
        self.isLoading = true
        self.fetchedRecipes = []
        
        // 1. קריאת המצרכים ושימוש במתרגם החדש (שדורש context)
        let translatedIngredients = pantryItems.compactMap { $0.name }
            .map { item in // מפרקים את ה-.map כדי להעביר את ה-viewContext
                HebrewTranslator.translate(item, in: viewContext) // <--- התיקון הקריטי
            }
            .filter { !$0.isEmpty }
        
        if translatedIngredients.isEmpty {
            self.isLoading = false
            print("Pantry is empty, cannot search.")
            return
        }
        
        // 2. קריאה לשירות Spoonacular עם המצרכים המתורגמים
        self.recipeService.fetchRecipes(byIngredients: translatedIngredients) { result in
            self.isLoading = false
            switch result {
            case .success(let recipes):
                self.fetchedRecipes = recipes.sorted { $0.title < $1.title }
                print("Search successful, found \(recipes.count) recipes.")
            case .failure(let error):
                print("CRITICAL API Error: \(error.localizedDescription)")
            }
        }
    }
    
    // Preview
    struct RecipeView_Previews: PreviewProvider {
        static var previews: some View {
            RecipeView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
