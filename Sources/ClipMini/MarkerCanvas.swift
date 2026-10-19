import AppKit
import WebKit

@MainActor
final class MarkerCanvas: NSObject, WKNavigationDelegate {
    let window: NSPanel
    let webView: WKWebView
    private let pageURL: URL?
    private var ready = false
    private var loading = false
    private var pending: [(UUID, String)] = []
    private var generation = UUID()
    private var lifecycle = UUID()
    private var hideWork: DispatchWorkItem?
    private var retries = 0

    init(frame: NSRect, pageURL: URL? = nil, configuration: WKWebViewConfiguration = WKWebViewConfiguration()) {
        self.pageURL = pageURL ?? Bundle.clipMiniResources.url(forResource: "index", withExtension: "html", subdirectory: "Resources/Pings")
        window = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        webView = WKWebView(frame: NSRect(origin: .zero, size: frame.size), configuration: configuration)
        super.init()
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = self
        window.contentView = webView
    }

    func show(_ index: Int, sender: String, point: NSPoint, steelCount: Int, frame: NSRect) {
        guard (0..<9).contains(index), point.x.isFinite, point.y.isFinite,
              let data = try? JSONSerialization.data(withJSONObject: [index, String(sender.prefix(20)), point.x - frame.minX, frame.maxY - point.y, max(0, steelCount)]),
              let arguments = String(data: data, encoding: .utf8) else { return }
        hideWork?.cancel()
        generation = UUID()
        let event = (generation, "remotePing(...\(arguments))")
        window.setFrame(frame, display: false)
        window.orderFrontRegardless()
        if ready { render(event) }
        else {
            if pending.count >= 30 { pending.removeFirst() }
            pending.append(event)
            if !loading { load() }
        }
    }

    func stop() {
        lifecycle = UUID()
        generation = UUID()
        hideWork?.cancel()
        pending.removeAll()
        window.orderOut(nil)
        webView.evaluateJavaScript("pings.replaceChildren()", completionHandler: nil)
    }

    private func load() {
        guard let pageURL else {
            NSLog("[ClipMini Marker] 缺少标记页面资源")
            window.orderOut(nil)
            return
        }
        ready = false
        loading = true
        if pageURL.isFileURL { webView.loadFileURL(pageURL, allowingReadAccessTo: pageURL.deletingLastPathComponent()) }
        else { webView.load(URLRequest(url: pageURL)) }
    }

    private func render(_ event: (UUID, String)) {
        let token = lifecycle
        webView.evaluateJavaScript(event.1) { [weak self] _, error in
            guard let self, self.lifecycle == token else { return }
            if let error {
                NSLog("[ClipMini Marker] 渲染失败：%@", error.localizedDescription)
                if self.pending.count < 30 { self.pending.append(event) }
                self.ready = false
                if !self.loading && self.retries < 1 {
                    self.retries += 1
                    self.load()
                } else if !self.loading { self.window.orderOut(nil) }
                return
            }
            self.retries = 0
            guard self.generation == event.0 else { return }
            self.window.orderFrontRegardless()
            self.hideWork?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self, self.generation == event.0 else { return }
                self.window.orderOut(nil)
            }
            self.hideWork = work
            // Start after WebKit confirms execution, not when loading begins.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: work)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loading = false
        ready = true
        webView.evaluateJavaScript("wheel.style.display='none'", completionHandler: nil)
        let events = pending
        pending.removeAll()
        events.forEach(render)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        ready = false
        loading = false
        hideWork?.cancel()
        window.orderOut(nil)
        if !pending.isEmpty { load() }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loading = false
        ready = false
        window.orderOut(nil)
        NSLog("[ClipMini Marker] 页面加载失败：%@", error.localizedDescription)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.webView(webView, didFail: navigation, withError: error)
    }
}
