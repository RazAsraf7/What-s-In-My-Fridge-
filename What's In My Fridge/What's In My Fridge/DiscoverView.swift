import SwiftUI

struct DiscoverView: View {
    
    private let recipeService = RecipeService()
    // אין כאן שום reference לשירות תרגום
    
    @State private var randomRecipes: [RecipeInfo] = []
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    Spacer()
                    ProgressView("טוען מתכונים...")
                    Spacer()
                } else {
                    List(randomRecipes) { recipeInfo in
                        NavigationLink(destination: RecipeDetailView(recipeId: recipeInfo.id)) {
                            let simpleRecipe = Recipe(id: recipeInfo.id, title: recipeInfo.title, image: recipeInfo.image)
                            RecipeCardView(recipe: simpleRecipe)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("גלה מתכונים")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: findRandomRecipes) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                if randomRecipes.isEmpty {
                    findRandomRecipes()
                }
            }
        }
    }
    
    // --- פונקציית חיפוש מתכונים אקראיים יציבה ---
    private func findRandomRecipes() {
        self.isLoading = true
        
        recipeService.fetchRandomRecipes(number: 10) { result in
            self.isLoading = false
            switch result {
            case .success(let recipes):
                self.randomRecipes = recipes.sorted { $0.title < $1.title } // אין תרגום כותרות
            case .failure(let error):
                print("Error getting random recipes: \(error.localizedDescription)")
            }
        }
    }
}
