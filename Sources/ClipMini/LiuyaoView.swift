import SwiftUI
import WebKit

struct LiuyaoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("六爻排盘").font(.headline)
                    Text("所有计算在本机完成 · 仅供传统文化娱乐参考")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("关闭") { dismiss() }.keyboardShortcut(.cancelAction)
            }.padding(.horizontal, 18).padding(.vertical, 12)
            Divider()
            LiuyaoWebView()
        }.frame(minWidth: 980, minHeight: 700)
    }
}

struct LiuyaoWebView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        guard let url = Bundle.main.url(forResource: "liuyao-index", withExtension: "html")
                ?? Bundle.module.url(forResource: "liuyao-index", withExtension: "html", subdirectory: "Resources") else {
            webView.loadHTMLString("<p style='font:16px system-ui;padding:24px'>六爻本地资源无法加载。</p>", baseURL: nil)
            return webView
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}

    @MainActor final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            decisionHandler(url.isFileURL || url.scheme == "about" ? .allow : .cancel)
        }
    }
}
