enum Environment {
    case local
    case staging
    case production
    
    var apiBaseURL: String {
        switch self {
        case .local: return "http://localhost:8000"
        case .staging: return "https://wedge-staging-api-xyz.a.run.app"
        case .production: return "https://wedge-prod-api-xyz.a.run.app"
        }
    }
}

struct Configuration {
    static var environment: Environment {
        #if DEBUG
            return .local
        #elseif STAGING
            return .staging
        #else
            return .production
        #endif
    }
} 