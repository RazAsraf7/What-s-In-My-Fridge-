import Foundation
import CoreData // נדרש כדי לגשת לבסיס הנתונים המותאם אישית

// זהו המילון שלנו.
class HebrewTranslator {
    
    // המפתח (Key) הוא השם בעברית (בלי רווחים מיותרים)
    // הערך (Value) הוא התרגום לאנגלית
    static let map: [String: String] = [
        "אורז": "rice", "אפונה": "peas", "אבוקדו": "avocado", "אורגנו": "oregano", "אגוזי מלך": "walnuts",
        "בזיליקום": "basil", "בצל": "onion", "ביצה": "egg", "ביצים": "eggs", "במיה": "okra",
        "בננה": "banana", "בשר": "beef", "גזר": "carrot", "גבינה": "cheese", "גבינת קוטג": "cottage cheese",
        "דג": "fish", "דבש": "honey", "חלב": "milk", "חמאה": "butter", "חזה עוף": "chicken breast",
        "טונה": "tuna", "יוגורט": "yogurt", "כוסברה": "coriander", "כרוב": "cabbage", "כרובית": "cauliflower",
        "לימון": "lemon", "מלח": "salt", "מלפפון": "cucumber", "מיונז": "mayonnaise", "נענע": "mint",
        "סוכר": "sugar", "סלרי": "celery", "עגבניה": "tomato", "עגבניות": "tomatoes", "עוף": "chicken",
        "פילה סלמון": "salmon fillet", "פלפל": "pepper", "פטרוזיליה": "parsley", "פטריות": "mushrooms",
        "קמח": "flour", "קינואה": "quinoa", "קישוא": "zucchini", "קפה": "coffee", "שום": "garlic",
        "שמנת": "cream", "שעועית": "beans", "שקד": "almond", "תות": "strawberry", "תירס": "corn",
        "תפוז": "orange", "תפוח": "apple", "תפוח אדמה": "potato", "תרד": "spinach", "מים": "water",
        "שמן זית": "olive oil", "אורז בסמטי": "basmati rice", "בשר טחון": "ground beef", "לחם": "bread",
        "קמח חיטה": "wheat flour", "אבקת אפייה": "baking powder", "סודה לשתיה": "baking soda", "שמן": "oil",
        "אגוז": "nut", "שקדים": "almonds",
        // אתה יכול להוסיף כאן עוד פריטים בקלות!
    ]

    // פונקציה שמקבלת מילה בעברית ומחזירה את התרגום// --- הפונקציה הראשית לתרגום (מעודכנת) ---
    // כעת מקבלת את viewContext כדי לחפש ב-Core Data
    static func translate(_ hebrewTerm: String, in context: NSManagedObjectContext) -> String {
        let cleanTerm = hebrewTerm.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. בדיקה ראשונה: תרגום מותאם אישית (CustomTranslation)
        let request: NSFetchRequest<CustomTranslation> = CustomTranslation.fetchRequest()
        request.predicate = NSPredicate(format: "hebrewName == %@", cleanTerm)
        
        if let customResult = try? context.fetch(request).first,
           let englishName = customResult.englishName,
           !englishName.isEmpty {
            return englishName // נמצא בבסיס הנתונים של המשתמש!
        }
        
        // 2. בדיקה שנייה: המילון המובנה (map)
        if let translation = map[cleanTerm] {
            return translation // נמצא במילון הקשיח
        }
        
        // 3. לא נמצא: החזרת המילה המקורית
        return cleanTerm
    }
    
    // --- פונקציית בדיקת תרגום (מעודכנת) ---
    // הפונקציה בודקת אם המילה תורגמה בהצלחה (מובנה או מותאם אישית)
    static func isTranslatable(_ hebrewTerm: String, in context: NSManagedObjectContext) -> Bool {
        let cleanTerm = hebrewTerm.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. בדיקה במילון המותאם אישית
        let request: NSFetchRequest<CustomTranslation> = CustomTranslation.fetchRequest()
        request.predicate = NSPredicate(format: "hebrewName == %@", cleanTerm)
        if (try? context.fetch(request).first) != nil {
            return true
        }
        
        // 2. בדיקה במילון המובנה
        return map.keys.contains(cleanTerm)
    }
}
