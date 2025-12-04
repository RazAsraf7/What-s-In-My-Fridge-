import SwiftUI

// הרחבה של Color שמאפשרת לנו ליצור צבעים מותאמים אישית
extension Color {
    
    // קבוצת צבעים מותאמת אישית
    struct Theme {
        
        /// הצבע המוביל שלנו (הירוק)
        static let accent = Color.green
        
        /// צבע רקע ראשי (אפרפר בהיר מאוד)
        static let background = Color(UIColor.systemGray6)
        
        /// צבע לרקע של כרטיסיות ואלמנטים
        static let cardBackground = Color(UIColor.systemBackground) // לבן/שחור (מותאם ל-Dark Mode)
        
        /// צבע טקסט ראשי (אפור כהה)
        static let textPrimary = Color(UIColor.label)
        
        /// צבע טקסט משני (אפור בינוני)
        static let textSecondary = Color(UIColor.secondaryLabel)
    }
}
