import SwiftUI
import CoreData

struct PantryView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PantryItem.name, ascending: true)],
        animation: .default)
    private var pantryItems: FetchedResults<PantryItem>

    @State private var newIngredientName: String = ""
    
    // --- משתנים חדשים עבור הטיפול בתרגום ידני ---
    @State private var showAlert: Bool = false // לצורך הצגת אזהרה פשוטה (לא קריטי)
    @State private var alertMessage: String = ""
    @State private var showManualTranslationAlert: Bool = false // לצורך קופץ הקלט
    @State private var manualEnglishName: String = "" // לצורך קליטת הקלט הידני
    @State private var itemToTranslate: PantryItem? // הפריט שהמשתמש לוחץ עליו
    // ---------------------------------------------

    var body: some View {
        NavigationView {
            VStack {
                // --- אזור הוספת פריט ---
                HStack {
                    TextField("הוסף מצרך חדש...", text: $newIngredientName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.leading)

                    Button(action: addItem) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                    .padding(.trailing)
                    .disabled(newIngredientName.isEmpty)
                }
                .padding(.top)

                // --- רשימת המצרכים ---
                List {
                    ForEach(pantryItems) { item in
                        
                        HStack {
                            // 1. הצגת סימן קריאה אם התרגום נכשל
                            if item.isTranslated == false {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                    // 2. כאשר לוחצים על האזהרה, מציגים את קופץ הקלט הידני
                                    .onTapGesture {
                                        self.itemToTranslate = item
                                        self.showManualTranslationAlert = true
                                    }
                            } else {
                                // מקום ריק כדי לשמור על יישור
                                Color.clear.frame(width: 20)
                            }
                            
                            // מציג את שם המצרך (שנשמר בעברית)
                            Text(item.name ?? "")
                            Spacer()
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
            }
            .navigationTitle("המזווה שלי")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            // 3. ה-Alert הראשי שמקבל קלט ידני (לתרגום מנגו)
            .alert("הוסף תרגום למילה: \(itemToTranslate?.name ?? "")", isPresented: $showManualTranslationAlert) {
                
                TextField("הזן תרגום באנגלית (לדוגמה: Mango)", text: $manualEnglishName)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)

                Button("שמור תרגום", action: saveCustomTranslation)

                Button("בטל", role: .cancel) {
                    itemToTranslate = nil
                    manualEnglishName = ""
                }
            } message: {
                Text("הזן את המילה המדויקת באנגלית שתשלח לשרת המתכונים.")
            }
            // 4. Alert רגיל להצגת הודעות אזהרה אחרות (נשאר למקרה שנצטרך אותו)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("אזהרת תרגום"), message: Text(alertMessage), dismissButton: .default(Text("הבנתי")))
            }
        }
    }
    
    // --- 3. כל פונקציות הלוגיקה ---
    
    private func addItem() {
        let cleanName = self.newIngredientName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        withAnimation {
            // 1. בדיקת כפילות
            if pantryItems.first(where: { $0.name == cleanName }) != nil {
                print("פריט קיים: \(cleanName)")
                return
            }

            // 2. בדיקת תרגום (משתמש ב-viewContext)
            let translationSuccessful = HebrewTranslator.isTranslatable(cleanName, in: viewContext)
            let translated = HebrewTranslator.translate(cleanName, in: viewContext)
            
            // 3. יצירת פריט חדש ושמירת הסטטוס
            let newItem = PantryItem(context: viewContext)
            newItem.name = cleanName
            newItem.translatedName = translated
            newItem.isTranslated = translationSuccessful
            
            do {
                try viewContext.save()
                self.newIngredientName = "" // ניקוי שדה הטקסט
            } catch {
                print("שמירת מצרך נכשלה: \(error.localizedDescription)")
            }
        }
    }

    private func saveCustomTranslation() {
        guard let item = itemToTranslate,
              let hebrewName = item.name,
              !manualEnglishName.isEmpty else {
            itemToTranslate = nil
            manualEnglishName = ""
            return
        }

        let englishName = manualEnglishName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        withAnimation {
            // 1. שמירה לישות CustomTranslation
            let newTranslation = CustomTranslation(context: viewContext)
            newTranslation.hebrewName = hebrewName.lowercased()
            newTranslation.englishName = englishName
            
            // 2. עדכון הפריט הקיים במזווה
            item.translatedName = englishName
            item.isTranslated = true // מסמן שהתרגום הצליח עכשיו
            
            // 3. שמירת הקונטקסט ואיפוס משתנים
            do {
                try viewContext.save()
                itemToTranslate = nil
                manualEnglishName = ""
                print("תרגום מותאם אישית נשמר: \(hebrewName) -> \(englishName)")
            } catch {
                print("שמירת תרגום מותאם אישית נכשלה: \(error.localizedDescription)")
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            offsets.map { pantryItems[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save: \(error.localizedDescription)")
        }
    }
}
