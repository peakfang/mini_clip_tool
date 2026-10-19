import AppKit
import Combine
import Foundation

struct WorkbenchTask: Codable, Identifiable {
    var id = UUID()
    var title: String
    var completed = false
    var day: String
}

struct QuotaWindow: Identifiable {
    let id: String
    let title: String
    let remaining: Double
    let reset: Date?
}

struct PlanetPosition: Identifiable {
    let id: String
    let azimuth: Double
    let altitude: Double
}

@MainActor
final class WorkbenchStore: ObservableObject {
    @Published var name = "Flipos" { didSet { save() } }
    @Published var motto = "把今天过好，一次做好一件事。" { didSet { save() } }
    @Published var note = "" { didSet { save() } }
    @Published var zodiac = "" { didSet { UserDefaults.standard.set(zodiac, forKey: "workbench.zodiac") } }
    @Published var avatar = "buu" { didSet { UserDefaults.standard.set(avatar, forKey: "workbench.avatar") } }
    @Published var tasks: [WorkbenchTask] = [] { didSet { save() } }
    @Published var folders: [String] = [] { didSet { save() } }
    @Published var city = "" { didSet { save() } }
    @Published var latitude = "" { didSet { save() } }
    @Published var longitude = "" { didSet { save() } }
    @Published private(set) var quotas: [QuotaWindow] = []
    @Published private(set) var quotaStatus = "正在连接 Codex…"
    @Published private(set) var quotaUpdatedAt: Date?
    @Published private(set) var nextQuotaRefresh: Date?
    @Published private(set) var planets: [PlanetPosition] = []
    @Published private(set) var skyStatus = "请先设置观测地点"
    @Published private(set) var skyUpdatedAt: Date?
    @Published private(set) var now = Date()
    private var process: Process?
    private var input: FileHandle?
    private var output: FileHandle?
    private var buffer = Data()
    private var timer: Timer?
    private var timeout: Task<Void, Never>?
    private var sequence = 1
    private var pendingID: Int?
    private var skyLoading = false

    init() {
        let defaults = UserDefaults.standard
        zodiac = defaults.string(forKey: "workbench.zodiac") ?? ""
        let savedAvatar = defaults.string(forKey: "workbench.avatar") ?? "buu"
        avatar = ["buu", "goku", "vegeta", "piccolo", "ahri", "jinx", "yasuo", "teemo"].contains(savedAvatar) ? savedAvatar : "buu"
        name = defaults.string(forKey: "workbench.name") ?? "Flipos"
        motto = defaults.string(forKey: "workbench.motto") ?? motto
        note = defaults.string(forKey: "workbench.note") ?? ""
        folders = defaults.stringArray(forKey: "workbench.folders") ?? []
        city = defaults.string(forKey: "workbench.city") ?? ""
        latitude = defaults.string(forKey: "workbench.latitude") ?? ""
        longitude = defaults.string(forKey: "workbench.longitude") ?? ""
        if let data = defaults.data(forKey: "workbench.tasks"),
           let saved = try? JSONDecoder().decode([WorkbenchTask].self, from: data) {
            tasks = saved
        }
    }

    var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: now)
    }

    var todayTasks: [WorkbenchTask] { tasks.filter { $0.day == todayKey } }

    var moonCycle: Double {
        // Approximate synodic cycle; do not present this as precision ephemeris.
        let days = now.timeIntervalSince1970 / 86400 - 10962.75972
        let cycle = days / 29.530588853
        return cycle - floor(cycle)
    }

    var moonName: String {
        ["新月", "娥眉月", "上弦月", "盈凸月", "满月", "亏凸月", "下弦月", "残月"][Int((moonCycle * 8 + 0.5).rounded(.down)) % 8]
    }

    var moonIllumination: Double { (1 - cos(2 * .pi * moonCycle)) / 2 }

    func quotaRefreshCountdown(at date: Date) -> String {
        guard let nextQuotaRefresh else { return "自动刷新未启动" }
        let seconds = max(0, Int(ceil(nextQuotaRefresh.timeIntervalSince(date))))
        return String(format: "下次自动刷新：%02d:%02d", seconds / 60, seconds % 60)
    }

    func start() {
        now = Date()
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.now = Date()
                    self?.nextQuotaRefresh = self?.now.addingTimeInterval(120)
                    if let next = self?.nextQuotaRefresh { self?.timer?.fireDate = next }
                    self?.refreshQuota()
                }
            }
            nextQuotaRefresh = timer?.fireDate
        }
        refreshQuota()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        nextQuotaRefresh = nil
        timeout?.cancel()
        output?.readabilityHandler = nil
        if process?.isRunning == true { process?.terminate() }
        process = nil
        input = nil
        output = nil
    }

    func refreshQuota() {
        guard pendingID == nil else { return }
        if process?.isRunning == true {
            sequence += 1
            pendingID = sequence
            send(["method": "account/rateLimits/read", "id": sequence])
        } else {
            let candidates = [
                "/Applications/ChatGPT.app/Contents/Resources/codex",
                "/Applications/Codex.app/Contents/Resources/codex",
                "/opt/homebrew/bin/codex", "/usr/local/bin/codex"
            ]
            guard let path = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
                quotaStatus = "未找到 Codex：请安装官方桌面 App 或 CLI"
                return
            }
            let process = Process()
            let stdin = Pipe()
            let stdout = Pipe()
            guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                quotaStatus = "无法访问本地应用数据目录"
                return
            }
            let runtime = support.appendingPathComponent("ClipMini/CodexRuntime", isDirectory: true)
            do { try FileManager.default.createDirectory(at: runtime, withIntermediateDirectories: true) }
            catch { quotaStatus = "无法创建 Codex 运行目录"; return }
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = ["app-server", "--stdio", "-c", "analytics.enabled=false", "-c", "sqlite_home=\(String(reflecting: runtime.path))"]
            process.standardInput = stdin
            process.standardOutput = stdout
            process.standardError = FileHandle.nullDevice
            self.process = process
            input = stdin.fileHandleForWriting
            output = stdout.fileHandleForReading
            buffer = Data()
            output?.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                Task { @MainActor in self?.receive(data) }
            }
            do {
                try process.run()
                pendingID = 0
                send(["method": "initialize", "id": 0, "params": ["clientInfo": ["name": "clipmini_workbench", "version": "1.17"]]])
            } catch {
                quotaStatus = "Codex 启动失败，请检查安装"
                pendingID = nil
                return
            }
        }
        quotaStatus = quotaUpdatedAt == nil ? "正在读取在线额度…" : "自动更新中…"
        timeout?.cancel()
        timeout = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(25))
            guard !Task.isCancelled, let self, pendingID != nil else { return }
            pendingID = nil
            quotaStatus = "在线查询超时，将自动重试"
            output?.readabilityHandler = nil
            if process?.isRunning == true { process?.terminate() }
            process = nil
        }
    }

    private func send(_ message: [String: Any]) {
        guard var data = try? JSONSerialization.data(withJSONObject: message) else { return }
        data.append(10)
        try? input?.write(contentsOf: data)
    }

    func receive(_ data: Data) {
        guard !data.isEmpty else {
            if pendingID != nil { quotaStatus = "Codex 连接中断，将自动重试" }
            pendingID = nil
            output?.readabilityHandler = nil
            return
        }
        buffer.append(data)
        while let newline = buffer.firstIndex(of: 10) {
            let line = buffer.prefix(upTo: newline)
            buffer.removeSubrange(...newline)
            guard let message = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any] else { continue }
            if message["id"] as? Int == 0 {
                if message["error"] != nil {
                    quotaStatus = "Codex 协议初始化失败"
                    pendingID = nil
                    continue
                }
                send(["method": "initialized"])
                pendingID = nil
                refreshQuota()
            } else if (pendingID != nil && message["id"] as? Int == pendingID) || message["method"] as? String == "account/rateLimits/updated" {
                pendingID = nil
                timeout?.cancel()
                guard let result = (message["result"] ?? message["params"]) as? [String: Any] else {
                    quotaStatus = "在线额度不可用，请确认 Codex 已登录 ChatGPT"
                    continue
                }
                var windows: [QuotaWindow] = []
                let buckets = result["rateLimitsByLimitId"] as? [String: [String: Any]]
                let snapshots = buckets ?? (result["rateLimits"] as? [String: Any]).map { ["codex": $0] } ?? [:]
                for key in snapshots.keys.sorted() {
                    guard let bucket = snapshots[key] else { continue }
                    for slot in ["primary", "secondary"] {
                        guard let window = bucket[slot] as? [String: Any],
                              let used = window["usedPercent"] as? Double, used.isFinite else { continue }
                        let duration = window["windowDurationMins"] as? Int
                        let label = duration.map { $0 >= 1440 ? "\($0 / 1440) 天窗口" : ($0 >= 60 ? "\($0 / 60) 小时窗口" : "\($0) 分钟窗口") } ?? "额度窗口"
                        windows.append(QuotaWindow(id: key + slot, title: "\(bucket["limitName"] as? String ?? key) · \(label)", remaining: min(100, max(0, 100 - used)), reset: (window["resetsAt"] as? Double).map { Date(timeIntervalSince1970: $0) }))
                    }
                }
                quotas = windows
                quotaUpdatedAt = Date()
                quotaStatus = windows.isEmpty ? "服务未返回额度窗口，不代表剩余为零" : "在线数据 · 每 2 分钟自动更新"
            }
        }
    }

    func refreshSky() async {
        guard !skyLoading else { return }
        guard let lat = Double(latitude), let lon = Double(longitude),
              lat.isFinite, lon.isFinite, (-90...90).contains(lat), (-180...180).contains(lon) else {
            planets = []
            skyStatus = "请设置有效的观测经纬度"
            return
        }
        skyLoading = true
        defer { skyLoading = false }
        skyStatus = "正在查询 NASA Horizons…"
        let date = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        var positions: [PlanetPosition] = []
        // Sequential requests respect Horizons' no-simultaneous-queries policy.
        for (name, command) in [("金星", "299"), ("木星", "599")] {
            var components = URLComponents(string: "https://ssd.jpl.nasa.gov/api/horizons.api")!
            let values = ["format": "json", "COMMAND": "'\(command)'", "OBJ_DATA": "'NO'", "MAKE_EPHEM": "'YES'", "EPHEM_TYPE": "'OBSERVER'", "CENTER": "'coord@399'", "COORD_TYPE": "'GEODETIC'", "SITE_COORD": "'\(lon),\(lat),0'", "START_TIME": "'\(formatter.string(from: date))'", "STOP_TIME": "'\(formatter.string(from: date.addingTimeInterval(120)))'", "STEP_SIZE": "'1 m'", "QUANTITIES": "'4'", "CSV_FORMAT": "'YES'"]
            components.queryItems = values.map { URLQueryItem(name: $0.key, value: $0.value) }
            do {
                var request = URLRequest(url: components.url!)
                request.timeoutInterval = 20
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200,
                      let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let text = object["result"] as? String,
                      let start = text.range(of: "$$SOE"), let end = text.range(of: "$$EOE"), start.upperBound < end.lowerBound,
                      let row = text[start.upperBound..<end.lowerBound].split(separator: "\n").first else { continue }
                let fields = row.split(separator: ",", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
                guard fields.count >= 5, let az = Double(fields[3]), let alt = Double(fields[4]), az.isFinite, alt.isFinite else { continue }
                positions.append(PlanetPosition(id: name, azimuth: az, altitude: alt))
            } catch { continue }
        }
        planets = positions
        skyUpdatedAt = positions.isEmpty ? nil : date
        skyStatus = positions.count == 2 ? "NASA Horizons · 高度低于 0° 表示地平线下" : "部分或全部行星数据不可用，将自动重试"
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(name, forKey: "workbench.name")
        defaults.set(motto, forKey: "workbench.motto")
        defaults.set(note, forKey: "workbench.note")
        defaults.set(folders, forKey: "workbench.folders")
        defaults.set(city, forKey: "workbench.city")
        defaults.set(latitude, forKey: "workbench.latitude")
        defaults.set(longitude, forKey: "workbench.longitude")
        if let data = try? JSONEncoder().encode(tasks) { defaults.set(data, forKey: "workbench.tasks") }
    }
}
