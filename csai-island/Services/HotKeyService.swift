import AppKit
import Carbon.HIToolbox

final class HotKeyService {
    private var eventHandler: EventHandlerRef?
    private var hotKey: EventHotKeyRef?

    func start() {
        guard AppSettings.shared.hotKeyEnabled else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let user = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            Task { @MainActor in
                IslandStateManager.shared.openAI()
                NotificationCenter.default.post(name: .islandNeedsLayout, object: nil)
            }
            return noErr
        }, 1, &spec, user, &eventHandler)
        let id = EventHotKeyID(signature: OSType(0x43534149), id: 1)
        RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(controlKey | optionKey),
            id,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
    }
}
