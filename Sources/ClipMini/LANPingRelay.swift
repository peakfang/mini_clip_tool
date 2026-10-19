import Foundation
import Network
import Darwin

@MainActor
final class LANPingRelay {
    private var listener: NWListener?
    private var connections: [UUID: NWConnection] = [:]
    private var members: [UUID: [String: Any]] = [:]
    private var advertisement: NetService?
    private var hostName = "房间"
    private var sequence: [UUID: Int] = [:]
    private var recent: [UUID: [TimeInterval]] = [:]
    private var roomCode = ""
    private var timeout: DispatchWorkItem?
    var onReady: ((String) -> Void)?
    var onFailure: ((String) -> Void)?

    func start(name: String = "房间") {
        stop()
        hostName = String(name.prefix(20))
        do {
            let websocket = NWProtocolWebSocket.Options()
            websocket.autoReplyPing = true
            websocket.maximumMessageSize = 2048
            let parameters = NWParameters.tcp
            parameters.defaultProtocolStack.applicationProtocols.insert(websocket, at: 0)
            let listener = try NWListener(using: parameters, on: .any)
            self.listener = listener
            let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
            roomCode = String((0..<8).map { _ in alphabet.randomElement()! })
            listener.stateUpdateHandler = { [weak self] state in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    switch state {
                    case .ready:
                        guard let port = listener.port else { return }
                        guard let address = Self.localAddress() else {
                            self.onFailure?("未找到局域网地址，请连接 Wi-Fi 后重试")
                            self.stop()
                            return
                        }
                        let service = NetService(domain: "local.", type: "_clipmini._tcp.", name: "ClipMini-\(self.roomCode)", port: Int32(port.rawValue))
                        self.advertisement = service
                        self.broadcastMembers()
                        service.publish()
                        self.onReady?("ws://\(address):\(port.rawValue)")
                    case .failed(let error):
                        self.onFailure?("局域网中转启动失败：\(error.localizedDescription)")
                        self.stop()
                    default: break
                    }
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                MainActor.assumeIsolated {
                    guard let self, self.connections.count < 20 else { connection.cancel(); return }
                    let id = UUID()
                    self.connections[id] = connection
                    connection.stateUpdateHandler = { [weak self] state in
                        MainActor.assumeIsolated {
                            if case .failed = state { self?.remove(id) }
                            if case .cancelled = state { self?.remove(id) }
                        }
                    }
                    connection.start(queue: .main)
                    self.receive(id)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                        guard let self, self.members[id] == nil else { return }
                        self.connections[id]?.cancel()
                    }
                }
            }
            listener.start(queue: .main)
            let expiry = DispatchWorkItem { [weak self] in self?.stop(); self?.onFailure?("局域网房间已到 24 小时，请重新创建") }
            timeout = expiry
            DispatchQueue.main.asyncAfter(deadline: .now() + 86400, execute: expiry)
        } catch { onFailure?("无法创建局域网房间：\(error.localizedDescription)") }
    }

    func stop() {
        advertisement?.stop()
        advertisement = nil
        timeout?.cancel()
        timeout = nil
        listener?.stateUpdateHandler = nil
        listener?.cancel()
        listener = nil
        let sockets = Array(connections.values)
        connections.removeAll()
        members.removeAll()
        sequence.removeAll()
        recent.removeAll()
        for connection in sockets {
            connection.stateUpdateHandler = nil
            connection.cancel()
        }
    }

    private func receive(_ id: UUID) {
        connections[id]?.receiveMessage { [weak self] data, context, _, error in
            MainActor.assumeIsolated {
                guard let self, let connection = self.connections[id] else { return }
                if error != nil { self.remove(id); return }
                if let metadata = context?.protocolMetadata(definition: NWProtocolWebSocket.definition) as? NWProtocolWebSocket.Metadata {
                    if metadata.opcode == .close { self.remove(id); return }
                    if metadata.opcode == .ping || metadata.opcode == .pong { self.receive(id); return }
                }
                if let data {
                    guard data.count <= 2048,
                          let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        self.reject(id, "消息格式不正确", close: true)
                        return
                    }
                    if self.members[id] == nil {
                        guard message["version"] as? Int == 2,
                              let name = message["name"] as? String, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                              name.count <= 20, !name.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains),
                              let action = message["type"] as? String, action == "create" || action == "join" else {
                            self.reject(id, "昵称不正确或版本不兼容，请双方更新到 1.45 或以上", close: true); return
                        }
                        if action == "create", !self.members.isEmpty {
                            self.reject(id, "房间已创建，请使用房间码加入", close: true); return
                        }
                        if action == "join", message["room"] as? String != self.roomCode {
                            self.reject(id, "房间码不正确", close: true); return
                        }
                        guard self.members.count < 10 else { self.reject(id, "房间已满（最多 10 人）", close: true); return }
                        self.members[id] = ["id": id.uuidString, "name": name.trimmingCharacters(in: .whitespacesAndNewlines), "steelCount": 0]
                        self.send(connection, ["type": "joined", "room": self.roomCode, "selfID": id.uuidString])
                        self.broadcastMembers()
                    } else {
                        guard message["type"] as? String == "ping",
                              let number = message["index"] as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
                              number.doubleValue == Double(number.intValue), (0..<9).contains(number.intValue),
                              let position = message["position"] as? [String: Any],
                              let x = position["x"] as? NSNumber, let y = position["y"] as? NSNumber,
                              CFGetTypeID(x) != CFBooleanGetTypeID(), CFGetTypeID(y) != CFBooleanGetTypeID(),
                              x.doubleValue.isFinite, y.doubleValue.isFinite,
                              (0...1).contains(x.doubleValue), (0...1).contains(y.doubleValue),
                              let seq = message["seq"] as? NSNumber, CFGetTypeID(seq) != CFBooleanGetTypeID(),
                              seq.doubleValue == Double(seq.intValue), seq.intValue > (self.sequence[id] ?? 0) else {
                            self.reject(id, "信号无效或重复", close: false)
                            self.receive(id)
                            return
                        }
                        self.sequence[id] = seq.intValue
                        let now = ProcessInfo.processInfo.systemUptime
                        let times = (self.recent[id] ?? []).filter { now - $0 < 1 }
                        guard times.count < 2 else {
                            self.reject(id, "发送太快，请稍后再试", close: false)
                            self.receive(id)
                            return
                        }
                        self.recent[id] = times + [now]
                        if number.intValue == 8 {
                            let count = (self.members[id]?["steelCount"] as? Int ?? 0) + 1
                            self.members[id]?["steelCount"] = count
                            self.broadcastMembers()
                        }
                        let packet: [String: Any] = ["type": "ping", "id": UUID().uuidString, "index": number.intValue, "name": self.members[id]!["name"]!, "sender": id.uuidString, "position": ["x": x.doubleValue, "y": y.doubleValue], "steelCount": self.members[id]?["steelCount"] as? Int ?? 0]
                        for peer in self.members.keys where peer != id {
                            if let socket = self.connections[peer] { self.send(socket, packet) }
                        }
                    }
                }
                if connection.state != .cancelled { self.receive(id) }
            }
        }
    }

    private func send(_ connection: NWConnection, _ packet: [String: Any], completion: (@MainActor @Sendable () -> Void)? = nil) {
        guard let data = try? JSONSerialization.data(withJSONObject: packet) else { return }
        let context = NWConnection.ContentContext(identifier: UUID().uuidString, metadata: [NWProtocolWebSocket.Metadata(opcode: .text)])
        connection.send(content: data, contentContext: context, isComplete: true, completion: .contentProcessed { _ in
            if let completion { DispatchQueue.main.async { completion() } }
        })
    }

    private func reject(_ id: UUID, _ message: String, close: Bool) {
        guard let connection = connections[id] else { return }
        send(connection, ["type": "error", "message": message]) { [weak self] in
            if close { self?.remove(id) }
        }
    }

    private func broadcastMembers() {
        let record = ["v": Data("2".utf8), "code": Data(roomCode.utf8), "name": Data(hostName.utf8), "count": Data(String(members.count).utf8)]
        advertisement?.setTXTRecord(NetService.data(fromTXTRecord: record))
        let packet: [String: Any] = ["type": "members", "members": Array(members.values)]
        for id in members.keys {
            if let connection = connections[id] { send(connection, packet) }
        }
    }

    private func remove(_ id: UUID) {
        guard let connection = connections.removeValue(forKey: id) else { return }
        connection.stateUpdateHandler = nil
        connection.cancel()
        if members.removeValue(forKey: id) != nil { broadcastMembers() }
        sequence[id] = nil
        recent[id] = nil
    }

    private static func localAddress() -> String? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0 else { return nil }
        defer { freeifaddrs(interfaces) }
        var current = interfaces
        var addresses: [(String, String)] = []
        while let item = current {
            defer { current = item.pointee.ifa_next }
            guard let address = item.pointee.ifa_addr, address.pointee.sa_family == UInt8(AF_INET),
                  item.pointee.ifa_flags & UInt32(IFF_UP) != 0, item.pointee.ifa_flags & UInt32(IFF_LOOPBACK) == 0 else { continue }
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(address, socklen_t(address.pointee.sa_len), &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST) == 0 {
                let name = String(cString: item.pointee.ifa_name)
                if name.hasPrefix("en") { addresses.append((name, String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self))) }
            }
        }
        return addresses.sorted { $0.0 < $1.0 }.first?.1
    }
}
