import Carbon.HIToolbox
import Foundation

@MainActor
final class HotKeyManager {
    var onClipboardPressed: (() -> Void)?
    var onApplicationPressed: ((UUID) -> Void)?

    private var hotKeys: [UInt32: EventHotKeyRef] = [:]
    private var shortcutIDs: [UInt32: UUID] = [:]
    private var eventHandler: EventHandlerRef?

    init() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }
                var identifier = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &identifier
                )
                guard status == noErr else { return status }

                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in
                    manager.handle(identifier.id)
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        _ = register(
            id: 1,
            keyCode: UInt32(kVK_ANSI_X),
            modifiers: UInt32(controlKey)
        )
    }

    func updateApplicationShortcuts(_ shortcuts: [AppShortcut]) -> [UUID] {
        for id in hotKeys.keys where id >= 100 {
            if let hotKey = hotKeys.removeValue(forKey: id) {
                UnregisterEventHotKey(hotKey)
            }
        }
        shortcutIDs.removeAll()
        var failedIDs: [UUID] = []

        for (index, shortcut) in shortcuts.enumerated() {
            guard let keyCode = shortcut.keyCode,
                  let modifiers = shortcut.modifiers else {
                continue
            }
            let id = UInt32(index + 100)
            if register(id: id, keyCode: keyCode, modifiers: modifiers) {
                shortcutIDs[id] = shortcut.id
            } else {
                failedIDs.append(shortcut.id)
            }
        }
        return failedIDs
    }

    private func register(id: UInt32, keyCode: UInt32, modifiers: UInt32) -> Bool {
        let identifier = EventHotKeyID(signature: fourCharacterCode("CLIP"), id: id)
        var hotKey: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            identifier,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
        guard status == noErr, let hotKey else { return false }
        hotKeys[id] = hotKey
        return true
    }

    private func handle(_ id: UInt32) {
        if id == 1 {
            onClipboardPressed?()
        } else if let shortcutID = shortcutIDs[id] {
            onApplicationPressed?(shortcutID)
        }
    }

    private func fourCharacterCode(_ value: String) -> OSType {
        value.utf8.reduce(0) { ($0 << 8) + OSType($1) }
    }
}
