import SwiftUI
import WebKit
import ZIPFoundation
import UIKit

//By ChatGPT, modified
struct WebView: UIViewRepresentable {
    var url: URL
    
    private let webView = WKWebView()   // Reference to WKWebView for direct access
    
//    var zoomLevel: CGFloat? // Make zoomLevel optional
    
    //    // Custom initializer to print a message upon initialization
    //    init(url: URL) {
    //        self.url = url
    //        print("---WebView---")
    //        print("WebView initialized with URL: \(url)")
    //    }
    func refresh() {
        webView.reload()
    }
    
    func makeUIView(context: Context) -> WKWebView {
//        let source = """
//document.addEventListener('DOMContentLoaded', function(event) {
//    if (typeof p5 !== 'undefined') {
//        const originalSetup = p5.prototype.setup;
//        p5.prototype.setup = function() {
//            if (originalSetup) originalSetup.call(this);
//            let sideLength = Math.min(window.innerWidth, window.innerHeight);
//            resizeCanvas(sideLength, sideLength);
//        };
//    }
//});
//"""
//        
//        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
//        
//        // Add the script to the web view's user content controller
//        webView.configuration.userContentController.addUserScript(script)
        setupSnapshotListener() // Setup the listener when the view is created
        print("makeUIView executed")
        // Assuming you have a WKWebView instance named webView
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        self.webView.isInspectable = true;
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard context.coordinator.lastLoadedURL != url else { return }
        uiView.load(URLRequest(url: url))
        context.coordinator.lastLoadedURL = url
//        if let zoomLevel = zoomLevel {
//            let jsZoomString = "document.body.style.zoom = '\(zoomLevel)'"
//            uiView.evaluateJavaScript(jsZoomString, completionHandler: nil)
//        }
    }
    
    func setupSnapshotListener() {
        NotificationCenter.default.addObserver(forName: .takeWebViewSnapshot, object: nil, queue: .main) { _ in
            self.takeSnapshot { image in
                // Here you can handle the snapshot image
                // For example, save it to the photo library
                if let image = image {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            }
        }
    }
    
    // Snapshot function accessible from SwiftUI
    func takeSnapshot(completion: @escaping (UIImage?) -> Void) {
        let config = WKSnapshotConfiguration()
        // Configure your snapshot here (e.g., specify rect, afterScreenUpdates, etc.)
        
        webView.takeSnapshot(with: config) { image, error in
            DispatchQueue.main.async {
                guard let image = image, error == nil else {
                    print(error?.localizedDescription ?? "Unknown error")
                    completion(nil)
                    return
                }
                completion(image)
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator class
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var lastLoadedURL: URL?
        init(_ webView: WebView) {
            self.parent = webView
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                // List of extensions you wish to block
                let blockedExtensions = ["pdf", "zip", "mp3", "doc", "docx", "xls", "xlsx"]
                if blockedExtensions.contains(where: url.pathExtension.lowercased().contains) {
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}

//By ChatGPT, exclusively
extension Notification.Name {
    static let takeWebViewSnapshot = Notification.Name("takeWebViewSnapshotNotification")
}



