//
//  TLManager.swift
//  CustomNavigation
//
//  Created by Alexander Danmayer on 13.11.18.
//  Copyright © 2018 Alexander Danmayer. All rights reserved.
//

import UIKit
import WebKit
import Turbolinks

public protocol TLManagerAppDelegate {
    func willTransitionToSize(_ size: CGSize, safeArea: UIEdgeInsets)
    func imageFromString(_ str: String?, size: CGSize, fallbackAsset: String?) -> UIImage

    func initializeResources(_ manager: TLManager, options: Dictionary<AnyHashable, Any>)
    func releaseResources()
    
    func doPreprocessingForURL(_ manager: TLManager, url: URL) -> Bool
    func doPostprocessingForResponse(_ manager: TLManager, response: WKNavigationResponse) -> Bool
    func visitCompleted(_ manager: TLManager, url: URL)
    
    func executeActionWithData(_ manager: TLManager,  data: Dictionary<String, AnyObject>, completion: (() -> Void)?) -> Bool

    func visitStartupURL()
    func initialRequestFinished()
    func assignStartupURL(_ url: URL?)
    // if different targets are implemented
    func injectJavaScriptWithTarget(_ target: String,script: String,resolve: @escaping ((Any?) -> Swift.Void),reject: @escaping ((String, String?, Error?) -> Swift.Void))
    
    func registerGlobalSwipe() -> Bool
    func changeLocale(_ locale: String)
    func i18NItem(_ item: String) -> String
    
    func handleGlobalSwipe(_ manager: TLManager, sender: UISwipeGestureRecognizer)
    
    func addAppTabBar() -> TLTabBar
    func getTabBarCustomizer(_ manager: TLManager) -> TLCustomizerViewController
    
    func handleTitlePress(_ manager: TLManager, url: URL, location: CGPoint) -> Bool
    func updateNavigation(_ manager: TLManager, _ title: String, _ actionButtons: Array<Dictionary<AnyHashable, Any>>?, _ subMenuData: Dictionary<AnyHashable, Any>?) -> Bool
    func presentVisitableForSession(_ manager: TLManager, _ route: TurbolinksRoute) -> Bool

}

// default implementation
extension TLManagerAppDelegate {
    func startupPath() -> String? {
        return nil
    }
    
    func visitCompleted(_ manager: TLManager, url: URL) {
        // do nothing
    }
    
    func handleTitlePress(_ manager: TLManager, url: URL, location: CGPoint) -> Bool {
        return false
    }
    
    func updateNavigation(_ manager: TLManager,_ title: String, _ subMenuData: Dictionary<AnyHashable, Any>, _ actionButtons: Array<Dictionary<AnyHashable, Any>>?) -> Bool {
        return false
    }
    
    func presentVisitableForSession(_ manager: TLManager, _ route: TurbolinksRoute) -> Bool {
        return false
    }

    func executeActionWithData(_ manager: TLManager,  data: Dictionary<String, AnyObject>, completion: (() -> Void)? = nil) -> Bool {
        return false // not handled
    }
    
    func registerGlobalSwipe() -> Bool {
        return false
    }
    
    func addAppTabBar() -> TLTabBar {
        return TLTabBar(frame: .zero)
    }
    
    func getTabBarCustomizer(_ manager: TLManager) -> TLCustomizerViewController {
        return TLCustomizerViewController.init(manager: manager)
    }
    
    func handleGlobalSwipe(_ manager: TLManager, sender: UISwipeGestureRecognizer) {
        // do nothing
    }
    
}

struct ActionButtonDimensions {
    static let imageHeight: CGFloat =  20
    static let imageWidth: CGFloat = 20
}


@objc(TLManager)
public class TLManager : RCTEventEmitter, UIGestureRecognizerDelegate {
    var lastActivation: NSDate?
    open var isAppActive = true
    var menuIcon: String!
    var initialRequest = false
    var viewMounted = false
    var navigation: TLNavigationController!
	
    open var tabBar: TLTabBar?
    open var tabBarItems: Array<Dictionary<String, String>>!
    open var tabBarActiveItems: Array<Dictionary<String, String>>!
    open var tabBarDefaultItems: Array<Dictionary<String, String>>!
	
    var titleTextColor: UIColor?
    var subtitleTextColor: UIColor?
    var barTintColor: UIColor?
    var tintColor: UIColor?
    var messageHandler: String?
    var userAgent: String?
    var customMenuIcon: UIImage?
    var loadingView: String?
    open var baseURLString: String?
    open var nativeBaseURLString: String!
    weak var customizerView: TLCustomizerViewController?
    
    public var swipeLeft: UISwipeGestureRecognizer?
    public var swipeRight: UISwipeGestureRecognizer?
    
    var processPool:WKProcessPool!
    
    fileprivate var _mountView: UIView?
    
    deinit {
        if (viewMounted) {
            removeFromRootViewController()
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    func initializeViewManager(_ route: Dictionary<AnyHashable, Any>,_ options: Dictionary<AnyHashable, Any>) {
        setAppOptions(options)
        
        // change translation values
        if let locale = options["locale"] as? String {
            appDelegate.changeLocale(locale)
        }
        
        self.processPool = WKProcessPool()
        navigation = TLNavigationController(self)
        if let tabBarConfig = (options["tabBar"] as? Dictionary<String, Any>) {
            updateTabBar(tabBarConfig)
        } else {
            removeTabBar()
        }
        
        mountViewController(navigation)
        appDelegate.initializeResources(self, options: options)
        
        if appDelegate.registerGlobalSwipe() {
            // add back gesture recognizer for back
            //swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
            //swipeRight!.direction = .right
            //navigation.view.addGestureRecognizer(swipeRight!)
            
            swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
            swipeLeft!.direction = .left
            navigation.view.addGestureRecognizer(swipeLeft!)
        }
        
        // set base URL for native views
        nativeBaseURLString = (options["nativeBaseURL"] as? String ?? "about:blank")
 
        // clear webView
        navSession.webView.load(URLRequest.init(url: URL.init(string: "about:blank")!))
        if let href = route["href"] as? String, href != "" {
            DispatchQueue.main.async {
                self.visit(route)
            }
        }
    }
    
    @objc func handleSwipes(_ sender:UISwipeGestureRecognizer) {
        self.appDelegate.handleGlobalSwipe(self, sender: sender)
    }
    
    @objc public func mountViewManager(_ reactTag: NSNumber, _ route: Dictionary<AnyHashable, Any>,_ options: Dictionary<AnyHashable, Any>) {
        let manager:RCTUIManager =  self.bridge.uiManager!
        
        // we have to exec on methodQueue
        manager.methodQueue.async {
            manager.addUIBlock { (uiManager: RCTUIManager?, viewRegistry:[NSNumber : UIView]?) in
                self._mountView = uiManager!.view(forReactTag: reactTag)
                self.initializeViewManager(route, options)
                self._mountView = nil // reset mount view
                DispatchQueue.main.async {
                    self.handleViewMounted()
                }
            }
            manager.batchDidComplete()
        }
        //        self._mountView = rootViewController().view
        //        self.initializeViewManager(route, options)
        //        DispatchQueue.main.async {
        //            self.handleViewMounted()
        //        }
    }
    
    @objc public func unmountViewManager() {
        self.releaseResources()
    }
    
    public func mainNavigation() -> UINavigationController {
        return self.navigation
    }
    
    public func getBaseURLString() -> String? {
        return self.baseURLString
    }
    
    public func getWebViewConfiguration() -> WKWebViewConfiguration {
        return self.navigation.setupWebView(self)
    }
	
	public func isTabBarDataAvailable() -> Bool {
		return (self.tabBar != nil) && (self.tabBarItems != nil) && (self.tabBarDefaultItems != nil)
	}
	
    var application: UIApplication {
        return UIApplication.shared
    }
    
    public var appDelegate: TLManagerAppDelegate {
        return application.delegate as! TLManagerAppDelegate
    }
    
    func getRootViewController() -> UIViewController {
        return application.keyWindow!.rootViewController!
    }
	
	public var hasNavigation: Bool {
		return (self.navigation != nil)
	}
	
    public var navSession: TurbolinksSession {
        return navigation.session
    }
    
    fileprivate var visibleViewController: UIViewController {
        return navigation.visibleViewController!
    }
    
    @objc func hotReloadInitiated() {
        releaseResources()
        
        DispatchQueue.main.async {
            self.sendEvent(withName: "turbolinksUnmount", body: [])
        }
    }
    
    @objc func didBecomeActive() {
        isAppActive = true
        
        // after becoming active again reload page
        DispatchQueue.main.async {
//            if let visitableView = self.navSession.topmostVisitable {
//                visitableView.visitableView.hideScreenshot()
//                // refresh, if more than x Seconds have passed since last activation
//                if NSDate().timeIntervalSince(((self.lastActivation ?? NSDate()) as Date)) > 5 {
//                    visitableView.reloadVisitable()
//                } else {
//                    visitableView.visitableView.hideScreenshot()
//                }
//            }
            self.sendEvent(withName: "turbolinksAppBecomeActive", body: {})
        }
    }

    @objc func willResignActive() {
        lastActivation = NSDate()
        isAppActive = false

        resignFocusInWebView()
        // after becoming active again reload page
//        if let visitableView = self.navSession.topmostVisitable {
//            visitableView.visitableView.updateScreenshot()
//            visitableView.visitableView.showScreenshot()
//        }

        DispatchQueue.main.async {
            self.sendEvent(withName: "turbolinksAppResignActive", body: {})
        }
    }
    
    fileprivate func releaseResources() {
		print("TLManager: Release resouces")
        self.appDelegate.releaseResources()

        navigation.popToRootViewController(animated: false)
        navigation.viewControllers = []
		navigation.releaseRessources()
		
		if let swipe = self.swipeLeft {
			navigation.view.removeGestureRecognizer(swipe)
			self.swipeLeft = nil
		}
		
		if let swipe = self.swipeRight {
			navigation.view.removeGestureRecognizer(swipe)
			self.swipeRight = nil
		}

		self.removeTabBar()
		self.removeFromRootViewController()
		self.navigation.session = nil
        self.navigation = nil
		self.processPool = nil

        NotificationCenter.default.removeObserver(self)
    }
    
    @objc public func reloadVisitable() {
        let visitable = visibleViewController as! TLViewController
        visitable.reload()
    }
    
    @objc public func reloadSession() {
        navSession.cleanCookies()
        navSession.injectCookies()
        navSession.reload()
    }

    public func printCurrentLocation() {
        let script = "location.href"
        navSession.webView.evaluateJavaScript(script) {(result, error) in
            if error != nil {
                print("Javascript error: \(error!.localizedDescription)")
                //reject("js_error", error!.localizedDescription, error)
            } else {
                print(result ?? "")
            }
        }
    }

    @objc public func changeLocale(_ locale: String) {
        if (hasNavigation) {
            appDelegate.changeLocale(locale)
            for vc in navigation.viewControllers {
                if let vc = vc as? CustomViewController {
                    vc.changeLocale(locale)
                }
            }
        }
    }
    
    @objc public func dismiss() {
        if (hasNavigation) {
            navigation.dismiss(animated: true)
        }
    }
    
    @objc public func popToRoot() {
        if (hasNavigation) {
            navigation.popToRootViewController(animated: false)
        }
    }
    
    @objc public func backTo(_ route: Dictionary<AnyHashable, Any>) {
        let tRoute = TurbolinksRoute(route)
        var idx = navigation.viewControllers.lastIndex { (vc) -> Bool in
            return ((vc as? TLViewController)?.visitableURL.absoluteString == tRoute.url?.absoluteString)
        }

        // check if all subsequent views share the same route
        if (idx != nil) && (idx != navigation.viewControllers.count-1) {
            if (navigation.viewControllers[idx!..<(navigation.viewControllers.count-1)].firstIndex{ (vc) -> Bool in
                return ((vc as? TLViewController)?.visitableURL.absoluteString.contains(tRoute.url?.absoluteString ?? "_") == false) } != nil) {
                idx = nil
            }
        }
        
        if (idx != nil) {
            navigation.popToViewController(navigation.viewControllers[idx!], animated: true)
        } else {
            self.visit(route)
        }
    }

    @objc public func back() {
        if (hasNavigation) {
            navigation.popViewController(animated: true)
        }
    }
    
    @objc public func showRNView(_ moduleName: String, _ route: Dictionary<AnyHashable, Any>) {
        if (customizerView != nil) {
            self.hideTabBarCustomizer()
            return
        }
        
        if (navigation.topViewController is TLReactViewVisitableController) {
            if ((navigation.topViewController as! TLReactViewVisitableController).moduleName == moduleName) {
                return; // is already set
            }
        }
        
        if self.navigation.topViewController is TLViewController {
            self.visit(["title": route["title"] ?? "",
                        "href": TLReactViewVisitableController.getPathFor(moduleName: moduleName),
                        "action": route["action"] ?? "advance",
                        "actionButtons" : (route["actionButtons"] ?? [:])])
        }
    }

    @objc public func executeAction(_ actionData: Dictionary<String, Any>,
                                    _ resolve: @escaping ((Any) -> Swift.Void),
                                    _ reject: @escaping ((String?, Error?) -> Swift.Void)) {
        let data = actionData as Dictionary<String, AnyObject>
        if data["action"] != nil {
            defaultExecuteActionWithData(data) {
                resolve(true)
            }
        } else {
            reject("Parameter action not found!", nil)
        }
    }
    
   @objc public func selectTabBarItem(_ selectedItem: String) {
        // set highlight
        if let tabBar = self.tabBar, let _ = tabBar.items {
            if let item = tabBarActiveItems.first(where: {$0["id"] == selectedItem}) {
                if let idx = tabBarActiveItems.firstIndex(of: item),
                    (idx < tabBar.items!.count - 1) {
                    tabBar.selectedItem = tabBar.items![idx + 1]
                    return;
                }
            }
            // select Menu by default
            tabBar.selectedItem = nil
            if (tabBar.items!.count > 0) {
                tabBar.selectedItem = tabBar.items!.first
            }
        }
    }
    
    @objc public func updateNavigation(_ title: String, _ actionButtons: Array<Dictionary<AnyHashable, Any>>?, _ options: Dictionary<AnyHashable, Any>?) {
		if navSession.interactiveTransition { return }

		// rewrite to URL, if it got redirected
        if let visitable = visibleViewController as? TLViewController,
			visitable.visitableView.webView != nil,
			visitable.visitableURL != (visitable.visitableView.webView!.url ?? visitable.visitableURL) {
            visitable.visitableURL = visitable.visitableView.webView!.url!
        }
        
        if let viewController = (navigation.topViewController as? TLViewController) {
            viewController.title = title
            viewController.route.title = title
            viewController.assignActionButtons(actionButtons)
            
            _ = self.appDelegate.updateNavigation(self, title, actionButtons, options)
        }
    }
    
    @objc public func updateTabBar(_ tabBarConfig: Dictionary<AnyHashable, Any>) {
        if hasNavigation {
            if let items = tabBarConfig["items"] as? Array<Dictionary<String, AnyObject>>,
               let activeItems = tabBarConfig["activeItems"] as? Array<String>,
               let defaultItems = tabBarConfig["defaultItems"] as? Array<String> {
                addTabBarView(toView: navigation!.view!)
                let selectedItem = tabBarConfig["selectedItem"] as? String
                menuIcon = (tabBarConfig["menuIcon"] as? String) ?? "defaultMenuIcon"
                tabBarItems = items.map({
                                ["id": $0["id"] as! String,
                                 "href": $0["href"] as! String,
                                 "title": $0["title"] as? String ?? "",
                                 "icon": $0["icon"] as? String ?? "",
                                 "badgeValue": $0["badgeValue"] as? String ?? ($0["badgeValue"] as? NSNumber)?.stringValue ?? ""]})
                initTabbar(activeIds: activeItems, defaultIds: defaultItems, selectedItem: selectedItem)
            } else {
                self.removeTabBar()
            }
        }
    }
    
    fileprivate func mountViewController(_ viewController: UIViewController) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.hotReloadInitiated),
            name: NSNotification.Name(rawValue: "RCTBridgeWillReloadNotification"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.willResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil)

        removeFromRootViewController() // remove existing childViewController, in case of debug reloading...
        addToRootViewController(viewController)

        mainNavigation().interactivePopGestureRecognizer!.isEnabled = true
		mainNavigation().interactivePopGestureRecognizer!.delegate = self

        self.initialRequest = true
        viewMounted = true
    }
    
    fileprivate func addToRootViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: getRootViewController())
        getRootViewController().addChild(viewController)
        if (_mountView != nil) {
            _mountView!.addSubview(viewController.view)
            viewController.view.frame = _mountView!.frame
        } else {
            getRootViewController().view.addSubview(viewController.view)
        }
        viewController.didMove(toParent: getRootViewController())
    }
    
    fileprivate func removeFromRootViewController() {
        var viewController: UIViewController?
        getRootViewController().children.forEach { (child) in
            if (child is TLNavigationController) {
                viewController = child
            }
        }
        
        if let vc = viewController {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            vc.didMove(toParent: nil)
        }
        viewMounted = false
    }
    
    @objc public func visit(_ route: Dictionary<AnyHashable, Any>) {
        let tRoute = TurbolinksRoute(route)
        
        if (self.baseURLString != nil) && (tRoute.url?.absoluteString.starts(with: "/") ?? false ) {
            tRoute.url = URL.init(string: "\(self.baseURLString!)\(tRoute.url!.absoluteString)" )
        }
		
		if (tRoute.url != nil) {
			selectTabBarItemWith(url: tRoute.url!)
		}
		if (tRoute.popToRoot == true) {
			popToRoot()
		}

		if (tRoute.url?.host == "ReactNative.executeAction") {
			self.defaultExecuteActionWithData(tRoute.url!.params())
		} else {
			self.presentVisitableForSession(tRoute)
		}
    }

    @objc public func injectJavaScript(_ script: String,_ resolve: @escaping ((Any?) -> Swift.Void),_ reject: @escaping ((String, String?, Error?) -> Swift.Void)) {
        injectJavaScriptWithTarget("default", script, resolve, reject);
    }
    
    @objc public func injectJavaScriptWithTarget(_ target: String,_ script: String,_ resolve: @escaping ((Any?) -> Swift.Void),_ reject: @escaping ((String, String?, Error?) -> Swift.Void)) {
        if (target == "default") {
			if (hasNavigation) {
				navSession.webView.evaluateJavaScript(script) {(result, error) in
					if error != nil {
						let errorMsg = (error!._userInfo?.value(forKey: "WKJavaScriptExceptionMessage") as? String) ?? (error!.localizedDescription)
                        print("Javascript error: \(errorMsg)")
						reject("js_error", errorMsg, error)
					} else {
						resolve(result)
					}
				}
			}
        } else {
            self.appDelegate.injectJavaScriptWithTarget(target, script: script, resolve: resolve, reject: reject)
        }
    }
    
    @objc public func debugMsg(_ message: String) {
        print(message)
    }

	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if (gestureRecognizer == mainNavigation().interactivePopGestureRecognizer) && (mainNavigation().viewControllers.count > 1) {
			self.navSession.interactiveTransition = true // interactiveTransition started
		}
		return true
	}
	
    @objc public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		// allow additional screenedge recognizers if navigation pop gesture is active
		if ((gestureRecognizer == mainNavigation().interactivePopGestureRecognizer) && otherGestureRecognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self)) {
            return true
        }
        return false
    }
	
    fileprivate func presentVisitableForSession(_ route: TurbolinksRoute) {
        var visitable: (UIViewController & Visitable)? = nil
        if (route.url?.host == "ReactNative.local") {
            if (navigation.topViewController is TLReactViewVisitableController) {
                if ((navigation.topViewController as! TLReactViewVisitableController).moduleName == route.url!.lastPathComponent) {
                    return
                }
            }
            visitable = TLReactViewVisitableController(self, route)
        } else {
            resignFocusInWebView()
            let isExternalUrl = (route.url != nil) && (self.getBaseURLString() != nil) && !(route.url!.absoluteString.starts(with:self.getBaseURLString()!))
			if isExternalUrl {
				session(self.navSession, openExternalURL: route.url!)
				return
			} else {
				// let appDelegate handle presentation for view controller, if implemented
				if !appDelegate.presentVisitableForSession(self, route) {
					visitable = TLViewController(self, route: route)
				}
			}
        }
        
        if let visitable = visitable {
            if route.action == .Advance {
                navigation.pushViewController(visitable, animated: true)
            } else if route.action == .Replace {
                if navigation.isAtRoot {
                    navigation.setViewControllers([visitable], animated: false)
                } else {
                    navigation.popViewController(animated: false)
                    navigation.pushViewController(visitable, animated: false)
                }
            }
            if !(visitable is TLReactViewVisitableController) {
                navSession.visit(visitable)
            }
        }
    }
    
    fileprivate func resignFocusInWebView() {
        injectJavaScript("document.activeElement.blur()", { (data) in
            // fine
        }) { (str, str2, err) in
            print("error resigning focus from activeElement")
        }
    }
    
    fileprivate func setAppOptions(_ options: Dictionary<AnyHashable, Any>) {
        self.userAgent = options["userAgent"] as? String
        self.baseURLString = options["baseURL"] as? String
        self.messageHandler = options["messageHandler"] as? String
        self.loadingView = options["loadingView"] as? String
        if (options["navBarStyle"] != nil) { setNavBarStyle(options["navBarStyle"] as! Dictionary<AnyHashable, Any>) }
        
        //        self.userAgent = RCTConvert.nsString(options["userAgent"])
        //        self.messageHandler = RCTConvert.nsString(options["messageHandler"])
        //        self.loadingView = RCTConvert.nsString(options["loadingView"])
        //        if (options["navBarStyle"] != nil) { setNavBarStyle(RCTConvert.nsDictionary(options["navBarStyle"])) }
        //        if (options["tabBarStyle"] != nil) { setTabBarStyle(RCTConvert.nsDictionary(options["tabBarStyle"])) }
    }
    
    fileprivate func setNavBarStyle(_ style: Dictionary<AnyHashable, Any>) {
        barTintColor = style["barTintColor"] as? UIColor
        tintColor = style["tintColor"] as? UIColor
        titleTextColor = style["titleTextColor"] as? UIColor
        subtitleTextColor = style["subtitleTextColor"] as? UIColor
        
        //        barTintColor = RCTConvert.uiColor(style["barTintColor"])
        //        tintColor = RCTConvert.uiColor(style["tintColor"])
        //        titleTextColor = RCTConvert.uiColor(style["titleTextColor"])
        //        subtitleTextColor = RCTConvert.uiColor(style["subtitleTextColor"])
        //        customMenuIcon = RCTConvert.uiImage(style["menuIcon"])
    }
    
    public func defaultNotificationWithData(_ data: Dictionary<String, AnyObject>) {
        if let msgDelegate = self.mainNavigation().topViewController as? ViewMsgBridgeDelegate {
            msgDelegate.notificationWithData(self, data: data)
        } else {
            print("Notification: \(data)")
        }
    }
    
    public func defaultExecuteActionWithData(_ data: Dictionary<String, AnyObject>, completion: (() -> Void)? = nil) {
        // try to execute on application delegate
        if !appDelegate.executeActionWithData(self, data: data, completion: completion) {
            // execute on current top view
            if let msgDelegate = self.mainNavigation().topViewController as? ViewMsgBridgeDelegate {
                msgDelegate.executeActionWithData(self, data: data, completion: completion)
            } else {
                print("Could not execute action: \(data)")
            }
        }
    }

    public func defaultPreprocessingForURL(_ URL: URL) -> Bool {
        return self.appDelegate.doPreprocessingForURL(self, url: URL)
    }

    public func defaultPostprocessingForResponse(_ response: WKNavigationResponse) -> Bool {
        return self.appDelegate.doPostprocessingForResponse(self, response: response)
    }
	
    public func executeAction(data: Dictionary<String, AnyObject>) {
        DispatchQueue.main.async {
            self.sendEvent(withName: "turbolinksExecuteAction", body: data)
        }
    }
    
    func handleViewMounted() {
        sendEvent(withName: "turbolinksViewMounted", body: ["finished": "true"])
    }
    
    func handleVisitCompleted(_ URL: URL) {
        appDelegate.visitCompleted(self, url: URL)
        
        sendEvent(withName: "turbolinksVisitCompleted", body: ["href": URL.absoluteString, "path": URL.path])

        if (self.initialRequest) {
            self.initialRequest = false
            appDelegate.initialRequestFinished();
        }
    }
    
    override public static func requiresMainQueueSetup() -> Bool {
        return true;
    }
    
    override public var methodQueue: DispatchQueue {
        return DispatchQueue.main
    }
    
    override public func constantsToExport() -> [AnyHashable: Any]! {
        let appVersion   = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        let buildVersion = Bundle.main.infoDictionary![kCFBundleVersionKey as String] as? String
		let storeInfo = Bundle.main.appStoreReceiptURL?.lastPathComponent ?? "receipt"
		#if (arch(i386) || arch(x86_64)) // simulator
		var releaseInfo = "simulator"
		#else
		var releaseInfo = "production"
		#endif
		if (storeInfo == "sandboxReceipt") {
			releaseInfo = "beta"
		}
		
        return [
            "ErrorCode": [
                "httpFailure": ErrorCode.httpFailure.rawValue,
                "networkFailure": ErrorCode.networkFailure.rawValue,
            ],
            "Action": [
                "advance": Action.Advance.rawValue,
                "replace": Action.Replace.rawValue,
                "restore": Action.Restore.rawValue,
            ],
            "appVersion": appVersion ?? "?",
            "buildVersion": buildVersion ?? "?",
			"releaseInfo": releaseInfo
        ]
    }
    
    override public func supportedEvents() -> [String]! {
        return ["turbolinksVisit", "turbolinksVisitCompleted", "turbolinksRedirect", "turbolinksMessage", "turbolinksError",
                "turbolinksTitlePress", "turbolinksExecuteAction",
                "turbolinksSessionFinished", "turbolinksViewMounted", "turbolinksShowMenu",
                "turbolinksActiveTabItemsChanged", "turbolinksAppBecomeActive", "turbolinksAppResignActive",
                "turbolinksRNViewAppear", "turbolinksRNViewDisappear",
                "turbolinksUnmount"]
    }
}


extension URL {
    func params() -> [String:AnyObject] {
        var dict = [String:AnyObject]()
        
        if let components = URLComponents(url: self, resolvingAgainstBaseURL: false) {
            if let queryItems = components.queryItems {
                for item in queryItems {
                    dict[item.name] = item.value! as AnyObject
                }
            }
            return dict
        } else {
            return [:]
        }
    }
}
