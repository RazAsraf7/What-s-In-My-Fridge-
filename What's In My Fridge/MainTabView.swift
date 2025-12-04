import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // כרטיסית ראשונה: המזווה
            PantryView()
                .tabItem {
                    Image(systemName: "refrigerator")
                    Text("המזווה שלי")
                }
            
            // כרטיסית שניה: חיפוש (מהמזווה)
            RecipeView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("חיפוש")
                }
            
            // ===================================
            // --- כאן נמצא התיקון ---
            // כרטיסית שלישית: גלה (חדש)
            // ===================================
            DiscoverView()
                .tabItem {
                    Image(systemName: "wand.and.stars") // אייקון של "גילוי"
                    Text("גלה")
                }
            
            // כרטיסית רביעית: רשימת קניות
            NavigationView {
                ShoppingListView()
            }
            .tabItem {
                Image(systemName: "cart")
                Text("רשימת קניות")
            }
        }
        .accentColor(.green) // הצבע הירוק נשמר
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
