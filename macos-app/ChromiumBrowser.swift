import AppKit
import SwiftUI
import WebKit

private let chromiumUA =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
    "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 cs.AI/3.8.6"

private let browserHome = URL(string: "https://chopstickshq.com/")!

final class ChromiumWebState: ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var loadFailed = false
    @Published var addressText = browserHome.absoluteString
    weak var webView: WKWebView?

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
    func reload() { webView?.reload() }
    func goHome() { load(browserHome) }
    func load(_ url: URL) { webView?.load(URLRequest(url: url)) }

    func navigate(input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let url = Self.url(from: trimmed) {
            load(url)
            addressText = url.absoluteString
            return
        }
        let q = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        let search = URL(string: "https://www.google.com/search?q=\(q)")!
        load(search)
        addressText = search.absoluteString
    }

    static func url(from text: String) -> URL? {
        let lower = text.lowercased()
        if lower == "about:blank" || lower.hasPrefix("about:") {
            return URL(string: text)
        }
        if text.contains(" ") { return nil }
        if let url = URL(string: text), url.scheme != nil {
            return url
        }
        if text.contains(".") {
            return URL(string: "https://\(text)")
        }
        return nil
    }
}

struct ChromiumWebView: NSViewRepresentable {
    @ObservedObject var state: ChromiumWebState

    func makeCoordinator() -> Coordinator { Coordinator(state: state) }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: .zero, configuration: config)
        view.customUserAgent = chromiumUA
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.setValue(false, forKey: "drawsBackground")
        view.load(URLRequest(url: browserHome))
        DispatchQueue.main.async { state.webView = view }
        return view
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let state: ChromiumWebState
        init(state: ChromiumWebState) { self.state = state }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            state.isLoading = true
            state.loadFailed = false
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            state.isLoading = false
            state.loadFailed = false
            state.canGoBack = webView.canGoBack
            state.canGoForward = webView.canGoForward
            if let url = webView.url?.absoluteString {
                state.addressText = url
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            state.isLoading = false
            state.loadFailed = true
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            state.isLoading = false
            state.loadFailed = true
        }

        private func allowInWebView(_ url: URL) -> Bool {
            guard let scheme = url.scheme?.lowercased() else { return true }
            switch scheme {
            case "https", "about":
                return true
            case "http":
                return true
            default:
                return false
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                      decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            if allowInWebView(url) {
                decisionHandler(.allow)
                return
            }
            let scheme = url.scheme?.lowercased() ?? ""
            if scheme == "mailto" || scheme == "tel" || scheme == "sms" || scheme == "maps" {
                NSWorkspace.shared.open(url)
            }
            decisionHandler(.cancel)
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            guard navigationAction.targetFrame == nil,
                  let url = navigationAction.request.url,
                  allowInWebView(url),
                  url.scheme == "http" || url.scheme == "https" else {
                return nil
            }
            webView.load(URLRequest(url: url))
            return nil
        }
    }
}

struct ChromiumBrowserView: View {
    @ObservedObject var store = AppStore.shared
    @StateObject private var web = ChromiumWebState()
    @FocusState private var addressFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            browserToolbar
            ZStack {
                ChromiumWebView(state: web)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if web.loadFailed {
                    VStack(spacing: 10) {
                        Text("Web computer")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Cursor.muted)
                        Text("This page didn’t load in the in-app browser.")
                            .font(.system(size: 13))
                            .foregroundStyle(Cursor.text)
                        Button("Open in a new tab") {
                            if let url = URL(string: web.addressText) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Cursor.chromium)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Cursor.bg.opacity(0.92))
                }
            }
        }
        .background(Cursor.bg)
        .onChange(of: store.pendingBrowserURL) { _, href in
            guard href.lowercased().hasPrefix("https://"), let url = URL(string: href) else { return }
            web.load(url)
            web.addressText = href
        }
    }

    private var browserToolbar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                toolbarButton("chevron.left", enabled: web.canGoBack) { web.goBack() }
                toolbarButton("chevron.right", enabled: web.canGoForward) { web.goForward() }
                toolbarButton(web.isLoading ? "xmark" : "arrow.clockwise", enabled: true) { web.reload() }
                toolbarButton("house", enabled: true) { web.goHome() }

                HStack(spacing: 8) {
                    Image(systemName: web.addressText.lowercased().hasPrefix("https://") ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(web.addressText.lowercased().hasPrefix("https://") ? Cursor.chromium.opacity(0.85) : Color.orange.opacity(0.9))
                    TextField("Search or enter URL", text: $web.addressText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(Cursor.text)
                        .focused($addressFocused)
                        .onSubmit { web.navigate(input: web.addressText) }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Cursor.composer)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Cursor.border)
                )

                Button {
                    web.navigate(input: web.addressText)
                } label: {
                    Text("Go")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.88))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Cursor.chromium))
                }
                .buttonStyle(.plain)

                Button {
                    if let url = URL(string: web.addressText) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("Open tab")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Cursor.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Cursor.hover))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Cursor.panel)

            HStack {
                Text("Browser · chopstickshq.com home")
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(Cursor.muted)
                Spacer()
                Text("Same view cs.AI uses to open pages")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Cursor.muted)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
            .background(Cursor.panel)

            Rectangle().fill(Cursor.hairline).frame(height: 1)
        }
    }

    private func toolbarButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(enabled ? Cursor.text : Cursor.muted)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(enabled ? Cursor.hover : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
