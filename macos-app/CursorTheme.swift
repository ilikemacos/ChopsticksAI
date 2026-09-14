import SwiftUI

enum Cursor {
    static let bg = Color.black
    static let sidebar = Color.black
    static let rail = Color.black
    static let panel = Color(red: 0.086, green: 0.094, blue: 0.110)
    static let composer = Color(red: 0.086, green: 0.094, blue: 0.110)
    static let hover = Color(red: 0.118, green: 0.125, blue: 0.141)
    static let selected = Color(red: 0.153, green: 0.165, blue: 0.180)
    static let hairline = Color(red: 0.184, green: 0.200, blue: 0.212)
    static let border = Color(red: 0.184, green: 0.200, blue: 0.212)
    static let muted = Color(red: 0.443, green: 0.463, blue: 0.482)
    static let soft = Color(red: 0.906, green: 0.914, blue: 0.918)
    static let text = Color(red: 0.906, green: 0.914, blue: 0.918)
    static let userBubble = Color(red: 0.086, green: 0.094, blue: 0.110)
    static let accent = Color.white
    static let accentFg = Color.black
    static let blue = Color(red: 0.114, green: 0.608, blue: 0.941)
    static let green = Color(red: 0.000, green: 0.729, blue: 0.486)
    static let chromium = Color(red: 0.114, green: 0.608, blue: 0.941)
    static var mozilla: Color { chromium }

    static let motionPanel = Animation.spring(response: 0.52, dampingFraction: 0.92)
    static let motionNav = Animation.spring(response: 0.48, dampingFraction: 0.94)
    static let motionSoft = Animation.easeInOut(duration: 0.36)
}

enum AppNav: String, CaseIterable, Identifiable {
    case agents
    case kaji
    case search
    case labs
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
        case .agents: return "Chats"
        case .kaji: return "Kaji"
        case .search: return "Browser"
        case .labs: return "Labs"
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
        case .kaji: return "sparkle"
        case .search: return "globe"
        case .labs: return "square.grid.2x2"
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
