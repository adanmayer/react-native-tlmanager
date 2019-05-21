import WebKit
import Turbolinks

class TLNavigationController: UINavigationController, UINavigationControllerDelegate {
    
    var session: TurbolinksSession!
    var isAtRoot: Bool { return viewControllers.count == 1 }
    let fadeAnimator = SimpleFadeAnimator()
    
    required convenience init(_ manager: TLManager) {
        self.init()
        self.session = TurbolinksSession(setupWebView(manager))
        self.session.delegate = manager
        if let barTintColor = manager.barTintColor { navigationBar.barTintColor = barTintColor }
        if let tintColor = manager.tintColor { navigationBar.tintColor = tintColor }
        navigationBar.prefersLargeTitles = false
        self.view.backgroundColor = UIColor(red:0.296, green:0.559, blue:0.979, alpha:1.000)
        self.delegate = self
    }
	
	deinit {
		print("deinit")
	}
	
    func setupWebView(_ manager: TLManager) -> WKWebViewConfiguration {
        let webConfig = WKWebViewConfiguration()
        if (manager.messageHandler != nil) { webConfig.userContentController.add(manager, name: manager.messageHandler!) }
        if (manager.userAgent != nil) { webConfig.applicationNameForUserAgent = manager.userAgent }
        
        // add additional javascript
        let bundle = Bundle(for: type(of: self))
        let source = try! String(contentsOf: bundle.url(forResource: "TLWebView", withExtension: "js")!, encoding: String.Encoding.utf8)
        let userScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webConfig.userContentController.addUserScript(userScript)
        webConfig.userContentController.removeScriptMessageHandler(forName: "MsgBridge")
        webConfig.userContentController.add(manager, name: "MsgBridge")
        
        // we are using a central processPool for cookie sharing
        webConfig.processPool = manager.processPool!
        return webConfig
    }
	
	func releaseRessources() {
		self.session.webView.configuration.userContentController.removeAllUserScripts()
		self.session.webView.configuration.userContentController.removeScriptMessageHandler(forName: "turbolinks")
		self.session.webView.configuration.userContentController.removeScriptMessageHandler(forName: "MsgBridge")
		self.session.releaseRessouces()
	}
    
    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if (operation == .none) { return nil }
        fadeAnimator.popStyle = (operation == .pop)

        if (operation == .push) {
            if let vc = toVC as? TLViewController, vc.viewAnimation == .fade {
                return fadeAnimator
            }
        } else {
            if let vc = fromVC as? TLViewController, vc.viewAnimation == .fade {
                fadeAnimator.shiftView = vc.visitableView
                return fadeAnimator
            }
        }
        return nil;
    }

}
