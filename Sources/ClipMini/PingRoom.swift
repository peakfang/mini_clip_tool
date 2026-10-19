import AppKit
import SwiftUI

struct PingRoomMember: Decodable, Identifiable {
    let id: String
    let name: String
    var steelCount: Int? = nil
}

struct PingPosition: Codable, Equatable {
    let x: Double
    let y: Double

    var isValid: Bool { x.isFinite && y.isFinite && (0...1).contains(x) && (0...1).contains(y) }

    init(point: NSPoint, screen: NSRect) {
        x = min(1, max(0, (point.x - screen.minX) / screen.width))
        y = min(1, max(0, (screen.maxY - point.y) / screen.height))
    }

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    func point(in screen: NSRect) -> NSPoint {
        NSPoint(x: screen.minX + x * screen.width, y: screen.maxY - y * screen.height)
    }
}

private struct PingRoomPacket: Decodable {
    let type: String
    var room: String?
    var selfID: String?
    var members: [PingRoomMember]?
    var id: String?
    var index: Int?
    var name: String?
    var message: String?
    var position: PingPosition?
    var steelCount: Int?
}

@MainActor
final class PingRoom: ObservableObject {
    @Published var server = UserDefaults.standard.string(forKey: "pingRoomServer") ?? ""
    @Published var nickname = UserDefaults.standard.string(forKey: "pingRoomNickname") ?? ""
    @Published var code = ""
    @Published var members: [PingRoomMember] = []
    @Published var status = "未连接"
    @Published var connecting = false
    @Published var joined = false
    @Published var hosting = false
    private var lanRelay: LANPingRelay?
    @Published var paused = UserDefaults.standard.object(forKey: "pingRoomPaused") as? Bool ?? false {
        didSet { UserDefaults.standard.set(paused, forKey: "pingRoomPaused") }
    }
    var onPing: ((Int, String, PingPosition, Int) -> Void)?
    private var socket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var receiver: Task<Void, Never>?
    private var generation = UUID()
    private var selfID: String?
    var onOwnSteelCount: ((Int) -> Void)?
    private var sequence = 0
    private var lastSend = -Double.infinity
    private var seen: [String] = []
    private var window: NSWindow?
    let network = RoomNetwork()

    func show() {
        network.start()
        if window == nil {
            let view = PingRoomView(room: self)
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 680), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "桌面信号联机"
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: view)
            self.window = window
        }
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func hostLAN() {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 20 else { status = "请先填写 1～20 字的昵称"; return }
        leave()
        let relay = LANPingRelay()
        lanRelay = relay
        connecting = true
        hosting = true
        status = "正在创建局域网房间…"
        relay.onReady = { [weak self, weak relay] address in
            guard let self, self.lanRelay === relay else { return }
            self.server = address
            self.connect(create: true, keepHost: true)
        }
        relay.onFailure = { [weak self, weak relay] message in
            guard let self, self.lanRelay === relay else { return }
            self.leave()
            self.status = message
        }
        relay.start(name: name)
    }

    func connect(create: Bool, keepHost: Bool = false) {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 20 else { status = "请填写 1～20 字的昵称"; return }
        guard let url = URL(string: server.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = url.host, ["ws", "wss"].contains(url.scheme), url.user == nil, url.password == nil else {
            status = "请填写中转服务地址，例如 wss://你的域名"
            return
        }
        let localHost = host == "localhost" || host == "127.0.0.1" || host == "::1" || host.hasSuffix(".local") || host.hasPrefix("192.168.") || host.hasPrefix("10.") || (16...31).contains(Int(host.split(separator: ".").dropFirst().first ?? "") ?? -1) && host.hasPrefix("172.")
        guard url.scheme == "wss" || localHost else { status = "公网服务请使用 wss:// 安全连接"; return }
        let requestedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard create || (requestedCode.count == 8 && requestedCode.allSatisfy { "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".contains($0) }) else {
            status = "请输入 8 位房间码"
            return
        }
        leave(keepHost: keepHost)
        UserDefaults.standard.set(url.absoluteString, forKey: "pingRoomServer")
        UserDefaults.standard.set(name, forKey: "pingRoomNickname")
        connecting = true
        status = "正在连接…"
        let token = generation
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 86400
        let session = URLSession(configuration: config)
        self.session = session
        let socket = session.webSocketTask(with: url)
        socket.maximumMessageSize = 4096
        self.socket = socket
        socket.resume()
        receiver = Task { [weak self] in
            do {
                let request: [String: Any] = ["type": create ? "create" : "join", "version": 2, "name": name, "room": requestedCode]
                let data = try JSONSerialization.data(withJSONObject: request)
                try await socket.send(.data(data))
                while !Task.isCancelled {
                    let message = try await socket.receive()
                    guard let self, self.generation == token else { return }
                    let data: Data
                    switch message {
                    case .data(let bytes): data = bytes
                    case .string(let text): data = Data(text.utf8)
                    @unknown default: continue
                    }
                    let packet = try JSONDecoder().decode(PingRoomPacket.self, from: data)
                    switch packet.type {
                    case "joined":
                        guard let code = packet.room, code.count == 8 else { throw URLError(.cannotParseResponse) }
                        self.code = code
                        self.selfID = packet.selfID
                        self.onOwnSteelCount?(0)
                        self.joined = true
                        self.connecting = false
                        self.status = "已加入房间"
                    case "members":
                        self.members = Array((packet.members ?? []).prefix(10))
                        self.onOwnSteelCount?(self.members.first(where: { $0.id == self.selfID })?.steelCount ?? 0)
                    case "ping":
                        guard self.joined, let index = packet.index, (0..<9).contains(index),
                              let id = packet.id, !self.seen.contains(id), let sender = packet.name,
                              let position = packet.position, position.isValid else { continue }
                        self.seen.append(id)
                        if self.seen.count > 64 { self.seen.removeFirst() }
                        if !self.paused { self.onPing?(index, String(sender.prefix(20)), position, max(0, packet.steelCount ?? 0)) }
                    case "error":
                        let detail = String((packet.message ?? "联机请求失败").prefix(100))
                        if !self.joined { self.leave() }
                        self.status = detail
                    default: continue
                    }
                }
            } catch {
                guard let self, self.generation == token, !Task.isCancelled else { return }
                self.leave()
                self.status = "连接已断开，请重新加入。\(error.localizedDescription)"
            }
        }
    }

    func send(_ index: Int, position: PingPosition) {
        guard joined, (0..<9).contains(index), position.isValid, let socket else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastSend >= 0.5 else { status = "发送太快，本次仅在本机显示"; return }
        lastSend = now
        sequence += 1
        let seq = sequence
        let token = generation
        Task { [weak self] in
            do {
                let data = try JSONSerialization.data(withJSONObject: ["type": "ping", "index": index, "seq": seq, "position": ["x": position.x, "y": position.y]])
                try await socket.send(.data(data))
                if let self, self.generation == token { self.status = "已发送信号" }
            } catch {
                guard let self, self.generation == token else { return }
                self.leave()
                self.status = "信号发送失败，请重新加入"
            }
        }
    }

    func leave(keepHost: Bool = false) {
        if !keepHost {
            lanRelay?.stop()
            lanRelay = nil
            hosting = false
        }
        generation = UUID()
        receiver?.cancel()
        receiver = nil
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
        session?.invalidateAndCancel()
        session = nil
        joined = false
        connecting = false
        members = []
        seen = []
        sequence = 0
        selfID = nil
        onOwnSteelCount?(0)
        lastSend = -Double.infinity
        status = "未连接"
    }
}

struct PingRoomView: View {
    @ObservedObject var room: PingRoom
    @ObservedObject var network: RoomNetwork

    init(room: PingRoom) {
        self.room = room
        network = room.network
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("和朋友互发桌面信号").font(.title2.bold())
                HStack {
                    Text(network.wifi).font(.callout).textSelection(.enabled)
                    Spacer()
                    Button("读取 Wi-Fi") { network.refreshWifi(requestPermission: true) }
                }
                TextField("联机地址（也可直接选择下方房间）", text: $room.server).disabled(room.joined || room.connecting)
                TextField("你的昵称", text: $room.nickname).disabled(room.joined || room.connecting)
                HStack {
                    TextField("8 位房间码", text: $room.code).disabled(room.joined || room.connecting)
                    if room.joined {
                        Button("复制邀请") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString("ClipMini 联机地址：\(room.server)\n房间码：\(room.code)", forType: .string)
                        }
                    } else if !room.connecting {
                        Button("粘贴邀请") {
                            let lines = NSPasteboard.general.string(forType: .string)?.components(separatedBy: .newlines) ?? []
                            if let address = lines.first(where: { $0.hasPrefix("ClipMini 联机地址：") }),
                               let code = lines.first(where: { $0.hasPrefix("房间码：") }) {
                                room.server = String(address.dropFirst("ClipMini 联机地址：".count))
                                room.code = String(code.dropFirst("房间码：".count))
                            } else { room.status = "请先复制朋友发送的完整邀请" }
                        }
                    }
                }
                HStack {
                    if room.joined || room.connecting {
                        Button(room.connecting ? "取消连接" : "退出房间") { room.leave() }
                    } else {
                        Button("创建局域网房间") { room.hostLAN() }
                        Button("加入房间") { room.connect(create: false) }
                    }
                    if room.connecting { ProgressView().controlSize(.small) }
                }
                Divider()
                HStack {
                    Text("可发现的局域网房间").font(.headline)
                    Spacer()
                    Button("刷新") { network.stop(); network.start() }
                }
                if network.rooms.isEmpty { Text("暂未发现房间，请让朋友先创建房间。").foregroundStyle(.secondary) }
                ForEach(network.rooms) { found in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(found.name)的房间 · \(found.count)/10 人")
                            Text(found.code).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("加入") {
                            room.server = found.address
                            room.code = found.code
                            room.connect(create: false)
                        }.disabled(room.joined || room.connecting || found.count >= 10)
                    }.padding(.vertical, 4)
                }
                Text(network.discoveryStatus).font(.caption).foregroundStyle(.secondary)
                Text(room.status).foregroundStyle(.secondary).textSelection(.enabled)
                if room.hosting { Text("你是房主，退出房间或关闭 ClipMini 后房间关闭。").font(.caption).foregroundStyle(.secondary) }
                if room.joined {
                    Divider()
                    Text("房间成员（\(room.members.count)/10）").font(.headline)
                    ForEach(room.members) { member in
                        HStack {
                            Text(member.name)
                            Spacer()
                            Text("叠钢 \(member.steelCount ?? 0) 次").foregroundStyle(.secondary)
                        }
                    }
                    Toggle("暂停接收朋友的信号", isOn: $room.paused)
                }
                Divider()
                Text("标记可同时显示，按屏幕比例同步。叠钢次数按本次入房后的成功发送统计，重新加入清零。无需账号密码，只需昵称。截图、剪贴板和 AI 留在本机。")
                    .font(.caption).foregroundStyle(.secondary)
                Text("房间发现覆盖可互通的局域网，不保证严格等同于同一 Wi-Fi 名称；访客网络或客户端隔离可能阻止发现。")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
        }.frame(width: 560, height: 680).background(Color(nsColor: .windowBackgroundColor))
    }
}
