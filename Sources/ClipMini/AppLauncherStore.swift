import Combine
import Foundation

struct AppShortcut: Codable, Identifiable, Hashable {
    let id: UUID
    let appName: String
    let appPath: String
    let keyCode: UInt32?
    let modifiers: UInt32?
    let shortcutLabel: String?

    func settingShortcut(keyCode: UInt32, modifiers: UInt32, label: String) -> AppShortcut {
        AppShortcut(
            id: id,
            appName: appName,
            appPath: appPath,
            keyCode: keyCode,
            modifiers: modifiers,
            shortcutLabel: label
        )
    }
}

@MainActor
final class AppLauncherStore: ObservableObject {
    @Published private(set) var shortcuts: [AppShortcut] = []
    @Published var recordingID: UUID?

    private let defaultsKey = "appShortcuts"

    init() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let savedShortcuts = try? JSONDecoder().decode([AppShortcut].self, from: data) else {
            return
        }
        shortcuts = savedShortcuts
    }

    func addApplication(at path: String) {
        guard !shortcuts.contains(where: { $0.appPath == path }) else { return }
        let appName = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        shortcuts.append(
            AppShortcut(
                id: UUID(),
                appName: appName,
                appPath: path,
                keyCode: nil,
                modifiers: nil,
                shortcutLabel: nil
            )
        )
        save()
    }

    func setShortcut(id: UUID, keyCode: UInt32, modifiers: UInt32, label: String) {
        shortcuts = shortcuts.map {
            guard $0.id == id else { return $0 }
            return $0.settingShortcut(keyCode: keyCode, modifiers: modifiers, label: label)
        }
        recordingID = nil
        save()
    }

    func shortcut(id: UUID) -> AppShortcut? {
        shortcuts.first { $0.id == id }
    }

    func containsShortcut(keyCode: UInt32, modifiers: UInt32, excluding id: UUID) -> Bool {
        shortcuts.contains {
            $0.id != id && $0.keyCode == keyCode && $0.modifiers == modifiers
        }
    }

    func remove(_ shortcut: AppShortcut) {
        shortcuts.removeAll { $0.id == shortcut.id }
        if recordingID == shortcut.id {
            recordingID = nil
        }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(shortcuts) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
