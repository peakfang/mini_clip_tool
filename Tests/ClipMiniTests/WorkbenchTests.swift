import XCTest
import AppKit
import SwiftUI
@testable import ClipMini

final class WorkbenchTests: XCTestCase {
    func testLiuyaoResourcesAreOfflineAndAttributed() throws {
        let indexURL = try XCTUnwrap(Bundle.module.url(forResource: "liuyao-index", withExtension: "html", subdirectory: "Resources"))
        let appURL = try XCTUnwrap(Bundle.module.url(forResource: "liuyao-app", withExtension: "js", subdirectory: "Resources"))
        let licenseURL = try XCTUnwrap(Bundle.module.url(forResource: "liuyao-LICENSE", withExtension: "txt", subdirectory: "Resources"))
        let noticesURL = try XCTUnwrap(Bundle.module.url(forResource: "liuyao-THIRD_PARTY_NOTICES", withExtension: "md", subdirectory: "Resources"))
        let index = try String(contentsOf: indexURL, encoding: .utf8)
        let app = try String(contentsOf: appURL, encoding: .utf8)
        let license = try String(contentsOf: licenseURL, encoding: .utf8)
        let notices = try String(contentsOf: noticesURL, encoding: .utf8)
        XCTAssertTrue(index.contains("src=\"lunar.js\""))
        XCTAssertTrue(index.contains("src=\"liuyao-app.js\""))
        XCTAssertFalse(index.contains("cdnjs.cloudflare.com"))
        XCTAssertTrue(app.contains("铜钱起卦"))
        XCTAssertTrue(app.contains("本卦"))
        XCTAssertTrue(license.contains("MIT License"))
        XCTAssertTrue(notices.contains("6ebc6e67168352c786ecfe924c12c0305c78a10a"))
    }

    func testBuuAppIconHasAlphaAndReadableSize() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let image = try XCTUnwrap(NSImage(contentsOf: root.appendingPathComponent("Resources/AppIcon-Source.png")))
        let bitmap = try XCTUnwrap(image.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:)))
        XCTAssertGreaterThanOrEqual(bitmap.pixelsWide, 1024)
        XCTAssertGreaterThanOrEqual(bitmap.pixelsHigh, 1024)
        XCTAssertTrue(bitmap.hasAlpha)
    }

    func testFanMonitorNumericFormatsRejectInvalidData() {
        XCTAssertEqual(FanMonitor.decode(type: "fpe2", bytes: [0x24, 0x30], modern: false, attributes: 0), 2316)
        XCTAssertEqual(FanMonitor.decode(type: "sp78", bytes: [0x26, 0x80], modern: false, attributes: 0), 38.5)
        XCTAssertEqual(FanMonitor.decode(type: "flt ", bytes: [0, 0, 0x48, 0x42], modern: true, attributes: 4), 50)
        XCTAssertEqual(FanMonitor.decode(type: "flt ", bytes: [0x42, 0x48, 0, 0], modern: true, attributes: 0), 50)
        XCTAssertEqual(FanMonitor.decode(type: "ui32", bytes: [0, 0, 0x0d, 0x39], modern: true, attributes: 0), 3385)
        XCTAssertNil(FanMonitor.decode(type: "flt ", bytes: [0], modern: true, attributes: 4))
        XCTAssertNil(FanMonitor.decode(type: "flt ", bytes: [0, 0, 0, 0], modern: nil, attributes: 4))
        XCTAssertNil(FanMonitor.decode(type: "flt ", bytes: [0, 0, 0x80, 0x7f], modern: true, attributes: 4))
        XCTAssertNil(FanMonitor.decode(type: "unknown", bytes: [], modern: true, attributes: 0))
    }

    func testFanMonitorReadsThisMacWithoutWriting() async throws {
        let snapshot: FanSnapshot
        do { snapshot = try await FanMonitor().snapshot() }
        catch FanMonitor.MonitorError.accessDenied {
            throw XCTSkip("当前测试沙盒禁止 AppleSMC 访问，实机读取需在正常启动的应用中验证。")
        }
        XCTAssertFalse(snapshot.fans.isEmpty)
        XCTAssertFalse(snapshot.temperatures.isEmpty)
        for fan in snapshot.fans {
            let rpm = try XCTUnwrap(fan.rpm)
            let minimum = try XCTUnwrap(fan.minimum)
            let maximum = try XCTUnwrap(fan.maximum)
            XCTAssertGreaterThanOrEqual(rpm, 0)
            XCTAssertGreaterThan(maximum, minimum)
            print("只读风扇 \(fan.id): \(rpm) RPM，硬件范围 \(minimum)...\(maximum)")
        }
        XCTAssertTrue(snapshot.temperatures.allSatisfy { $0.celsius.map { (1...150).contains($0) } ?? true })
        print("本机只读温度传感器：\(snapshot.temperatures.count) 个")
    }

    func testCyberKLineChartRenders() async throws {
        try await MainActor.run {
            let birth = Calendar.current.date(from: DateComponents(year: 2000, month: 8, day: 16, hour: 4))!
            let reading = try XCTUnwrap(CyberFortune.shared.reading(birth: birth, gender: "女", year: 2026))
            let view = VStack(alignment: .leading, spacing: 16) {
                Text("人生 K 线 · 本地规则，文化娱乐").font(.title2)
                LifeCandleChart(candles: reading.life, selected: .constant(reading.life[26])).frame(width: 780, height: 230)
                Text("2026 年 · 年度月线").font(.headline)
                LifeCandleChart(candles: reading.months, selected: .constant(nil)).frame(width: 780, height: 230)
            }.padding(24).background(Color.white).preferredColorScheme(.light)
            let image = try XCTUnwrap(ImageRenderer(content: view).nsImage)
            let bitmap = try XCTUnwrap(image.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:)))
            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
            let path = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("outputs/Cyber-KLine-Preview.png")
            try png.write(to: path)
            XCTAssertGreaterThan(bitmap.pixelsWide, 750)
        }
    }

    func testCyberLifeKLineIsOfflineDeterministicAndBounded() async throws {
        try await MainActor.run {
            let birth = Calendar.current.date(from: DateComponents(year: 2000, month: 8, day: 16, hour: 4))!
            let today = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 12))!
            let reading = try XCTUnwrap(CyberFortune.shared.reading(birth: birth, gender: "女", year: 2026, today: today))
            XCTAssertEqual(reading.bazi, Almanac.shared.details(birth, birth: true)["bazi"])
            XCTAssertEqual(reading.life.count, 100)
            XCTAssertEqual(reading.months.count, 12)
            XCTAssertEqual(reading.life.first?.year, 2000)
            XCTAssertEqual(reading.life.last?.age, 100)
            XCTAssertFalse(reading.dayun.isEmpty)
            for candle in reading.life + reading.months {
                XCTAssertTrue((1...100).contains(candle.low))
                XCTAssertTrue((1...100).contains(candle.high))
                XCTAssertLessThanOrEqual(candle.low, min(candle.open, candle.close))
                XCTAssertGreaterThanOrEqual(candle.high, max(candle.open, candle.close))
            }
            let again = CyberFortune.shared.reading(birth: birth, gender: "女", year: 2026, today: today)
            XCTAssertEqual(again?.life.map(\.close), reading.life.map(\.close))
            XCTAssertNil(CyberFortune.shared.reading(birth: birth, gender: "", year: 2026, today: today))
            XCTAssertNil(CyberFortune.shared.reading(birth: birth, gender: "女", year: 1999, today: today))
        }
    }

    func testBundledAvatarImagesDecode() async {
        await MainActor.run {
            for id in ["buu", "goku", "vegeta", "piccolo", "ahri", "jinx", "yasuo", "teemo"] {
                let image = WorkbenchView(store: WorkbenchStore()).avatarImage(id)
                XCTAssertTrue(image.isValid && image.size.width >= 1024, "头像无法加载：\(id)")
            }
        }
    }

    func testDeepSeekRequestAndReplyParsing() async throws {
        try await MainActor.run {
            let request = try AIChatStore.request(key: "test-only", model: "deepseek-flash", messages: [
                AIChatMessage(role: "user", content: "你好"), AIChatMessage(role: "assistant", content: "你好！")
            ])
            XCTAssertEqual(request.url?.absoluteString, "https://api.deepseek.com/chat/completions")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-only")
            let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            XCTAssertEqual(body["model"] as? String, "deepseek-flash")
            XCTAssertEqual(body["stream"] as? Bool, false)
            XCTAssertEqual((body["messages"] as? [[String: String]])?.count, 2)
            XCTAssertNil(body["api_key"])
            let reply = Data("{\"choices\":[{\"message\":{\"content\":\"测试回复\"}}]}".utf8)
            XCTAssertEqual(try AIChatStore.reply(reply), "测试回复")
            XCTAssertThrowsError(try AIChatStore.reply(Data("{}".utf8)))
            XCTAssertThrowsError(try AIChatStore.reply(Data("{\"choices\":[{\"message\":{\"content\":null}}]}".utf8)))
        }
    }

    func testOfflinePurpleStarReadingAndInvalidInputs() async {
        await MainActor.run {
            let birth = Calendar.current.date(from: DateComponents(year: 2000, month: 8, day: 16, hour: 4))!
            let date = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 14))!
            let result = Fortune.shared.reading(birth: birth, gender: "女", date: date, scope: "yearly")
            XCTAssertTrue(result["profile", default: ""].contains("破军"))
            XCTAssertEqual(result["mutagen"], "天同化禄 · 天机化权 · 文昌化科 · 廉贞化忌")
            XCTAssertEqual(result["官禄"], "化忌")
            XCTAssertFalse(Fortune.shared.reading(birth: birth, gender: "女", date: date, scope: "monthly").isEmpty)
            XCTAssertFalse(Fortune.shared.reading(birth: birth, gender: "女", date: date, scope: "daily").isEmpty)
            XCTAssertTrue(Fortune.shared.reading(birth: birth, gender: "", date: date, scope: "yearly").isEmpty)
            XCTAssertTrue(Fortune.shared.reading(birth: birth, gender: "女", date: date, scope: "bad").isEmpty)
        }
    }

    func testRefreshCountdownUsesActualTimerDeadline() async {
        await MainActor.run {
            let store = WorkbenchStore()
            XCTAssertEqual(store.quotaRefreshCountdown(at: Date()), "自动刷新未启动")
            store.start()
            guard let deadline = store.nextQuotaRefresh else { return XCTFail("Missing timer deadline") }
            XCTAssertEqual(store.quotaRefreshCountdown(at: deadline.addingTimeInterval(-120)), "下次自动刷新：02:00")
            XCTAssertEqual(store.quotaRefreshCountdown(at: deadline.addingTimeInterval(-59)), "下次自动刷新：00:59")
            XCTAssertEqual(store.quotaRefreshCountdown(at: deadline.addingTimeInterval(5)), "下次自动刷新：00:00")
            store.stop()
            XCTAssertNil(store.nextQuotaRefresh)
        }
    }

    func testDashboardGridEqualHeightAndSingleColumnTask() async {
        await MainActor.run {
            let top = ImageRenderer(content: WorkbenchRow {
                Color.red.frame(minHeight: 80).frame(maxHeight: .infinity)
                Color.blue.frame(minHeight: 160).frame(maxHeight: .infinity)
                Color.green.frame(minHeight: 120).frame(maxHeight: .infinity)
            }.frame(width: 852))
            guard let topImage = top.cgImage else { return XCTFail("Unable to render dashboard row") }
            XCTAssertEqual(topImage.height, 160)
            let bitmap = NSBitmapImageRep(cgImage: topImage)
            XCTAssertGreaterThan(bitmap.colorAt(x: 100, y: 150)?.redComponent ?? 0, 0.5)
            let bottom = ImageRenderer(content: WorkbenchRow {
                Color.red.frame(minHeight: 235).frame(maxHeight: .infinity)
            }.frame(width: 852))
            guard let bottomImage = bottom.cgImage else { return XCTFail("Unable to render task row") }
            XCTAssertEqual(bottomImage.height, 235)
            let lower = NSBitmapImageRep(cgImage: bottomImage)
            XCTAssertGreaterThan(lower.colorAt(x: 250, y: 230)?.redComponent ?? 0, 0.5)
            XCTAssertLessThan(lower.colorAt(x: 300, y: 230)?.alphaComponent ?? 1, 0.1)
        }
    }

    func testBundledOfflineAlmanacAndBirthChart() async {
        await MainActor.run {
            let date = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 12))!
            let values = Almanac.shared.details(date)
            XCTAssertFalse(values["yi", default: ""].isEmpty)
            XCTAssertFalse(values["ji", default: ""].isEmpty)
            XCTAssertEqual(values["yi"], "祭祀、治病、破屋、坏垣、馀事勿取")
            XCTAssertEqual(values["ji"], "诸事不宜")
            XCTAssertEqual(values["bazi"]?.split(separator: " ").count, 4)
            XCTAssertEqual(values["wuxing"]?.split(separator: " ").count, 4)
            let next = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            XCTAssertNotEqual(values["bazi"], Almanac.shared.details(next)["bazi"])
        }
    }

    func testOnlineSnapshotAndClamping() async {
        await MainActor.run {
            let store = WorkbenchStore()
            let message = """
            {"method":"account/rateLimits/updated","params":{"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":28,"windowDurationMins":300,"resetsAt":1900000000},"secondary":{"usedPercent":120,"windowDurationMins":10080}},"other":{"primary":{"usedPercent":-5}}}}}
            """
            store.receive(Data((message + "\n").utf8))
            XCTAssertEqual(store.quotas.map(\.remaining), [72, 0, 100])
            XCTAssertEqual(store.quotas[0].reset?.timeIntervalSince1970, 1900000000)
            XCTAssertNotNil(store.quotaUpdatedAt)
            store.stop()
        }
    }

    func testMissingWindowsAreNotZero() async {
        await MainActor.run {
            let store = WorkbenchStore()
            store.receive(Data("{\"method\":\"account/rateLimits/updated\",\"params\":{\"rateLimits\":{\"primary\":null}}}\n".utf8))
            XCTAssertTrue(store.quotas.isEmpty)
            XCTAssertTrue(store.quotaStatus.contains("不代表"))
            store.stop()
        }
    }

    func testFragmentedProtocolAndUnknownNotification() async {
        await MainActor.run {
            let store = WorkbenchStore()
            store.receive(Data("{\"method\":\"unknown\"}\n".utf8))
            XCTAssertNil(store.quotaUpdatedAt)
            let data = Data("{\"method\":\"account/rateLimits/updated\",\"params\":{\"rateLimits\":{\"primary\":{\"usedPercent\":40}}}}\n".utf8)
            store.receive(data.prefix(18))
            XCTAssertTrue(store.quotas.isEmpty)
            store.receive(data.dropFirst(18))
            XCTAssertEqual(store.quotas.first?.remaining, 60)
            XCTAssertNil(store.quotas.first?.reset)
            XCTAssertTrue((0...1).contains(store.moonCycle))
            XCTAssertTrue((0...1).contains(store.moonIllumination))
            store.stop()
        }
    }
}
