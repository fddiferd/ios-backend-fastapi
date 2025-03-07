import FirebaseRemoteConfig
import FirebaseFirestore

class NetworkManager {
    private let remoteConfig = RemoteConfig.remoteConfig()
    private let db = Firestore.firestore()
    
    init() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
    }
    
    func getBaseURL(completion: @escaping (String) -> Void) {
        #if DEBUG
        let branch = Bundle.main.infoDictionary?["BRANCH_NAME"] as? String ?? "main"
        let projectName = Bundle.main.infoDictionary?["PROJECT_NAME"] as? String ?? "default-project"
        
        db.collection("projects").document("\(projectName)-\(branch)").getDocument { document, error in
            if let url = document?.data()?["url"] as? String {
                completion(url)
            } else {
                completion(self.remoteConfig.configValue(forKey: "api_url_\(branch)").stringValue ?? "https://\(branch)-api.yourdomain.com")
            }
        }
        #else
        completion(remoteConfig.configValue(forKey: "api_url_prod").stringValue ?? "https://api.yourdomain.com")
        #endif
    }
} 