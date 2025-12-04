import SwiftUI
import CoreData

struct RecipeDetailView: View {
    
    // 1. כל המשתנים וה-Fetch Requests
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \PantryItem.name, ascending: true)])
    private var pantryItems: FetchedResults<PantryItem>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ShoppingListItem.isBought, ascending: true),
                                      NSSortDescriptor(keyPath: \ShoppingListItem.name, ascending: true)])
    private var shoppingItems: FetchedResults<ShoppingListItem>

    let recipeId: Int
    private let recipeService = RecipeService()
    
    @State private var recipeInfo: RecipeInfo?
    @State private var isLoading = true
    
    @State private var ownedIngredients: [Ingredient] = []
    @State private var missingIngredients: [Ingredient] = []

    // 2. ה-UI המעוצב של המסך
    var body: some View {
        ZStack {
            Color.Theme.background.ignoresSafeArea()
            
            if isLoading {
                ProgressView("טוען פרטי מתכון...")
            } else if let info = recipeInfo {
                List {
                    // --- חלק 1: תמונה ---
                    Section {
                        AsyncImage(url: URL(string: info.image)) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: 200)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    
                    // --- חלק 2: זמן הכנה ---
                    if let prepTime = info.readyInMinutes {
                        Section {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.Theme.accent)
                                Text("זמן הכנה:")
                                    .font(.headline)
                                Spacer()
                                Text("\(prepTime) דקות")
                                    .font(.body)
                                    .foregroundColor(.Theme.textSecondary)
                            }
                        }
                    }
                    
                    // --- חלק 3: מצרכים "יש לך" ---
                    Section(header: Text("יש לך במקרר (\(ownedIngredients.count))").font(.headline)) {
                        ForEach(ownedIngredients) { ingredient in
                            Text("✅ \(ingredient.description)")
                                .foregroundColor(.green)
                        }
                    }
                    
                    // --- חלק 4: מצרכים "חסר לך" ---
                    Section(header: Text("חסר לך (\(missingIngredients.count))").font(.headline)) {
                        ForEach(missingIngredients) { ingredient in
                            Button(action: { addMissingIngredient(ingredient) }) {
                                Text("❌ \(ingredient.description)")
                                    .foregroundColor(.red)
                            }
                            .disabled(isAlreadyInActiveShoppingList(ingredient))
                        }
                    }
                    
                    // --- חלק 5: הוראות הכנה ---
                    Section(header: Text("הוראות הכנה").font(.headline)) {
                        if let instructions = info.instructions, !instructions.isEmpty {
                            Text(instructions.stripHTML())
                                .font(.body)
                                .foregroundColor(.Theme.textPrimary)
                        } else {
                            Text("לא נמצאו הוראות הכנה.")
                                .foregroundColor(.Theme.textSecondary)
                        }
                    }
                    
                    // --- חלק 6: קישור למקור ---
                    if let urlString = info.sourceUrl, let url = URL(string: urlString) {
                        Section {
                            Link("למתכון המלא באתר המקור", destination: url)
                                .font(.headline)
                                .foregroundColor(.Theme.accent)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                Text("שגיאה בטעינת המתכון.")
                    .foregroundColor(.Theme.textSecondary)
            }
            
        } // סוף ZStack
        
        .onAppear {
            if recipeInfo == nil {
                fetchDetails()
            }
        }
        .navigationTitle(recipeInfo?.title ?? "טוען...")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // --- 3. כל פונקציות העזר (לוגיקה) ---
    
    func fetchDetails() {
        recipeService.fetchRecipeDetails(byId: recipeId) { result in
            isLoading = false
            switch result {
            case .success(let info):
                self.recipeInfo = info
                // קורא ישירות למיון מצרכים
                self.classifyIngredients(allIngredients: info.extendedIngredients)
            case .failure(let error):
                print("שגיאה: \(error.localizedDescription)")
            }
        }
    }
    
    // בקובץ RecipeDetailView.swift
    // בתוך RecipeDetailView.swift
    // בתוך RecipeDetailView.swift, החלף את הפונקציה classifyIngredients כולה

    func classifyIngredients(allIngredients: [Ingredient]) {
        
        // 1. יצירת Set של המצרכים במזווה שלך, מתורגמים לאנגלית ונקיים (החלק היעיל)
        let englishPantryNames: Set<String> = {
            var names = Set<String>()
            
            let hebrewPantryNames = pantryItems.compactMap {
                $0.name?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            for hebrewName in hebrewPantryNames {
                // **התיקון הקריטי: העברנו את viewContext**
                let translatedName = HebrewTranslator.translate(hebrewName, in: viewContext)
                
                // המילה המתורגמת (למשל, "onion") מוכנסת ל-Set (O(1) lookup)
                names.insert(translatedName.lowercased())
            }
            return names
        }()
        
        ownedIngredients = []
        missingIngredients = []
        
        // 2. השוואה מהירה (O(1) Search)
        for ingredient in allIngredients {
            
            // מנרמל את שם המצרך מהמתכון (אנגלית)
            let ingredientNameFromRecipe = normalize(ingredient.name).lowercased()
            
            var found = false
            
            // א. חיפוש O(1) (הכי מהיר): האם שם המתכון קיים בדיוק במזווה המתורגם?
            if englishPantryNames.contains(ingredientNameFromRecipe) {
                found = true
            } else {
                // ב. חיפוש הכלה (חיוני לדיוק)
                for englishPantryItemName in englishPantryNames {
                    if !englishPantryItemName.isEmpty {
                        if ingredientNameFromRecipe.contains(englishPantryItemName) || englishPantryItemName.contains(ingredientNameFromRecipe) {
                            found = true
                            break
                        }
                    }
                }
            }
            
            // 3. סיווג
            if found {
                ownedIngredients.append(Ingredient(id: ingredient.id,
                                                   name: normalize(ingredient.name),
                                                   amount: ingredient.amount,
                                                   unit: ingredient.unit))
            } else {
                addOrMergeMissing(ingredient)
            }
        }
    }
    
    private func normalize(_ name: String) -> String {
        let lower = name.lowercased()
        
        if lower == "tomatoe" || lower == "tomatos" {
            return "Tomato"
        }
        
        return name.capitalized
    }
    
    private func addOrMergeMissing(_ newIngredient: Ingredient) {
        
        let normalizedIngredient = Ingredient(id: newIngredient.id,
                                            name: normalize(newIngredient.name),
                                            amount: newIngredient.amount,
                                            unit: newIngredient.unit)
        
        if let existingIndex = missingIngredients.firstIndex(where: {
            $0.name.lowercased() == normalizedIngredient.name.lowercased() &&
            $0.unit.lowercased() == normalizedIngredient.unit.lowercased()
        }) {
            let existing = missingIngredients[existingIndex]
            let mergedAmount = existing.amount + normalizedIngredient.amount
            
            let mergedIngredient = Ingredient(id: existing.id,
                                                name: existing.name,
                                                amount: mergedAmount,
                                                unit: existing.unit)
            missingIngredients[existingIndex] = mergedIngredient
            
        } else {
            missingIngredients.append(normalizedIngredient)
        }
    }
    
    // בתוך RecipeDetailView.swift

    private func addMissingIngredient(_ ingredient: Ingredient) {
        
        // 1. נרמל את שם המצרך (אנגלית)
        let englishIngredientName = normalize(ingredient.name)
        
        // 2. נתרגם את שם המצרך בחזרה לעברית באמצעות המילון.
        // מכיוון ש-HebrewTranslator.map הוא אנגלית -> עברית, אנחנו נהפוך את המילון
        // כדי למצוא את השם המקורי בעברית (אם קיים), או נחזיר את שם המתכון כפי שהוא.
        
        // יצירת מילון הפוך זמני: English -> Hebrew
        let englishToHebrewMap: [String: String] = {
            var map: [String: String] = [:]
            for (hebrew, english) in HebrewTranslator.map {
                map[english.capitalized] = hebrew.capitalized
            }
            return map
        }()
        
        // ננסה למצוא את השם העברי (e.g., "בצל") לפי השם האנגלי (e.g., "Onion")
        let hebrewShoppingName = englishToHebrewMap[englishIngredientName.capitalized] ?? englishIngredientName
        
        
        let existingItem = shoppingItems.first { $0.name == hebrewShoppingName }
        
        withAnimation {
            if let existingItem = existingItem {
                // אם הפריט קיים ונקנה, נחזיר אותו לרשימה (isBought = false)
                if existingItem.isBought {
                    existingItem.isBought = false
                }
            } else {
                // אם הפריט לא קיים, ניצור אותו בשם העברי המתורגם
                let newItem = ShoppingListItem(context: viewContext)
                newItem.name = hebrewShoppingName
            }
            
            do {
                try viewContext.save()
            } catch {
                print("השמירה לרשימת הקניות נכשלה: \(error.localizedDescription)")
            }
        }
    }
    
    private func isAlreadyInActiveShoppingList(_ ingredient: Ingredient) -> Bool {
        let ingredientName = ingredient.name
        return shoppingItems.contains { $0.name == ingredientName && !$0.isBought }
    }
}


// --- הרחבה לניקוי HTML ---
extension String {
    func stripHTML() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}


// --- תצוגה מקדימה (Preview) ---
struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RecipeDetailView(recipeId: 716429)
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
