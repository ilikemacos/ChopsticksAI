import Foundation

enum PlateCatalog {
    static let ids = [
        "csaifast", "csaiauto", "csai47flash", "csai46core", "csai46swift", "csai46lite",
        "csai46corepro", "csai47pro",
        "csai4air", "chopcode",
        "wagyua1", "wagyua2", "wagyua3", "wagyua4", "wagyua5",
        "kaji", "max", "stickercoderplus",
    ]

    static func isHqPro(_ id: String) -> Bool {
        id == "csai4air" || id == "chopcode"
    }

    static func label(_ id: String, sky: Bool) -> String {
        if sky {
            switch id {
            case "csaifast": return "Fast"
            case "csaiauto": return "Auto"
            case "csai47flash": return "Flash"
            case "csai46core": return "Core"
            case "csai46swift": return "Swift"
            case "csai46lite": return "Lite"
            case "csai46corepro": return "Core-Pro"
            case "csai47pro": return "Pro"
            case "csai4air": return "cs.AI-4.0-Air"
            case "wagyua1": return "Air II"
            case "wagyua2": return "Air III"
            case "wagyua3": return "Air VI"
            case "wagyua4": return "Air V"
            case "wagyua5": return "cs.AI 3.5-Air"
            case "chopcode": return "csCode-Pro"
            case "kaji": return "Kaji"
            case "max": return "Max"
            case "stickercoderplus": return "StickerCoder+"
            default: return id
            }
        }
        switch id {
        case "csaifast": return "Fast"
        case "csaiauto": return "Auto"
        case "csai47flash": return "Flash"
        case "csai46core": return "Core"
        case "csai46swift": return "Swift"
        case "csai46lite": return "Lite"
        case "csai46corepro": return "Core-Pro"
        case "csai47pro": return "Pro"
        case "csai4air": return "cs.AI-4.0-Air"
        case "wagyua1": return "Wagyu A1"
        case "wagyua2": return "Wagyu A2"
        case "wagyua3": return "Wagyu A3"
        case "wagyua4": return "Wagyu A4"
        case "wagyua5": return "Wagyu A5"
        case "chopcode": return "csCode-Pro"
        case "kaji": return "Kaji"
        case "max": return "Max"
        case "stickercoderplus": return "StickerCoder+"
        default: return id
        }
    }
}
