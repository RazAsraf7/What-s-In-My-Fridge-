import SwiftUI
import CoreData

struct ShoppingListView: View {
    
    @Environment(\.managedObjectContext) private var viewContext

    // 1. שליפה של רשימת הקניות (קיים)
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ShoppingListItem.isBought, ascending: true),
            NSSortDescriptor(keyPath: \ShoppingListItem.name, ascending: true)
        ],
        animation: .default)
    private var shoppingItems: FetchedResults<ShoppingListItem>
    
    // ===================================
    // --- כאן נמצא התיקון (1 מתוך 2) ---
    // 2. נוסיף שליפה של פריטי המזווה
    // כדי שנוכל לבדוק אם פריט כבר קיים שם
    // ===================================
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PantryItem.name, ascending: true)],
        animation: .default)
    private var pantryItems: FetchedResults<PantryItem>

    var body: some View {
        List {
            ForEach(shoppingItems) { item in
                HStack {
                    Button(action: {
                        toggleItem(item) // הפונקציה הזו עודכנה
                    }) {
                        Image(systemName: item.isBought ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(item.isBought ? .green : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text(item.name ?? "ללא שם")
                        .strikethrough(item.isBought)
                        .foregroundColor(item.isBought ? .gray : .primary)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle("רשימת קניות")
        .toolbar {
            EditButton()
        }
    }

    // --- פונקציות עזר ---
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            offsets.map { shoppingItems[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    // ===================================
    // --- כאן נמצא התיקון (2 מתוך 2) ---
    // הפונקציה הזו שודרגה
    // ===================================
    private func toggleItem(_ item: ShoppingListItem) {
        withAnimation {
            // 1. הופכים את מצב הפריט
            item.isBought.toggle()
            
            // 2. אם הפריט *סומן עכשיו* כ"נקנה"
            if item.isBought {
                guard let itemName = item.name else { return } // 3. ניקח את השם שלו
                
                // 4. נבדוק אם הוא כבר קיים במזווה
                let alreadyInPantry = pantryItems.contains { $0.name?.lowercased() == itemName.lowercased() }
                
                // 5. אם הוא *לא* קיים במזווה, נוסיף אותו
                if !alreadyInPantry {
                    let newPantryItem = PantryItem(context: viewContext)
                    newPantryItem.name = itemName
                }
            }
            // 6. נשמור את כל השינויים (גם את הסימון וגם את הפריט החדש)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("השמירה נכשלה: \(error.localizedDescription)")
        }
    }
}

// ----- תצוגה מקדימה (Preview) -----
struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ShoppingListView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
