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
	
	public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
		// if an interactive transaction ended => trigger appearance on the visitableDelegate, which blocked processing
		if let vc = viewController as? TLViewController {
			if self.session.interactiveTransition {
				self.session.interactiveTransition = false
				vc.viewWillAppear(false)
				vc.viewDidAppear(false)
			}
		}
	}
	
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let coordinator = navigationController.topViewController?.transitionCoordinator {
            // if viewController is in stack we are trying to show an old view controller during a transition
            self.session.interactiveTransition = coordinator.isInteractive
			coordinator.animate(alongsideTransition: nil, completion: { (context) in
				if context.isCancelled {
					if let fromController = context.viewController(forKey: .from) as? TLViewController {
						self.navigationController(navigationController, didShow: fromController, animated: animated)
					} else {
						self.session.interactiveTransition = false
					}
				}
			})
        } else {
            self.session.interactiveTransition = false
        }
    }
    
}
