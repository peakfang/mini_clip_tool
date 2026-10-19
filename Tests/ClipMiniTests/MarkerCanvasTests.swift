import AppKit
import WebKit
import XCTest
@testable import ClipMini

@MainActor
private final class DelayedMarkerPage: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            let html = "<html><div id='wheel'></div><div id='pings'></div><script>function remotePing(){pings.append(document.createElement('div'))}</script></html>"
            let data = Data(html.utf8)
            task.didReceive(URLResponse(url: task.request.url!, mimeType: "text/html", expectedContentLength: data.count, textEncodingName: "utf-8"))
            task.didReceive(data)
            task.didFinish()
        }
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

final class MarkerCanvasTests: XCTestCase {
    @MainActor
    func testSlowLoadAndOldHideDeadlineDoNotLoseMarkers() async throws {
        let configuration = WKWebViewConfiguration()
        let handler = DelayedMarkerPage()
        configuration.setURLSchemeHandler(handler, forURLScheme: "marker-test")
        let frame = NSRect(x: 0, y: 0, width: 480, height: 480)
        let canvas = MarkerCanvas(frame: frame, pageURL: URL(string: "marker-test://page"), configuration: configuration)
        defer { canvas.stop() }
        canvas.show(0, sender: "First", point: NSPoint(x: 100, y: 100), steelCount: 0, frame: frame)
        try await Task.sleep(for: .milliseconds(4600))
        let count = try await canvas.webView.evaluateJavaScript("pings.childElementCount")
        XCTAssertEqual(count as? Int, 1)
        XCTAssertTrue(canvas.window.isVisible, "Loading took longer than the old 3.5 second deadline")
        try await Task.sleep(for: .milliseconds(2800))
        canvas.show(6, sender: "Second", point: NSPoint(x: 200, y: 200), steelCount: 0, frame: frame)
        try await Task.sleep(for: .milliseconds(500))
        XCTAssertTrue(canvas.window.isVisible, "The previous hide must not hide a new marker")
        canvas.webViewWebContentProcessDidTerminate(canvas.webView)
        canvas.show(0, sender: "Recovered", point: NSPoint(x: 200, y: 200), steelCount: 0, frame: frame)
        try await Task.sleep(for: .milliseconds(4600))
        XCTAssertTrue(canvas.window.isVisible)
    }
}
