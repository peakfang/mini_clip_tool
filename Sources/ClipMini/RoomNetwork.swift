import AppKit
import CoreLocation
import CoreWLAN

struct DiscoveredPingRoom: Identifiable {
    let id: String
    let name: String
    let code: String
    let address: String
    let count: Int
}

@MainActor
final class RoomNetwork: NSObject, ObservableObject, @preconcurrency NetServiceBrowserDelegate, @preconcurrency NetServiceDelegate, @preconcurrency CLLocationManagerDelegate {
    @Published var rooms: [DiscoveredPingRoom] = []
    @Published var wifi = "Wi-Fi 名称未读取"
    @Published var discoveryStatus = "正在发现局域网房间…"
    private let browser = NetServiceBrowser()
    private let location = CLLocationManager()
    private var services: [String: NetService] = [:]
    private var timer: Timer?
    private var browsing = false

    override init() {
        super.init()
        browser.delegate = self
        location.delegate = self
    }

    func start() {
        refreshWifi()
        guard !browsing else { return }
        browsing = true
        browser.searchForServices(ofType: "_clipmini._tcp.", inDomain: "local.")
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshWifi() }
        }
    }

    func stop() {
        browser.stop()
        browsing = false
        timer?.invalidate()
        timer = nil
        services.values.forEach { $0.stopMonitoring(); $0.stop() }
        services.removeAll()
        rooms.removeAll()
    }

    func refreshWifi(requestPermission: Bool = false) {
        if requestPermission, location.authorizationStatus == .notDetermined {
            location.requestWhenInUseAuthorization()
        }
        let interfaces = CWWiFiClient.shared().interfaces() ?? []
        if let ssid = interfaces.compactMap({ $0.ssid() }).first {
            wifi = "Wi-Fi：\(ssid)"
        } else if location.authorizationStatus == .denied || location.authorizationStatus == .restricted {
            wifi = "Wi-Fi 名称不可用：定位权限未允许"
        } else if location.authorizationStatus == .notDetermined {
            wifi = "Wi-Fi 名称未读取：点击授权读取"
        } else {
            wifi = "Wi-Fi 名称不可用（可能未连接或系统未提供）"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { refreshWifi() }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        guard services.count < 50 else { return }
        services[service.name] = service
        service.delegate = self
        service.resolve(withTimeout: 5)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        services.removeValue(forKey: service.name)?.stopMonitoring()
        rooms.removeAll { $0.id == service.name }
        discoveryStatus = "已发现 \(rooms.count) 个局域网房间"
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        discoveryStatus = "无法发现房间，请检查本地网络权限；仍可粘贴邀请加入"
        browsing = false
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        update(sender)
        sender.startMonitoring()
    }

    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) { update(sender, data: data) }

    private func update(_ service: NetService, data: Data? = nil) {
        guard services[service.name] === service,
              let host = service.hostName, service.port > 0,
              let data = data ?? service.txtRecordData() else { return }
        let record = NetService.dictionary(fromTXTRecord: data)
        guard let version = record["v"], String(data: version, encoding: .utf8) == "2",
              let bytes = record["code"], let code = String(data: bytes, encoding: .utf8), code.count == 8,
              code.allSatisfy({ "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".contains($0) }) else { return }
        let name = record["name"].flatMap { String(data: $0, encoding: .utf8) } ?? "局域网房间"
        let count = record["count"].flatMap { String(data: $0, encoding: .utf8) }.flatMap(Int.init) ?? 0
        let address = "ws://\(host.trimmingCharacters(in: CharacterSet(charactersIn: "."))):\(service.port)"
        rooms.removeAll { $0.id == service.name }
        rooms.append(DiscoveredPingRoom(id: service.name, name: String(name.prefix(20)), code: code, address: address, count: min(10, max(0, count))))
        rooms.sort { $0.name < $1.name }
        discoveryStatus = "已发现 \(rooms.count) 个局域网房间"
    }
}
