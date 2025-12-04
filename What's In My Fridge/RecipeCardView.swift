import SwiftUI

struct RecipeCardView: View {
    
    // הכרטיס מקבל מתכון (מהסוג הפשוט)
    let recipe: Recipe

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 1. התמונה (AsyncImage) משמשת כרקע
            AsyncImage(url: URL(string: recipe.image)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                // רקע אפור בזמן טעינה
                Color.Theme.background
            }
            .frame(height: 200) // גובה קבוע לכל הכרטיסיות
            
            // 2. שכבת צל שחורה-שקופה בתחתית
            // כדי שהטקסט הלבן יבלוט
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.black.opacity(0.8), .clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(height: 100)

            // 3. הטקסט של הכותרת
            Text(recipe.title)
                .font(.title3) // פונט קטן יותר מכותרת רגילה
                .fontWeight(.bold)
                .foregroundColor(.white) // טקסט לבן
                .padding()
        }
        .frame(height: 200)
        .cornerRadius(15) // פינות מעוגלות
        .shadow(color: .black.opacity(0.2), radius: 5, y: 2) // צל עדין
        .padding(.vertical, 8)
    }
}

// Preview (רק כדי לראות איך זה נראה)
struct RecipeCardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRecipe = Recipe(id: 1, title: "Classic Margherita Pizza", image: "https://spoonacular.com/recipeImages/639388-556x370.jpg")
        RecipeCardView(recipe: sampleRecipe)
            .padding()
    }
}
