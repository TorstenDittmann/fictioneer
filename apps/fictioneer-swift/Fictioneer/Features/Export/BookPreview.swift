import SwiftUI
import WebKit

/// Drives the book preview: serves the publication's files to a WKWebView
/// under `fictioneer-book://`, paginates each document like an e-reader
/// (CSS columns, one page per viewport) and tracks the reading position.
@Observable
final class BookPreviewController: NSObject {
    enum Device: String, CaseIterable, Identifiable {
        case phone, tablet, reader

        var id: String { rawValue }
        var label: String {
            switch self {
            case .phone: "Phone"
            case .tablet: "Tablet"
            case .reader: "E-Reader"
            }
        }
        var systemImage: String {
            switch self {
            case .phone: "iphone"
            case .tablet: "ipad"
            case .reader: "book.pages"
            }
        }
        /// The screen in CSS pixels.
        var screen: CGSize {
            switch self {
            case .phone: CGSize(width: 390, height: 800)
            case .tablet: CGSize(width: 744, height: 1030)
            case .reader: CGSize(width: 600, height: 800)
            }
        }
    }

    enum Theme: String, CaseIterable, Identifiable {
        case light, sepia, dark

        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        var background: Color {
            switch self {
            case .light: Color(red: 1, green: 1, blue: 1)
            case .sepia: Color(red: 0.96, green: 0.93, blue: 0.85)
            case .dark: Color(red: 0.08, green: 0.08, blue: 0.09)
            }
        }
        fileprivate var css: (background: String, foreground: String) {
            switch self {
            case .light: ("#ffffff", "#1d1d1f")
            case .sepia: ("#f5eddb", "#5b4636")
            case .dark: ("#141417", "#d8d6d1")
            }
        }
    }

    private enum Landing: Equatable {
        case first, last, fraction(Double), anchor(String)
    }

    static let scheme = "fictioneer-book"

    var device: Device = .reader
    var theme: Theme = .light { didSet { applyReaderOptions() } }
    /// Percent of the book's own text size.
    var textScale: Int = 100 { didSet { applyReaderOptions() } }

    private(set) var publication: EpubPublication?
    private(set) var spineIndex = 0
    private(set) var page = 0
    private(set) var pageCount = 1

    @ObservationIgnored private weak var webView: WKWebView?
    @ObservationIgnored private var landing: Landing = .first

    var currentItem: EpubPublication.SpineItem? {
        guard let spine = publication?.spine, spine.indices.contains(spineIndex) else { return nil }
        return spine[spineIndex]
    }

    var canGoBack: Bool { page > 0 || spineIndex > 0 }
    var canGoForward: Bool {
        page < pageCount - 1 || spineIndex < (publication?.spine.count ?? 0) - 1
    }

    // MARK: - Web view

    func makeWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(self, forURLScheme: Self.scheme)
        configuration.userContentController.add(self, name: "reader")
        configuration.userContentController.addUserScript(WKUserScript(
            source: Self.readerScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true
        ))
        configuration.suppressesIncrementalRendering = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = false
        webView.allowsBackForwardNavigationGestures = false
        webView.setAccessibilityLabel("Book preview")
        self.webView = webView
        loadCurrent()
        return webView
    }

    func setZoom(_ zoom: CGFloat) {
        guard let webView, abs(webView.pageZoom - zoom) > 0.001 else { return }
        webView.pageZoom = zoom
    }

    // MARK: - Content

    /// Swaps in a rebuilt publication, keeping the reader where they were.
    func update(_ publication: EpubPublication?) {
        let previousPath = currentItem?.path
        let fraction = pageCount > 1 ? Double(page) / Double(pageCount - 1) : 0
        self.publication = publication
        guard let publication, !publication.spine.isEmpty else {
            webView?.loadHTMLString("", baseURL: nil)
            return
        }
        if let previousPath, let index = publication.spine.firstIndex(where: { $0.path == previousPath }) {
            spineIndex = index
            landing = .fraction(fraction)
        } else {
            spineIndex = min(spineIndex, publication.spine.count - 1)
            landing = .first
        }
        loadCurrent()
    }

    func go(toSpineIndex index: Int) {
        guard let spine = publication?.spine, spine.indices.contains(index) else { return }
        spineIndex = index
        landing = .first
        loadCurrent()
    }

    func nextPage() {
        if page < pageCount - 1 {
            evaluate("fictioneerReader.goTo(\(page + 1))")
        } else if let spine = publication?.spine, spineIndex < spine.count - 1 {
            spineIndex += 1
            landing = .first
            loadCurrent()
        }
    }

    func previousPage() {
        if page > 0 {
            evaluate("fictioneerReader.goTo(\(page - 1))")
        } else if spineIndex > 0 {
            spineIndex -= 1
            landing = .last
            loadCurrent()
        }
    }

    private func loadCurrent() {
        guard let webView, let item = currentItem,
              let url = URL(string: "\(Self.scheme)://book/\(item.path)")
        else { return }
        page = 0
        pageCount = 1
        webView.load(URLRequest(url: url))
    }

    private var readerOptions: String {
        let colors = theme.css
        return #"{"background":"\#(colors.background)","foreground":"\#(colors.foreground)","scale":\#(textScale)}"#
    }

    private func applyReaderOptions() {
        evaluate("fictioneerReader.configure(\(readerOptions))")
    }

    private func evaluate(_ script: String) {
        webView?.evaluateJavaScript(script, completionHandler: nil)
    }

    // MARK: - Reader script

    /// Paginates with CSS columns: each column is exactly one viewport wide,
    /// so page n starts at n × innerWidth.
    private static let readerScript = #"""
    (() => {
      const margin = 32;
      const style = document.createElement('style');
      (document.head || document.documentElement).appendChild(style);
      let page = 0;
      let options = { background: '#ffffff', foreground: '#1d1d1f', scale: 100 };

      const width = () => window.innerWidth;
      const pageCount = () => Math.max(1, Math.ceil((document.documentElement.scrollWidth - 2) / width()));
      const report = () => window.webkit.messageHandlers.reader.postMessage({ type: 'layout', page, pages: pageCount() });
      const show = (n) => {
        page = Math.max(0, Math.min(n, pageCount() - 1));
        document.documentElement.scrollLeft = page * width();
        document.body.scrollLeft = page * width();
        report();
      };

      function render() {
        style.textContent = `
          html { height: 100vh !important; overflow: hidden !important; background: ${options.background} !important; font-size: ${options.scale}% !important; }
          body { box-sizing: border-box !important; height: 100vh !important; margin: 0 !important; padding: ${margin}px !important;
                 column-width: calc(100vw - ${margin * 2}px) !important; column-gap: ${margin * 2}px !important; column-fill: auto !important;
                 background: transparent !important; color: ${options.foreground} !important; }
          body * { color: inherit !important; }
          img { max-width: 100% !important; max-height: calc(100vh - ${margin * 2}px) !important; object-fit: contain; }
          body.cover-page { padding: 0 !important; display: flex; align-items: center; justify-content: center; column-width: auto !important; }
          body.cover-page img { max-height: 100vh !important; }
          a { text-decoration: none; }
        `;
      }

      window.fictioneerReader = {
        configure(next) {
          const fraction = pageCount() > 1 ? page / (pageCount() - 1) : 0;
          options = next;
          render();
          requestAnimationFrame(() => show(Math.round(fraction * (pageCount() - 1))));
        },
        goTo: show,
        goToLast() { show(pageCount() - 1); },
        goToFraction(f) { show(Math.round(f * (pageCount() - 1))); },
        goToAnchor(id) {
          const target = document.getElementById(id);
          if (!target) { show(0); return; }
          const left = target.getBoundingClientRect().left + page * width();
          show(Math.floor(left / width()));
        }
      };

      document.addEventListener('keydown', (event) => {
        if (['ArrowRight', 'PageDown', ' '].includes(event.key)) { event.preventDefault(); window.webkit.messageHandlers.reader.postMessage({ type: 'turn', direction: 1 }); }
        if (['ArrowLeft', 'PageUp'].includes(event.key)) { event.preventDefault(); window.webkit.messageHandlers.reader.postMessage({ type: 'turn', direction: -1 }); }
      });

      let wheel = 0, wheelTimer = null;
      window.addEventListener('wheel', (event) => {
        const delta = Math.abs(event.deltaX) > Math.abs(event.deltaY) ? event.deltaX : event.deltaY;
        wheel += delta;
        clearTimeout(wheelTimer);
        wheelTimer = setTimeout(() => { wheel = 0; }, 180);
        if (Math.abs(wheel) > 80) {
          window.webkit.messageHandlers.reader.postMessage({ type: 'turn', direction: wheel > 0 ? 1 : -1 });
          wheel = -Math.sign(wheel) * 400;
        }
      }, { passive: true });

      document.addEventListener('click', (event) => {
        if (event.target.closest('a')) { return; }
        const x = event.clientX / width();
        if (x > 0.66) { window.webkit.messageHandlers.reader.postMessage({ type: 'turn', direction: 1 }); }
        if (x < 0.33) { window.webkit.messageHandlers.reader.postMessage({ type: 'turn', direction: -1 }); }
      });

      window.addEventListener('resize', () => requestAnimationFrame(() => show(page)));
      render();
      window.webkit.messageHandlers.reader.postMessage({ type: 'ready' });
      if (document.fonts) { document.fonts.ready.then(() => show(page)); }
    })();
    """#
}

// MARK: - Scheme handler

extension BookPreviewController: WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
              let file = publication?.file(at: String(url.path.dropFirst()))
        else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let response = URLResponse(
            url: url,
            mimeType: file.mediaType,
            expectedContentLength: file.data.count,
            textEncodingName: file.mediaType.hasPrefix("image/") || file.mediaType.hasPrefix("font/") ? nil : "utf-8"
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(file.data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {}
}

// MARK: - Messages and navigation

extension BookPreviewController: WKScriptMessageHandler, WKNavigationDelegate {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        switch type {
        case "ready":
            evaluate("fictioneerReader.configure(\(readerOptions))")
            switch landing {
            case .first: evaluate("fictioneerReader.goTo(0)")
            case .last: evaluate("fictioneerReader.goToLast()")
            case .fraction(let value): evaluate("fictioneerReader.goToFraction(\(value))")
            case .anchor(let id): evaluate("fictioneerReader.goToAnchor('\(id)')")
            }
            landing = .first
        case "layout":
            page = body["page"] as? Int ?? 0
            pageCount = max(1, body["pages"] as? Int ?? 1)
        case "turn":
            if (body["direction"] as? Int ?? 1) > 0 { nextPage() } else { previousPage() }
        default:
            break
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else { return decisionHandler(.cancel) }
        guard url.scheme == Self.scheme else {
            // Links out of the book (e.g. in back matter) open in the browser.
            if navigationAction.navigationType == .linkActivated, url.scheme == "https" || url.scheme == "http" {
                NSWorkspace.shared.open(url)
            }
            return decisionHandler(.cancel)
        }
        if navigationAction.navigationType == .linkActivated {
            // A table-of-contents link: route through the spine so the
            // position and page count stay in sync.
            let path = String(url.path.dropFirst())
            if let index = publication?.spine.firstIndex(where: { $0.path == path }) {
                spineIndex = index
                landing = url.fragment.map { .anchor($0) } ?? .first
                decisionHandler(.cancel)
                loadCurrent()
                return
            }
            return decisionHandler(.cancel)
        }
        decisionHandler(.allow)
    }
}

// MARK: - Views

struct BookWebView: NSViewRepresentable {
    let controller: BookPreviewController
    let zoom: CGFloat

    func makeNSView(context: Context) -> WKWebView {
        let webView = controller.makeWebView()
        webView.pageZoom = zoom
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        controller.setZoom(zoom)
    }
}

/// The preview canvas: a device-shaped frame scaled to fit, with the book
/// rendered at the device's true CSS size inside it.
struct BookPreviewStage: View {
    let controller: BookPreviewController

    var body: some View {
        GeometryReader { proxy in
            let device = controller.device
            let bezel: CGFloat = device == .reader ? 34 : 18
            let chin: CGFloat = device == .reader ? 56 : 18
            let outer = CGSize(width: device.screen.width + bezel * 2, height: device.screen.height + bezel + chin)
            let scale = min(
                (proxy.size.width - 48) / outer.width,
                (proxy.size.height - 48) / outer.height,
                1.2
            )
            VStack(spacing: 0) {
                BookWebView(controller: controller, zoom: max(scale, 0.1))
                    .frame(width: device.screen.width * scale, height: device.screen.height * scale)
                    .background(controller.theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: (device == .phone ? 28 : 6) * scale, style: .continuous))
                    .padding(.top, bezel * scale)
                    .padding(.horizontal, bezel * scale)
                    .padding(.bottom, chin * scale)
            }
            .background(
                RoundedRectangle(cornerRadius: (device == .phone ? 46 : device == .tablet ? 30 : 18) * scale, style: .continuous)
                    .fill(device == .reader ? Color(white: 0.2) : Color(white: 0.1))
                    .shadow(color: .black.opacity(0.25), radius: 18 * scale, y: 8 * scale)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: device)
        }
    }
}
