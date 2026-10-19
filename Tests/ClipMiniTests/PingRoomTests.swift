import XCTest
@testable import ClipMini

final class PingRoomTests: XCTestCase {
    @MainActor
    func testNativeLANRoomLifecycleAndSignalControls() async throws {
        let host = PingRoom()
        let guest = PingRoom()
        let keys = ["pingRoomServer", "pingRoomNickname", "pingRoomPaused"]
        let previous = keys.map { UserDefaults.standard.object(forKey: $0) }
        defer {
            guest.leave()
            host.leave()
            for (key, value) in zip(keys, previous) { UserDefaults.standard.set(value, forKey: key) }
        }
        var ownCounts: [Int] = []
        host.onOwnSteelCount = { ownCounts.append($0) }
        host.nickname = "Host"
        host.hostLAN()
        for _ in 0..<80 where !host.joined && host.connecting { try await Task.sleep(for: .milliseconds(100)) }
        if host.status.contains("未找到局域网地址") { throw XCTSkip("This test needs an active local network interface") }
        XCTAssertTrue(host.joined, host.status)
        guard host.joined else { return }
        guest.nickname = "Guest"
        guest.server = host.server
        guest.code = host.code
        guest.paused = false
        var received: [(Int, String, PingPosition)] = []
        guest.onPing = { index, name, position, _ in received.append((index, name, position)) }
        guest.connect(create: false)
        for _ in 0..<80 where !guest.joined && guest.connecting { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertTrue(guest.joined, guest.status)
        guard guest.joined else { return }
        for _ in 0..<20 where guest.members.count != 2 { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertEqual(guest.members.count, 2)
        host.send(4, position: PingPosition(x: 0.2, y: 0.75))
        for _ in 0..<20 where received.isEmpty { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertEqual(received.first?.0, 4)
        XCTAssertEqual(received.first?.1, "Host")
        XCTAssertEqual(received.first?.2, PingPosition(x: 0.2, y: 0.75))
        try await Task.sleep(for: .milliseconds(600))
        host.send(8, position: PingPosition(x: 0.2, y: 0.75))
        for _ in 0..<20 where received.count < 2 { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertEqual(received.last?.0, 8, "Heartsteel must reach the other client")
        for _ in 0..<20 where guest.members.first(where: { $0.name == "Host" })?.steelCount != 1 { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertEqual(guest.members.first(where: { $0.name == "Host" })?.steelCount, 1)
        XCTAssertEqual(host.members.first(where: { $0.name == "Host" })?.steelCount, 1)
        XCTAssertTrue(ownCounts.contains(1))
        XCTAssertEqual(received.last?.2, PingPosition(x: 0.2, y: 0.75))
        let initial = received.count
        try await Task.sleep(for: .milliseconds(600))
        guest.paused = true
        host.send(6, position: PingPosition(x: 1, y: 0))
        try await Task.sleep(for: .milliseconds(600))
        XCTAssertEqual(received.count, initial)
        guest.paused = false
        host.send(6, position: PingPosition(x: 1, y: 0))
        for _ in 0..<20 where received.count == initial { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertEqual(received.count, initial + 1)
        guest.leave()
        for _ in 0..<20 where host.members.count != 1 { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertEqual(host.members.count, 1)
        guest.code = host.code
        guest.connect(create: false)
        for _ in 0..<30 where !guest.joined { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertTrue(guest.joined)
        host.leave()
        for _ in 0..<30 where guest.joined { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertFalse(guest.joined, "Leaving as host must close the LAN room")
    }

    func testPositionMapsDifferentSizesAndNegativeScreenOrigins() {
        let source = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        let target = CGRect(x: 0, y: -900, width: 1440, height: 900)
        let position = PingPosition(point: CGPoint(x: -1440, y: 810), screen: source)
        XCTAssertEqual(position, PingPosition(x: 0.25, y: 0.25))
        XCTAssertEqual(position.point(in: target), CGPoint(x: 360, y: -225))
        XCTAssertEqual(PingPosition(x: 1, y: 0).point(in: target), CGPoint(x: 1440, y: 0))
        XCTAssertFalse(PingPosition(x: .nan, y: 0).isValid)
        XCTAssertFalse(PingPosition(x: 1.1, y: 0).isValid)
    }

    @MainActor
    func testTenMembersAndRejectEleventh() async throws {
        let host = PingRoom()
        var guests: [PingRoom] = []
        let keys = ["pingRoomServer", "pingRoomNickname", "pingRoomPaused"]
        let previous = keys.map { UserDefaults.standard.object(forKey: $0) }
        defer {
            guests.forEach { $0.leave() }
            host.leave()
            for (key, value) in zip(keys, previous) { UserDefaults.standard.set(value, forKey: key) }
        }
        host.nickname = "Host"
        host.hostLAN()
        for _ in 0..<80 where !host.joined && host.connecting { try await Task.sleep(for: .milliseconds(100)) }
        if host.status.contains("未找到局域网地址") { throw XCTSkip("Needs a local network interface") }
        XCTAssertTrue(host.joined, host.status)
        guard host.joined else { return }
        for index in 1...10 {
            let guest = PingRoom()
            guests.append(guest)
            guest.nickname = "Guest\(index)"
            guest.server = host.server
            guest.code = host.code
            guest.connect(create: false)
            for _ in 0..<30 where guest.connecting { try await Task.sleep(for: .milliseconds(100)) }
            if index < 10 { XCTAssertTrue(guest.joined, guest.status) }
            else { XCTAssertFalse(guest.joined); XCTAssertTrue(guest.status.contains("已满"), guest.status) }
        }
        for _ in 0..<20 where host.members.count < 10 { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertEqual(host.members.count, 10)
    }

    @MainActor
    func testRejectInvalidInvitationAndInsecurePublicURL() {
        let room = PingRoom()
        room.nickname = "Guest"
        room.server = "ws://example.com:8765"
        room.code = "AAAAAAAA"
        room.connect(create: false)
        XCTAssertFalse(room.connecting)
        XCTAssertTrue(room.status.contains("wss://"))
        room.server = "ws://127.0.0.1:8765"
        room.code = "bad"
        room.connect(create: false)
        XCTAssertFalse(room.connecting)
        XCTAssertTrue(room.status.contains("8 位"))
    }
}
