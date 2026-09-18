import ServiceManagement

enum LoginItemService {
    static func set(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Unsigned local builds often cannot register a login item.
            }
        }
    }
}
