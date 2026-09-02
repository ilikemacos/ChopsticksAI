import Foundation

enum PlateCatalog {
    static let ids = [
        "rice", "tamago", "hibachi",
        "wagyua1", "wagyua2", "wagyua3", "wagyua4", "wagyua5",
        "chopcode", "kaji", "max", "stickercoderplus",
    ]

    static func label(_ id: String, sky: Bool) -> String {
        if sky {
            switch id {
            case "rice": return "cs.AI 3.1"
            case "tamago": return "cs.AI 3.3-Fast"
            case "hibachi": return "cs.AI 3.3-Thinking"
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
        case "rice": return "Rice"
        case "tamago": return "Tamago"
        case "hibachi": return "Hibachi"
        case "wagyua1": return "Wagyu A1"
        case "wagyua2": return "Wagyu A2"
        case "wagyua3": return "Wagyu A3"
        case "wagyua4": return "Wagyu A4"
        case "wagyua5": return "Wagyu A5"
        case "chopcode": return "ChopCode"
        case "kaji": return "Kaji"
        case "max": return "Max"
        case "stickercoderplus": return "StickerCoder+"
        default: return id
        }
    }
}
