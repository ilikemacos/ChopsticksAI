import Foundation

final class ConversationStore {
    private let key = "csai.island.history"

    func load() -> [ChatTurn] {
        guard AppSettings.shared.keepHistory,
              let data = UserDefaults.standard.data(forKey: key),
              let turns = try? JSONDecoder().decode([ChatTurn].self, from: data) else { return [] }
        return turns
    }

    func save(_ turns: [ChatTurn]) {
        guard AppSettings.shared.keepHistory else {
            UserDefaults.standard.removeObject(forKey: key)
            return
        }
        let clipped = Array(turns.suffix(40))
        UserDefaults.standard.set(try? JSONEncoder().encode(clipped), forKey: key)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
