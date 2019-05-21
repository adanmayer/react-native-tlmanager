//
//  ReactViewController.swift
//  RNTLWebView
//
//  Created by Alexander Danmayer on 09.01.19.
//  Copyright © 2019 Faria. All rights reserved.
//

import Foundation
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
    
    let moduleName: String!
    
    init(_ manager: TLManager, _ route: TurbolinksRoute) {
        self.moduleName = route.url!.lastPathComponent
        self.visitableURL = URL.init(string: "about:blank")
        
        super.init(manager: manager)
        
        self.title = TLManager.i18NItem("\(moduleName!)Title")
        self.edgesForExtendedLayout = [];

        let rootView = RCTRootView(bridge: manager.bridge,
                           moduleName: moduleName,
                           initialProperties: nil)
        self.view.backgroundColor = UIColor.clear
        self.view = rootView
        
        self.assignMenuButton(route.leftButton)
        self.assignActionButtons(route.actionButtons)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.hidesBackButton = (self.navigationController!.viewControllers.count <= 1)
        super.viewWillAppear(animated)
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
        // do nothing
    }
    
    open func didRedirect(to: URL) {
        // do nothing
    }
    
    public func executeActionWithData(_ manager: TLManager, data: Dictionary<String, AnyObject>, completion: (() -> Void)? = nil) {
        manager.forwardAction(data: data)

        completion?()
    }
    
    public func notificationWithData(_ manager: TLManager, data: Dictionary<String, AnyObject>) {
        print("Notification: \(data)")
    }
    
}
