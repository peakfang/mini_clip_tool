import AppKit
import SwiftUI

struct LauncherSettingsView: View {
    @ObservedObject var store: AppLauncherStore
    let onAdd: () -> Void
    let onRecord: (UUID) -> Void
    let onRemove: (AppShortcut) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("快捷启动应用")
                        .font(.headline)
                    Text("快捷键只保存在本机，Control+X 固定用于剪贴板")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("添加应用", action: onAdd)
            }
            .padding(16)

            Divider()

            if store.shortcuts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)
                    Text("还没有快捷启动应用")
                        .font(.headline)
                    Text("添加应用后，为它按下一个带修饰键的快捷键")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.shortcuts) { shortcut in
                            HStack(spacing: 12) {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: shortcut.appPath))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(shortcut.appName)
                                    Text(shortcut.appPath)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Button {
                                    onRecord(shortcut.id)
                                } label: {
                                    Text(store.recordingID == shortcut.id ? "请按快捷键…" : shortcut.shortcutLabel ?? "设置快捷键")
                                        .frame(minWidth: 92)
                                }

                                Button {
                                    onRemove(shortcut)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(10)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                        }
                    }
                    .padding(12)
                }
            }
        }
        .frame(minWidth: 520, minHeight: 360)
    }
}
