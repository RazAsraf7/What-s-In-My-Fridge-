import Foundation
import CoreData

// הקובץ מסתמך על המודלים: Recipe, RecipeInfo, RandomRecipeResponse, Ingredient
// המוגדרים בקובץ RecipeModels.swift.

// גלובלי כדי לגשת ל-Core Data context (נדרש עבור Caching)
// הפנייה חיצונית ל-PersistenceController
private let viewContext = PersistenceController.shared.container.viewContext

class RecipeService {
    
    enum RecipeError: Error {
        case invalidURL
        case noData
        case decodingError
        case requestError
        case apiKeyMissing
    }
    
    // קורא את מפתח Spoonacular הראשי מה-Info.plist
    private func getSpoonacularAPIKey() -> String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SpoonacularAPIKey") as? String else {
            print("ERROR: 'SpoonacularAPIKey' not found in Info.plist.")
            return nil
        }
        return key
    }
    
    // --- CACHE HELPER FUNCTIONS ---
    
    // Loads recipes from the local cache
    private func getCachedRecipes(for key: String) -> [Recipe]? {
        let request: NSFetchRequest<CachedRecipe> = CachedRecipe.fetchRequest()
        request.predicate = NSPredicate(format: "cacheKey == %@", key)
        
        do {
            let cachedEntities = try viewContext.fetch(request)
            guard !cachedEntities.isEmpty else { return nil }
            
            // המרה חזרה ל-Recipe struct
            return cachedEntities.map { Recipe(id: Int($0.id), title: $0.title ?? "", image: $0.image ?? "") }
        } catch {
            print("Error fetching cache: \(error)")
            return nil
        }
    }
    
    // Saves new recipes to the local cache
    private func saveRecipesToCache(_ recipes: [Recipe], withKey key: String) {
        
        // 1. ניקוי Cache ישן
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CachedRecipe.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cacheKey == %@", key)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(deleteRequest)
        } catch {
            print("Could not clear old cache: \(error)")
        }
        
        // 2. שמירת Cache חדש
        for recipe in recipes {
            let newCacheEntry = CachedRecipe(context: viewContext)
            newCacheEntry.cacheKey = key
            // --- התיקון הקריטי: המרה ל-Int32 ---
            newCacheEntry.id = Int32(recipe.id)
            newCacheEntry.title = recipe.title
            newCacheEntry.image = recipe.image
        }
        
        // 3. שמירת הקונטקסט
        do {
            try viewContext.save()
        } catch {
            print("Error saving cache: \(error)")
        }
    }
    
    // --- FUNCTON 1: Fetch Recipes (WITH CACHING LOGIC) ---
    func fetchRecipes(byIngredients ingredients: [String], completion: @escaping (Result<[Recipe], RecipeError>) -> Void) {
        
        let cacheKey = ingredients.sorted().joined(separator: ",")
        
        // 1. בדיקת Cache
        if let cachedRecipes = self.getCachedRecipes(for: cacheKey) {
            print("CACHE HIT: Loading recipes from local storage for key: \(cacheKey)")
            completion(.success(cachedRecipes))
            return
        }
        
        // 2. רשת (אם Cache Miss)
        guard let apiKey = getSpoonacularAPIKey() else {
            completion(.failure(.apiKeyMissing))
            return
        }

        let ingredientsString = ingredients
            .map { $0.lowercased().replacingOccurrences(of: " ", with: "+") }
            .joined(separator: ",")
        
        let urlString = "https://api.spoonacular.com/recipes/findByIngredients?ingredients=\(ingredientsString)&number=10&ranking=1&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            
            guard let data = data, error == nil else {
                completion(.failure(.requestError))
                return
            }
            
            do {
                let recipes = try JSONDecoder().decode([Recipe].self, from: data)
                
                // 3. כתיבה ל-Cache
                self.saveRecipesToCache(recipes, withKey: cacheKey)
                
                DispatchQueue.main.async {
                    completion(.success(recipes))
                }
            } catch {
                print("שגיאת פענוח: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.decodingError))
                }
            }
            
        }.resume()
    }
    
    // --- Functon 2 & 3 (ללא שינוי, לוגיקת המפתח תוקנה בנפרד) ---
    
    func fetchRecipeDetails(byId id: Int, completion: @escaping (Result<RecipeInfo, RecipeError>) -> Void) {
        guard let apiKey = getSpoonacularAPIKey() else { completion(.failure(.apiKeyMissing)); return }
        let urlString = "https://api.spoonacular.com/recipes/\(id)/information?includeNutrition=false&apiKey=\(apiKey)"
        guard let url = URL(string: urlString) else { completion(.failure(.invalidURL)); return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { completion(.failure(.requestError)); return }
            do { let recipeInfo = try JSONDecoder().decode(RecipeInfo.self, from: data); DispatchQueue.main.async { completion(.success(recipeInfo)) } } catch { print("שגיאת פענוח פרטי מתכון: \(error)"); DispatchQueue.main.async { completion(.failure(.decodingError)) } }
        }.resume()
    }
    
    func fetchRandomRecipes(number: Int, completion: @escaping (Result<[RecipeInfo], RecipeError>) -> Void) {
        guard let apiKey = getSpoonacularAPIKey() else { completion(.failure(.apiKeyMissing)); return }
        let urlString = "https://api.spoonacular.com/recipes/random?number=\(number)&apiKey=\(apiKey)"
        guard let url = URL(string: urlString) else { completion(.failure(.invalidURL)); return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { completion(.failure(.requestError)); return }
            do { let response = try JSONDecoder().decode(RandomRecipeResponse.self, from: data); DispatchQueue.main.async { completion(.success(response.recipes)) } } catch { print("שגיאת פענוח מתכונים אקראיים: \(error)"); DispatchQueue.main.async { completion(.failure(.decodingError)) } }
        }.resume()
    }
}
