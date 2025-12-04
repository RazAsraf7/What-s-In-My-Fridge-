import Foundation

// 1. מודלים ל-DeepL
struct DeepLResponse: Codable {
    let translations: [DeepLTranslation]
}

struct DeepLTranslation: Codable {
    let detected_source_language: String
    let text: String
}


// 2. השירות המעודכן
class DeepLService {
    
    enum TranslateError: Error {
        case invalidURL
        case noData
        case decodingError
        case requestError
        case apiKeyMissing
    }
    
    // קורא את המפתח DeepL מה-Info.plist
    private func getAPIKey() -> String? {
        // ודא שהמפתח DeepLAPIKey נמצא ב-Info.plist
        guard let key = Bundle.main.object(forInfoDictionaryKey: "DeepLAPIKey") as? String else {
            print("ERROR: 'DeepLAPIKey' not found in Info.plist.")
            return nil
        }
        return key
    }
    
    /**
     * מתרגם מילה אחת דרך DeepL API.
     * השיטה משתמשת בקידוד Form URL-Encoded.
     */
    func translate(term: String, completion: @escaping (Result<String, TranslateError>) -> Void) {
        
        guard let apiKey = getAPIKey() else {
            completion(.failure(.apiKeyMissing))
            return
        }

        // כתובת ה-URL של DeepL Free API
        guard let url = URL(string: "https://api-free.deepl.com/v2/translate") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // שליחה בפורמט DeepL-Auth-Key ב-Header
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        
        
        // יצירת גוף הבקשה (ללא המפתח)
        let components = [
            "text": term,
            "source_lang": "HE",
            "target_lang": "EN-US"
        ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")

        request.httpBody = components.data(using: .utf8)
        
        // ביצוע קריאת הרשת
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let data = data, error == nil else {
                completion(.failure(.requestError))
                return
            }
            
            do {
                let deepLResponse = try JSONDecoder().decode(DeepLResponse.self, from: data)
                
                if let firstTranslation = deepLResponse.translations.first {
                    DispatchQueue.main.async {
                        completion(.success(firstTranslation.text))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.noData))
                    }
                }
            } catch {
                print("שגיאת פענוח DeepL: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.decodingError))
                }
            }
            
        }.resume()
    }
}
