import SwiftUI

@main
struct What_s_In_My_FridgeApp: App { // <-- תחליף את YourAppName בשם הפרויקט שלך
    
    // 1. ניצור עותק של בקר בסיס הנתונים שיצרנו
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                // 2. "נזריק" את בסיס הנתונים הפעיל (ה-context)
                // לתוך סביבת העבודה של SwiftUI.
                // זה מאפשר ל-ContentView לגשת אליו.
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
