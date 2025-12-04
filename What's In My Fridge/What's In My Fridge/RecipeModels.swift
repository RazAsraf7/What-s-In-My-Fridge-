import Foundation

// מודל 1: תוצאת חיפוש (מהרשימה)
struct Recipe: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let image: String
}


// ------------------------------------
// מודל 2: פרטי מתכון מלאים
// ------------------------------------

struct RecipeInfo: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let image: String
    
    let extendedIngredients: [Ingredient]
    
    let instructions: String?
    let sourceUrl: String?
    
    // ===================================
    // --- כאן נמצא התיקון ---
    // הוספנו את השדה של זמן הכנה
    // ===================================
    let readyInMinutes: Int? // הוספנו '?' כי לפעמים זה ריק

    
    // פונקציות תמיכה ב-Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: RecipeInfo, rhs: RecipeInfo) -> Bool {
        lhs.id == rhs.id
    }
}

// מודל 3: מצרך בודד
struct Ingredient: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let amount: Double
    let unit: String
    
    var description: String {
        let formattedAmount = String(format: "%g", amount)
        return "\(formattedAmount) \(unit) \(name)"
    }
}

// מודל 4: מעטפת לתשובת מתכונים אקראיים
struct RandomRecipeResponse: Codable {
    let recipes: [RecipeInfo]
}
