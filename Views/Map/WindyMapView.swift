//
//  WindyMapView.swift
//  AquaGuard
//
//  Windy Map Forecast API rendered via WKWebView.
//  Uses Leaflet 1.4.0 + Windy libBoot.js to display weather overlays.
//

import SwiftUI
import WebKit

struct WindyMapView: UIViewRepresentable {
    let apiKey: String
    let overlay: String
    let centerLat: Double
    let centerLon: Double
    let zoom: Int

    // Track the current overlay so we can update it via JS
    @Binding var currentOverlay: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        // Add JS message handler for Swift ↔ JS communication
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "windyReady")
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.06, green: 0.11, blue: 0.15, alpha: 1.0)

        // Load the Windy HTML
        let html = generateWindyHTML()
        webView.loadHTMLString(html, baseURL: nil)

        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // When overlay changes from SwiftUI, update via JS
        if context.coordinator.isWindyReady && context.coordinator.lastOverlay != currentOverlay {
            context.coordinator.lastOverlay = currentOverlay
            let js = "if(typeof windyStore !== 'undefined') { windyStore.set('overlay', '\(currentOverlay)'); }"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    // MARK: - HTML Generation

    private func generateWindyHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, shrink-to-fit=no, viewport-fit=cover" />
            <script src="https://unpkg.com/leaflet@1.4.0/dist/leaflet.js"></script>
            <script src="https://api.windy.com/assets/map-forecast/libBoot.js"></script>
            <style>
                * { margin: 0; padding: 0; }
                html, body {
                    width: 100%;
                    height: 100%;
                    overflow: hidden;
                    background: #101B26;
                }
                #windy {
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    width: 100%;
                    height: 100%;
                }
                /* Hide default Windy UI controls for cleaner look */
                #bottom, #embed-zoom, #mobile-ovr-select,
                #legend, #progress-bar, .leaflet-control-zoom,
                .leaflet-control-attribution, #logo-wrapper,
                #windy .leaflet-bottom, .right-border,
                .progress-bar, .legend-bar {
                    display: none !important;
                }
            </style>
        </head>
        <body>
            <div id="windy"></div>
            <script>
                var windyStore = null;

                const options = {
                    key: '\(apiKey)',
                    lat: \(centerLat),
                    lon: \(centerLon),
                    zoom: \(zoom),
                    overlay: '\(overlay)',
                    verbose: false
                };

                windyInit(options, function(windyAPI) {
                    windyStore = windyAPI.store;

                    // Notify Swift that Windy is ready
                    window.webkit.messageHandlers.windyReady.postMessage('ready');
                });

                // Function callable from Swift to change overlay
                function changeOverlay(newOverlay) {
                    if (windyStore) {
                        windyStore.set('overlay', newOverlay);
                    }
                }
            </script>
        </body>
        </html>
        """
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WindyMapView
        var webView: WKWebView?
        var isWindyReady = false
        var lastOverlay: String = ""

        init(_ parent: WindyMapView) {
            self.parent = parent
            self.lastOverlay = parent.overlay
        }

        // WKScriptMessageHandler - receive messages from JS
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            if message.name == "windyReady" {
                isWindyReady = true
                print("WindyMapView: Windy API is ready")
            }
        }

        // WKNavigationDelegate
        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {
            print("WindyMapView: WebView finished loading")
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            print("WindyMapView: Navigation failed: \(error.localizedDescription)")
        }
    }
}
