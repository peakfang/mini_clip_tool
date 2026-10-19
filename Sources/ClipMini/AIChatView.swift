import SwiftUI

struct AIChatView: View {
    @ObservedObject var store: AIChatStore
    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    @State private var key = ""
    @State private var settingsVisible = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("AI 对话 · DeepSeek").font(.title2.weight(.semibold))
                Spacer()
                Button("新对话") { store.clear() }.disabled(store.sending || store.messages.isEmpty)
                Button("AI 设置") { settingsVisible.toggle() }
                Button("关闭") { store.stop(); key = ""; dismiss() }.keyboardShortcut(.cancelAction)
            }
            if settingsVisible || !store.hasKey {
                VStack(alignment: .leading, spacing: 10) {
                    SecureField(store.hasKey ? "输入新 Key 替换现有 Key" : "DeepSeek API Key", text: $key)
                    HStack {
                        Button("保存 Key") { store.saveKey(key); key = "" }.disabled(key.isEmpty || store.sending)
                        Button("移除 Key") { store.removeKey() }.disabled(!store.hasKey || store.sending)
                        Spacer()
                        Link("获取 Key", destination: URL(string: "https://platform.deepseek.com/api_keys")!)
                    }
                    Picker("模型", selection: $store.model) {
                        Text("DeepSeek Flash").tag("deepseek-flash")
                        Text("DeepSeek V4 Pro").tag("deepseek-v4-pro")
                    }.disabled(store.sending)
                    Text("Key 仅存本机钥匙串。发送会把当前会话交给 DeepSeek，按其 API 规则计费；不会自动读取工作台、文件或剪贴板。")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(14).background(Color.blue.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if store.messages.isEmpty {
                            Text("有什么想聊的？\n聊天仅在本次运行中保留，不保存到磁盘。")
                                .foregroundStyle(.secondary).padding(.vertical, 30)
                        }
                        ForEach(store.messages) { message in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(message.role == "user" ? "你" : "DeepSeek").font(.caption).foregroundStyle(.secondary)
                                Text(message.content).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                            }.padding(14).background(message.role == "user" ? Color.blue.opacity(0.07) : Color.secondary.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12)).id(message.id)
                        }
                    }
                }.onChange(of: store.messages.count) { _ in
                    if let id = store.messages.last?.id { proxy.scrollTo(id, anchor: .bottom) }
                }
            }
            if store.sending { HStack { ProgressView().controlSize(.small); Text("正在回复…"); Spacer(); Button("停止") { store.stop() } } }
            if !store.status.isEmpty { Text(store.status).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading) }
            HStack(alignment: .bottom) {
                TextEditor(text: $input).disabled(store.sending).frame(height: 70).padding(6).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                Button("发送") { store.send(input) }.keyboardShortcut(.return, modifiers: [.command])
                    .disabled(store.sending || !store.hasKey || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Text("⌘ Enter 发送 · 重试可能产生额外费用 · 不要发送敏感信息")
                .font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
        }.padding(24).frame(width: 700, height: 680)
        .onChange(of: store.messages.count) { _ in input = "" }
        .onDisappear { store.stop(); key = "" }
    }
}
