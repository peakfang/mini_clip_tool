import AppKit
import ApplicationServices
import Carbon.HIToolbox
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let desktopPing = DesktopPing()
    private let pingRoom = PingRoom()
    private let store = ClipboardStore()
    private let hotKeyManager = HotKeyManager()
    private let pickerState = HistoryPickerState()
    private var statusItem: NSStatusItem?
    private var panel: NSPanel?
    private var previousApplication: NSRunningApplication?
    private weak var bottomPlacementMenuItem: NSMenuItem?
    private weak var menuPlacementMenuItem: NSMenuItem?

    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        desktopPing.start()
        desktopPing.onSend = { [weak self] index, position in self?.pingRoom.send(index, position: position) }
        pingRoom.onOwnSteelCount = { [weak self] count in self?.desktopPing.steelCount = count }
        pingRoom.onPing = { [weak self] index, sender, position, count in self?.desktopPing.receive(index, sender: sender, position: position, steelCount: count) }

        hotKeyManager.onClipboardPressed = { [weak self] in
            self?.showHistory()
        }
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let image = NSImage(systemSymbolName: "questionmark", accessibilityDescription: "ClipMini")?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 17, weight: .bold))
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = "ClipMini · 桌面信号与联机"

        let menu = NSMenu()
        menu.addItem(withTitle: "联机房间…", action: #selector(showPingRoom), keyEquivalent: "")
        let pingItem = menu.addItem(withTitle: "启用桌面信号（按住 ⌃⌥）", action: #selector(toggleDesktopPing(_:)), keyEquivalent: "")
        pingItem.state = desktopPing.enabled ? .on : .off
        let muteItem = menu.addItem(withTitle: "信号静音", action: #selector(togglePingMute(_:)), keyEquivalent: "")
        muteItem.state = UserDefaults.standard.bool(forKey: "desktopPingMuted") ? .on : .off
        menu.addItem(withTitle: "试听信号音效", action: #selector(testPingSound), keyEquivalent: "")
        menu.addItem(withTitle: "授权／重试桌面信号", action: #selector(authorizeDesktopPing), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        let launchAtLoginItem = menu.addItem(withTitle: "登录时启动", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(NSMenuItem.separator())

        let clipboardItem = NSMenuItem(title: "剪贴板", action: nil, keyEquivalent: "")
        let clipboardMenu = NSMenu()
        clipboardMenu.addItem(withTitle: "查看剪贴板历史（⌃X）", action: #selector(showHistory), keyEquivalent: "")
        let placementItem = NSMenuItem(title: "面板位置", action: nil, keyEquivalent: "")
        let placementMenu = NSMenu()
        let bottomItem = placementMenu.addItem(withTitle: "底部", action: #selector(setBottomPlacement), keyEquivalent: "")
        let menuItem = placementMenu.addItem(withTitle: "菜单栏下方", action: #selector(setMenuPlacement), keyEquivalent: "")
        bottomItem.target = self
        menuItem.target = self
        placementItem.submenu = placementMenu
        clipboardMenu.addItem(placementItem)
        bottomPlacementMenuItem = bottomItem
        menuPlacementMenuItem = menuItem
        updatePlacementMenuState()
        clipboardMenu.addItem(NSMenuItem.separator())
        clipboardMenu.addItem(withTitle: "清空历史", action: #selector(clearHistory), keyEquivalent: "")
        clipboardMenu.items.forEach { $0.target = self }
        clipboardItem.submenu = clipboardMenu
        menu.addItem(clipboardItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "退出 ClipMini", action: #selector(quit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu

        self.statusItem = statusItem
    }

    @objc private func showHistory() {
        store.captureCurrentClipboard()

        if NSWorkspace.shared.frontmostApplication?.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            previousApplication = NSWorkspace.shared.frontmostApplication
        }

        if panel == nil {
            let historyView = HistoryView(
                store: store,
                pickerState: pickerState,
                onPick: { [weak self] item in
                    self?.select(item)
                },
                onClear: { [weak self] in
                    self?.store.clear()
                }
            )

            let panel = HistoryPanel(
                contentRect: NSRect(x: 0, y: 0, width: 900, height: 310),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.hidesOnDeactivate = false
            panel.onPrevious = { [weak self] in
                guard let self else { return }
                pickerState.moveSelection(by: -1, in: store.items)
            }
            panel.onNext = { [weak self] in
                guard let self else { return }
                pickerState.moveSelection(by: 1, in: store.items)
            }
            panel.onConfirm = { [weak self] in
                guard let self,
                      let item = pickerState.selectedItem(in: store.items) else { return }
                select(item)
            }
            panel.contentViewController = NSHostingController(rootView: historyView)
            self.panel = panel
        }

        pickerState.reset(with: store.items)
        positionPanel()
        panel?.orderFrontRegardless()
        panel?.makeKeyAndOrderFront(nil)
    }

    private func positionPanel() {
        guard let panel else { return }
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }
        let inset: CGFloat = 16
        let frame: NSRect
        switch pickerState.placement {
        case .bottom:
            frame = NSRect(
                x: screen?.frame.minX ?? visibleFrame.minX,
                y: screen?.frame.minY ?? visibleFrame.minY,
                width: screen?.frame.width ?? visibleFrame.width,
                height: 270
            )
        case .menu:
            let size = NSSize(width: 420, height: 400)
            if let button = statusItem?.button,
               let window = button.window {
                let buttonFrame = window.convertToScreen(button.convert(button.bounds, to: nil))
                let x = min(
                    max(buttonFrame.midX - size.width / 2, visibleFrame.minX + inset),
                    visibleFrame.maxX - size.width - inset
                )
                frame = NSRect(x: x, y: buttonFrame.minY - size.height - 6, width: size.width, height: size.height)
            } else {
                frame = NSRect(
                    x: visibleFrame.midX - size.width / 2,
                    y: visibleFrame.maxY - size.height,
                    width: size.width,
                    height: size.height
                )
            }
        }
        panel.setFrame(frame, display: true)
    }

    private func select(_ item: ClipboardItem) {
        let canAutoPaste = requestAccessibilityPermissionIfNeeded()
        store.restore(item)
        panel?.orderOut(nil)
        guard let previousApplication else { return }
        let processIdentifier = previousApplication.processIdentifier
        previousApplication.activate(options: [.activateIgnoringOtherApps])

        guard canAutoPaste else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            sendPasteShortcut(to: processIdentifier)
        }
    }

    private func requestAccessibilityPermissionIfNeeded() -> Bool {
        if AXIsProcessTrusted() {
            return true
        }
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func sendPasteShortcut(to processIdentifier: pid_t) {
        guard let keyDown = CGEvent(
            keyboardEventSource: nil,
            virtualKey: CGKeyCode(kVK_ANSI_V),
            keyDown: true
        ), let keyUp = CGEvent(
            keyboardEventSource: nil,
            virtualKey: CGKeyCode(kVK_ANSI_V),
            keyDown: false
        ) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.postToPid(processIdentifier)
        keyUp.postToPid(processIdentifier)
    }

    @objc private func clearHistory() {
        store.clear()
    }

    @objc private func setBottomPlacement() {
        pickerState.setPlacement(.bottom)
        updatePlacementMenuState()
        positionPanel()
    }

    @objc private func setMenuPlacement() {
        pickerState.setPlacement(.menu)
        updatePlacementMenuState()
        positionPanel()
    }

    private func updatePlacementMenuState() {
        bottomPlacementMenuItem?.state = pickerState.placement == .bottom ? .on : .off
        menuPlacementMenuItem?.state = pickerState.placement == .menu ? .on : .off
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                sender.state = .off
            } else {
                try SMAppService.mainApp.register()
                sender.state = .on
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "无法修改登录启动设置"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    @objc private func toggleDesktopPing(_ sender: NSMenuItem) {
        desktopPing.toggle(sender)
    }

    @objc private func showPingRoom() {
        pingRoom.show()
    }

    @objc private func testPingSound() {
        desktopPing.testSound()
    }

    @objc private func authorizeDesktopPing() {
        desktopPing.start(prompt: true)
    }

    @objc private func togglePingMute(_ sender: NSMenuItem) {
        let muted = !UserDefaults.standard.bool(forKey: "desktopPingMuted")
        UserDefaults.standard.set(muted, forKey: "desktopPingMuted")
        sender.state = muted ? .on : .off
    }

    @objc private func quit() {
        pingRoom.leave()
        pingRoom.network.stop()
        desktopPing.stop()
        NSApp.terminate(nil)
    }
}

@MainActor
private final class HistoryPanel: NSPanel {
    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?
    var onConfirm: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        orderOut(nil)
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            switch event.keyCode {
            case 123, 126:
                onPrevious?()
                return
            case 124, 125:
                onNext?()
                return
            case 36, 76:
                onConfirm?()
                return
            case 53:
                orderOut(nil)
                return
            default:
                break
            }
        }
        super.sendEvent(event)
    }
}

@MainActor
private final class ShortcutSettingsWindow: NSWindow {
    var onKeyDown: ((NSEvent) -> Bool)?

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, onKeyDown?(event) == true {
            return
        }
        super.sendEvent(event)
    }
}
