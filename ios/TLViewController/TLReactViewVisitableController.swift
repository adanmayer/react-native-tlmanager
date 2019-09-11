//
//  ReactViewController.swift
//  RNTLWebView
//
//  Created by Alexander Danmayer on 09.01.19.
//  Copyright © 2019 Faria. All rights reserved.
//

import Foundation
import WebKit
import Turbolinks

class RNVisitableView: VisitableView {
    
    private lazy var blankPage: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        return view
    }()
    
    func showBlankPage() {
        addSubview(blankPage)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: [ "view": blankPage ]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: [ "view": blankPage ]))
    }
    
    func hideBlankPage() {
        blankPage.removeFromSuperview()
    }
       
    override func activateWebView(_ webView: WKWebView, forVisitable visitable: Visitable) {
        // do nothing
        self.webView = webView
    }
}


public class ReactNativeBridge {
    public let bridge: RCTBridge
    
    public init(launchOptions: Dictionary<AnyHashable, Any>? = nil) {
        var jsCodeLocation: URL
//        #if DEBUG
            jsCodeLocation = RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index", fallbackResource:nil)
//        #else
//            jsCodeLocation = CodePush.bundleURL();
//        #endif
        print(jsCodeLocation)
        bridge = RCTBridge(bundleURL: jsCodeLocation, moduleProvider: nil, launchOptions: launchOptions)
    }
}

public class TLReactViewVisitableController: CustomViewController, Visitable, ViewMsgBridgeDelegate {
    
    open weak var visitableDelegate: VisitableDelegate?
    open var visitableURL: URL!
	open var moduleURL: URL!
    
    open var webView: WKWebView?
    
    let moduleName: String!
    
	class func getPathFor(moduleName: String) -> String {
		return "RN://ReactNative.local/\(moduleName)"
	}
    
    deinit {
        setParentRecogniserFor(view: nil, enabled: true)
    }
	
    init(_ manager: TLManager, _ route: TurbolinksRoute) {
        self.moduleName = route.url!.lastPathComponent
        self.visitableURL = URL.init(string: manager.nativeBaseURLString)
        self.moduleURL = URL.init(string: TLReactViewVisitableController.getPathFor(moduleName: self.moduleName))
        super.init(manager: manager)
        
        self.title = manager.appDelegate.i18NItem("\(moduleName!)Title")
        self.edgesForExtendedLayout = [];

        self.view.backgroundColor = UIColor.clear
        
        self.assignMenuButton(route.leftButton)
        self.assignActionButtons(route.actionButtons)
        
        let rootView = RCTRootView(bridge: manager.bridge,
                                   moduleName: moduleName,
                                   initialProperties: nil)
        self.view = rootView
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func activateWebView(_ webView: WKWebView) {
        // do nothing
        self.webView = webView
        self.webView?.isHidden = true
        view.addSubview(webView)
    }
    
    func deactivateWebView() {
        if (self.webView?.superview == self.view) {
            self.webView?.removeFromSuperview()
        }
        self.webView?.isHidden = false
    }
    
    public func setParentRecogniserFor(view: UIView?, enabled: Bool) {
        var rnSuperView = (view != nil) ? view!.superview : UIApplication.shared.keyWindow!.rootViewController!.view
        while (rnSuperView != nil) {
            if let rnRootView = rnSuperView as? RCTRootView {
                rnRootView.contentView.gestureRecognizers?.forEach({ (recogniser) in
                    recogniser.isEnabled = enabled
                })
            }
            rnSuperView = rnSuperView?.superview
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.hidesBackButton = (self.navigationController!.viewControllers.count <= 1)
        super.viewWillAppear(animated)
        
        self.manager.sendEvent(withName: "turbolinksRNViewAppear", body: ["href": self.moduleURL.absoluteString, "path": self.moduleURL.path, "title": self.title ?? ""])
        
        activateWebView(self.manager.navSession.webView)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setParentRecogniserFor(view: self.view, enabled: false)
        visitableDidRender()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deactivateWebView()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        setParentRecogniserFor(view: self.view, enabled: true)
        manager.sendEvent(withName: "turbolinksRNViewDisappear", body: ["href": moduleURL.absoluteString, "path": moduleURL.path, "title": self.title ?? ""])
    }
    
    open override func changeLocale(_ locale: String) {
        self.title = manager.appDelegate.i18NItem("\(moduleName!)Title")
    }
    
    // MARK: Visitable View
    
    open private(set) lazy var visitableView: VisitableView! = {
        let view = RNVisitableView(frame: self.view.bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    // MARK: Visitable
    
    open func visitableDidRender() {
        //manager.sendEvent(withName: "turbolinksVisitCompleted", body: ["href": moduleURL.absoluteString, "path": moduleURL.path])
        manager.handleVisitCompleted(moduleURL)
    }
    
    open func didRedirect(to: URL) {
        // do nothing
    }
    
    public func executeActionWithData(_ manager: TLManager, data: Dictionary<String, AnyObject>, completion: (() -> Void)? = nil) {
        manager.executeAction(data: data)
        completion?()
    }
    
    public func notificationWithData(_ manager: TLManager, data: Dictionary<String, AnyObject>) {
        print("Notification: \(data)")
    }
    
}
