import Foundation
import Combine
import Security

struct AIChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let content: String
}

@MainActor
final class AIChatStore: ObservableObject {
    @Published private(set) var messages: [AIChatMessage] = []
    @Published private(set) var sending = false
    @Published var status = ""
    @Published private(set) var hasKey = false
    @Published var model = "deepseek-flash" {
        didSet { UserDefaults.standard.set(model, forKey: "workbench.ai.model") }
    }
    private var task: Task<Void, Never>?
    private let session: URLSession
    private let keyQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "local.clipmini.deepseek",
        kSecAttrAccount as String: "api-key"
    ]

    init(session: URLSession = URLSession(configuration: .ephemeral)) {
        self.session = session
        let saved = UserDefaults.standard.string(forKey: "workbench.ai.model") ?? "deepseek-flash"
        model = ["deepseek-flash", "deepseek-v4-pro"].contains(saved) ? saved : "deepseek-flash"
        hasKey = readKey() != nil
    }

    private func readKey() -> String? {
        var query = keyQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveKey(_ input: String) {
        let key = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !key.contains(where: { $0.isWhitespace }) else { status = "请输入有效的 API Key"; return }
        let data = Data(key.utf8)
        var result = SecItemUpdate(keyQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if result == errSecItemNotFound {
            var query = keyQuery
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            query[kSecAttrSynchronizable as String] = false
            result = SecItemAdd(query as CFDictionary, nil)
        }
        hasKey = readKey() != nil
        status = result == errSecSuccess ? "Key 已保存到本机钥匙串" : "钥匙串保存失败，请检查系统授权"
    }

    func removeKey() {
        let result = SecItemDelete(keyQuery as CFDictionary)
        if result == errSecSuccess || result == errSecItemNotFound {
            hasKey = false
            status = "Key 已移除"
        } else { status = "钥匙串移除失败" }
    }

    func send(_ text: String) {
        let content = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sending, !content.isEmpty else { return }
        guard let key = readKey() else { hasKey = false; status = "请先在 AI 设置中保存 DeepSeek API Key"; return }
        sending = true
        status = ""
        let history = messages + [AIChatMessage(role: "user", content: content)]
        task = Task { [weak self] in
            guard let self else { return }
            defer { sending = false; task = nil }
            do {
                let request = try Self.request(key: key, model: model, messages: history)
                let (data, response) = try await session.data(for: request)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse else { status = "服务响应无效"; return }
                guard http.statusCode == 200 else {
                    switch http.statusCode {
                    case 401: status = "Key 无效或已失效，请重新配置"
                    case 402: status = "DeepSeek 账户余额不足"
                    case 429: status = "请求过于频繁，请稍后再试"
                    case 400, 422: status = "请求被拒绝，请检查模型或缩短会话"
                    default: status = "DeepSeek 服务暂不可用（\(http.statusCode)）"
                    }
                    return
                }
                let reply = try Self.reply(data)
                messages = history + [AIChatMessage(role: "assistant", content: reply)]
            } catch is CancellationError { status = "已停止，本次消息未加入会话" }
            catch let error as URLError {
                status = error.code == .cancelled ? "已停止" : (error.code == .timedOut ? "请求超时，请重试" : "网络连接失败，请检查网络")
            } catch { status = "回复解析失败，请重试" }
        }
    }

    func stop() { task?.cancel() }

    func clear() {
        guard !sending else { return }
        messages = []
        status = ""
    }

    static func request(key: String, model: String, messages: [AIChatMessage]) throws -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.deepseek.com/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model, "stream": false, "thinking": ["type": "disabled"],
            "messages": messages.map { ["role": $0.role, "content": $0.content] }
        ])
        return request
    }

    static func reply(_ data: Data) throws -> String {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let text = message["content"] as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CocoaError(.coderReadCorrupt)
        }
        return text
    }
}
