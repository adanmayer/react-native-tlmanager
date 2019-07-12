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

    func activateTopVisitable(_ activatedVC: TLViewController) {
        if let topVisitable = self.topViewController as? TLViewController {
            //deactivatedVC.visitableView.hideScreenshot()
            //deactivatedVC.visitableView.showScreenshot()
            self.session.activateVisitable(activatedVC, showScreenshot: false)
            topVisitable.reload()
        }
    }
    
    override open var viewControllers: [UIViewController] {
        get { return super.viewControllers }
        set {
            super.viewControllers = newValue
            if self.session.interactiveTransition {
                self.session.interactiveTransition = false
                print("Save settings now")
                if let vc = self.topViewController as? TLViewController {
                    vc.visitableDelegate?.visitableViewWillAppear(vc)
                }
            }
        }
    }

    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if  let _ = navigationController.topViewController as? TLViewController,
            let coordinator = navigationController.topViewController?.transitionCoordinator {

            // if viewController is in stack we are trying to show an old view controller during a transition
            self.session.interactiveTransition = coordinator.isInteractive
            print("Is interruptable: \(self.session.interactiveTransition)")
            coordinator.notifyWhenInteractionChanges({ (context) in
                print("Is cancelled: \(context.isCancelled)")
//                if (context.isCancelled) {
//                    if (self.viewControllers.firstIndex(of: viewController) != nil) {
//                        if let vc = viewController as? TLViewController {
//                            self.activateTopVisitable(topVC)
//                        }
//                   }
//                }
            })
        } else {
            self.session.interactiveTransition = false
        }
    }
    
}
