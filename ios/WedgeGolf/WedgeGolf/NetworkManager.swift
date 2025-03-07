import FirebaseFirestore

class NetworkManager {
    private let db = Firestore.firestore()
    
    func getBaseURL(completion: @escaping (String) -> Void) {
        #if DEBUG
        let branch = Bundle.main.infoDictionary?["BRANCH_NAME"] as? String ?? "main"
        let projectName = Bundle.main.infoDictionary?["PROJECT_NAME"] as? String ?? "default-project"
        
        db.collection("projects").document("\(projectName)-\(branch)").getDocument { document, error in
            if let url = document?.data()?["url"] as? String {
                completion(url)
            } else {
                completion("https://\(branch)-api.yourdomain.com")
            }
        }
        #else
        completion("https://api.yourdomain.com")
        #endif
    }
} 