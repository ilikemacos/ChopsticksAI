import SwiftUI

enum Cursor {
    static let bg = Color(red: 0.086, green: 0.086, blue: 0.086)          
    static let sidebar = Color(red: 0.075, green: 0.075, blue: 0.075)     
    static let rail = Color(red: 0.067, green: 0.067, blue: 0.067)        
    static let panel = Color(red: 0.110, green: 0.110, blue: 0.110)       
    static let composer = Color(red: 0.129, green: 0.129, blue: 0.129)    
    static let hover = Color(red: 0.165, green: 0.165, blue: 0.165)       
    static let selected = Color(red: 0.188, green: 0.188, blue: 0.188)    
    static let hairline = Color.white.opacity(0.07)
    static let border = Color.white.opacity(0.11)
    static let muted = Color.white.opacity(0.42)
    static let soft = Color.white.opacity(0.68)
    static let text = Color.white.opacity(0.92)
    static let userBubble = Color(red: 0.165, green: 0.165, blue: 0.165)
    static let accent = Color.white
    static let accentFg = Color.black
    static let blue = Color(red: 0.35, green: 0.55, blue: 0.98)
    static let green = Color(red: 0.35, green: 0.72, blue: 0.48)
    static let chromium = Color(red: 0.102, green: 0.451, blue: 0.910)
    static var mozilla: Color { chromium }
}

enum AppNav: String, CaseIterable, Identifiable {
    case agents
    case search
    case cloudAgents
    case automations
    case repos
    case marketplace
    case moreModels
    case usage
    case account
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .agents: return "Agents"
        case .search: return "Browser"
        case .cloudAgents: return "Cloud Agents (preview)"
        case .automations: return "Automations (preview)"
        case .repos: return "Repositories"
        case .marketplace: return "Marketplace (preview)"
        case .moreModels: return "More models"
        case .usage: return "Usage"
        case .account: return "Account"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .agents: return "bubble.left.and.bubble.right"
        case .search: return "globe"
        case .cloudAgents: return "cloud"
        case .automations: return "arrow.triangle.2.circlepath"
        case .repos: return "externaldrive"
        case .marketplace: return "puzzlepiece.extension"
        case .moreModels: return "sparkles"
        case .usage: return "chart.bar"
        case .account: return "person.crop.circle"
        case .settings: return "gearshape"
        }
    }
}

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case chat
    case appearance
    case agents
    case models
    case rules
    case customize
    case plugins
    case mcp
    case indexing
    case hooks
    case cloudAgents
    case network
    case beta
    case privacy
    case planUsage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .chat: return "Chat"
        case .appearance: return "Appearance"
        case .agents: return "Agents"
        case .models: return "Models"
        case .rules: return "Rules, Skills, Subagents"
        case .customize: return "Customize"
        case .plugins: return "Plugins (preview)"
        case .mcp: return "Tools & MCPs (preview)"
        case .indexing: return "Indexing & Docs (preview)"
        case .hooks: return "Hooks (preview)"
        case .cloudAgents: return "Cloud Agents (preview)"
        case .network: return "Network"
        case .beta: return "Beta"
        case .privacy: return "Privacy"
        case .planUsage: return "Plan & Usage"
        }
    }
}
