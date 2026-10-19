import AppKit
import IOKit
import SwiftUI

struct FanReading: Identifiable, Sendable {
    let id: Int
    let rpm: Double?
    let minimum: Double?
    let maximum: Double?
}

struct TemperatureReading: Identifiable, Sendable {
    let id: String
    let celsius: Double?
}

struct FanSnapshot: Sendable {
    let fans: [FanReading]
    let temperatures: [TemperatureReading]
    let date: Date
}

// Only selectors 5 (read bytes), 8 (read index), and 9 (read metadata) exist here.
// The 80-byte AppleSMC wire layout and numeric formats are community documented:
// https://asahilinux.org/docs/hw/soc/smc/ and Aeolus Sources/SMCCore.
// No root helper, SMC write command, network request, or telemetry persistence.
actor FanMonitor {
    private var connection: io_connect_t = 0
    private var modern: Bool?
    private var metadata: [String: (size: UInt32, type: String, attributes: UInt8)] = [:]
    private var temperatureKeys: [String]?

    func snapshot() throws -> FanSnapshot {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { throw MonitorError.unavailable }
        defer { IOObjectRelease(service) }
        let provider = IORegistryEntryCreateCFProperty(service, "IOProviderClass" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
        modern = provider?.contains("RTBuddy") == true ? true : provider?.contains("ACPI") == true ? false : nil
        let openStatus = IOServiceOpen(service, mach_task_self_, 0, &connection)
        guard openStatus == kIOReturnSuccess else {
            connection = 0
            if openStatus == kIOReturnNotPermitted || openStatus == kIOReturnNotPrivileged {
                throw MonitorError.accessDenied
            }
            throw MonitorError.readFailure("open kernel=\(openStatus)")
        }
        defer { IOServiceClose(connection); connection = 0 }
        let count = try read("FNum")
        guard count.isFinite, count.rounded() == count,
              (0...16).contains(count) else { throw MonitorError.unavailable }
        let fans = (0..<Int(count)).map { index in
            FanReading(id: index, rpm: validated(reading: try? read("F\(index)Ac"), range: 0...30000),
                       minimum: validated(reading: try? read("F\(index)Mn"), range: 0...30000),
                       maximum: validated(reading: try? read("F\(index)Mx"), range: 0...30000))
        }
        if temperatureKeys == nil {
            guard let total = try? read("#KEY"), total.isFinite, total.rounded() == total,
                  (1...20000).contains(total) else { throw MonitorError.unavailable }
            var keys: [String] = []
            for index in 0..<Int(total) {
                try Task.checkCancellation()
                let reply = try call(key: 0, selector: 8, index: UInt32(index))
                let code = reply.load(fromByteOffset: 0, as: UInt32.self)
                reply.deallocate()
                let key = String(bytes: [UInt8(truncatingIfNeeded: code >> 24), UInt8(truncatingIfNeeded: code >> 16), UInt8(truncatingIfNeeded: code >> 8), UInt8(truncatingIfNeeded: code)], encoding: .ascii) ?? ""
                if key.hasPrefix("T"), let value = try? read(key),
                   ["flt ", "sp78"].contains(metadata[key]?.type ?? ""), value.isFinite, (1...150).contains(value) {
                    keys.append(key)
                }
            }
            temperatureKeys = keys.sorted()
        }
        let temperatures = (temperatureKeys ?? []).map {
            TemperatureReading(id: $0, celsius: validated(reading: try? read($0), range: 1...150))
        }
        return FanSnapshot(fans: fans, temperatures: temperatures, date: Date())
    }

    private func validated(reading: Double?, range: ClosedRange<Double>) -> Double? {
        guard let reading, reading.isFinite, range.contains(reading) else { return nil }
        return reading
    }

    private func read(_ key: String) throws -> Double {
        guard key.utf8.count == 4 else { throw MonitorError.unavailable }
        let code = key.utf8.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        if metadata[key] == nil {
            let reply = try call(key: code, selector: 9)
            defer { reply.deallocate() }
            let type = reply.load(fromByteOffset: 32, as: UInt32.self)
            let text = String(bytes: [UInt8(truncatingIfNeeded: type >> 24), UInt8(truncatingIfNeeded: type >> 16), UInt8(truncatingIfNeeded: type >> 8), UInt8(truncatingIfNeeded: type)], encoding: .ascii) ?? ""
            metadata[key] = (reply.load(fromByteOffset: 28, as: UInt32.self), text, reply.load(fromByteOffset: 36, as: UInt8.self))
        }
        guard let info = metadata[key], (1...32).contains(info.size) else { throw MonitorError.unavailable }
        let reply = try call(key: code, selector: 5, size: info.size)
        defer { reply.deallocate() }
        let bytes = (0..<Int(info.size)).map { reply.load(fromByteOffset: 48 + $0, as: UInt8.self) }
        guard let result = Self.decode(type: info.type, bytes: bytes, modern: modern, attributes: info.attributes) else {
            throw MonitorError.readFailure("type=\(info.type) size=\(info.size) key=\(key)")
        }
        return result
    }

    static func decode(type: String, bytes: [UInt8], modern: Bool?, attributes: UInt8) -> Double? {
        let value: Double
        switch type {
        case "ui8 " where bytes.count == 1: value = Double(bytes[0])
        case "fpe2" where bytes.count == 2: value = Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1])) / 4
        case "sp78" where bytes.count == 2: value = Double(Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))) / 256
        case "flt " where bytes.count == 4, "ui32" where bytes.count == 4:
            guard let modern else { return nil }
            let little = modern ? attributes & 0x04 != 0 : type == "flt "
            let ordered = little ? Array(bytes.reversed()) : bytes
            let bits = ordered.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
            value = type == "flt " ? Double(Float(bitPattern: bits)) : Double(bits)
        default: return nil
        }
        return value.isFinite ? value : nil
    }

    private func call(key: UInt32, selector: UInt8, index: UInt32 = 0, size: UInt32 = 0) throws -> UnsafeMutableRawPointer {
        guard [UInt8(5), 8, 9].contains(selector), connection != 0 else { throw MonitorError.unavailable }
        let input = UnsafeMutableRawPointer.allocate(byteCount: 80, alignment: 8)
        defer { input.deallocate() }
        input.initializeMemory(as: UInt8.self, repeating: 0, count: 80)
        input.storeBytes(of: key, toByteOffset: 0, as: UInt32.self)
        input.storeBytes(of: size, toByteOffset: 28, as: UInt32.self)
        input.storeBytes(of: selector, toByteOffset: 42, as: UInt8.self)
        input.storeBytes(of: index, toByteOffset: 44, as: UInt32.self)
        let output = UnsafeMutableRawPointer.allocate(byteCount: 80, alignment: 8)
        output.initializeMemory(as: UInt8.self, repeating: 0, count: 80)
        var length = 80
        let status = IOConnectCallStructMethod(connection, 2, input, 80, output, &length)
        guard status == kIOReturnSuccess, length == 80, output.load(fromByteOffset: 40, as: UInt8.self) == 0 else {
            let result = output.load(fromByteOffset: 40, as: UInt8.self)
            output.deallocate()
            throw MonitorError.readFailure("selector=\(selector) kernel=\(status) length=\(length) firmware=\(result)")
        }
        return output
    }

    enum MonitorError: Error { case unavailable; case accessDenied; case readFailure(String) }
}

struct FanMonitorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var snapshot: FanSnapshot?
    @State private var status = "正在读取本机传感器…"
    @State private var opening = false
    private let monitor = FanMonitor()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("风扇与温度").font(.title2.weight(.semibold))
                Spacer()
                Button("完成") { dismiss() }
            }
            Text("只读监测，不接管风扇；当前控制模式请在 Macs Fan Control 中查看。")
                .font(.caption).foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let snapshot {
                        if snapshot.fans.isEmpty { Text("本机未报告风扇。") }
                        ForEach(snapshot.fans) { fan in
                            HStack {
                                Image(systemName: "fanblades").foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("风扇 \(fan.id + 1)").font(.headline)
                                    Text("硬件范围：\(formatted(fan.minimum)) – \(formatted(fan.maximum)) RPM")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(formatted(fan.rpm) + " RPM").font(.title3).monospacedDigit()
                            }.padding(14).background(Color.primary.opacity(0.035)).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Divider()
                        Text("温度传感器 · 硬件编号").font(.headline)
                        if snapshot.temperatures.isEmpty { Text("暂无可读取的温度传感器").foregroundStyle(.secondary) }
                        ForEach(snapshot.temperatures) { sensor in
                            HStack {
                                Text(sensor.id).monospaced()
                                Spacer()
                                Text(sensor.celsius.map { String(format: "%.1f °C", $0) } ?? "不可用").monospacedDigit()
                            }
                        }
                    }
                }
            }
            Text(status).font(.caption).foregroundStyle(.secondary)
            Button(opening ? "正在打开…" : "打开 Macs Fan Control · 自动 / 自定义转速") {
                let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.crystalidea.macsfancontrol")
                    ?? URL(fileURLWithPath: "/Applications/Macs Fan Control.app")
                guard FileManager.default.fileExists(atPath: url.path) else {
                    status = "未找到 Macs Fan Control，请先安装后再使用调速入口。"
                    return
                }
                opening = true
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                    Task { @MainActor in
                        opening = false
                        if error != nil { status = "打开失败，请从访达打开 Macs Fan Control。" }
                    }
                }
            }.disabled(opening)
        }.padding(24).frame(width: 560, height: 540)
            .task {
                while !Task.isCancelled {
                    do {
                        let result = try await monitor.snapshot()
                        guard !Task.isCancelled else { return }
                        snapshot = result
                        status = "本机实时数据 · 每 2 秒刷新 · \(result.date.formatted(date: .omitted, time: .standard))"
                    } catch {
                        guard !Task.isCancelled else { return }
                        snapshot = nil
                        status = "本机传感器暂不可读取；你仍可打开 Macs Fan Control。"
                    }
                    do { try await Task.sleep(for: .seconds(2)) } catch { return }
                }
            }
    }

    private func formatted(_ value: Double?) -> String {
        value.map { String(format: "%.0f", $0) } ?? "不可用"
    }
}
