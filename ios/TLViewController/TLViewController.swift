//
//  ViewController.swift
//  CustomNavigation
//
//  Created by Alexander Danmayer on 06.11.18.
//  Copyright © 2018 Alexander Danmayer. All rights reserved.
//

import UIKit
import Turbolinks
import WebKit

public enum ViewAnimation : String {
    case normal
    case fade
}

public protocol ViewMsgBridgeDelegate {
    // overrideables
    func executeActionWithData(_ manager: TLManager, data: Dictionary<String, AnyObject>, completion: (() -> Void)?)
    func notificationWithData(_ manager: TLManager, data: Dictionary<String, AnyObject>)
}

open class TLViewController: CustomViewController, Visitable {
    open weak var visitableDelegate: VisitableDelegate?
    open var visitableURL: URL!
    open var hasContent: Bool = false
    open var keyboardVisible: Bool = false
	open var storedContentPosition: CGPoint = CGPoint.zero

    open var scrollView: UIScrollView? { return visitableView.webView?.scrollView }
    open var viewAnimation: ViewAnimation = .normal

    open var topVisitableConstraint: NSLayoutConstraint?
    open var bottomVisitableContraint: NSLayoutConstraint?
    
    var tapGestureRecognizer : UITapGestureRecognizer!
    var configuration: WKWebViewConfiguration?
    
    var route: TurbolinksRoute!
   
    deinit {
        self.route = nil
    }
    
    public convenience init(manager: TLManager, url: URL) {
        self.init(manager: manager)
        self.visitableURL = url
    }

    public convenience required init(_ manager: TLManager, route: TurbolinksRoute) {
        self.init(manager: manager, url: route.url!)
        self.route = route
        
        view.backgroundColor = UIColor.white
        installVisitableView()
        
        assignMenuButton(route.leftButton)
        assignActionButtons(route.actionButtons)
        initCustomViews()
    }
    
    open func initCustomViews() {
        
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
    }
   
    // MARK: Visitable View
    
    open private(set) lazy var visitableView: VisitableView! = {
		let view = VisitableView(frame: self.view.bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: Visitable
	
    open func visitableDidRender() {
        if (self.visitableView.webView?.url != nil) {
            manager.handleVisitCompleted((self.visitableView.webView?.url!)!)
        }
    }
    
    open func updateScrollViewInsets(_ forced: Bool = false) {
        // do necessary scroll inset updates here
    }
    
    open func didRedirect(to: URL) {
        self.visitableURL = to
    }
    
    func reload() {
        reloadVisitable()
    }
    
    fileprivate func installVisitableView() {
        view.addSubview(visitableView)

        let safeGuide = view.safeAreaLayoutGuide
        visitableView.leftAnchor.constraint(equalTo: safeGuide.leftAnchor).isActive = true
        visitableView.rightAnchor.constraint(equalTo: safeGuide.rightAnchor).isActive = true
        topVisitableConstraint = visitableView.topAnchor.constraint(equalTo: safeGuide.topAnchor, constant: 0)
        topVisitableConstraint?.isActive = true
        bottomVisitableContraint = visitableView.bottomAnchor.constraint(equalTo: safeGuide.bottomAnchor, constant: 0)
        bottomVisitableContraint?.isActive = true
    }
	
	open func restoreStoredScrollPosition() {
		// restore contentOffset
		if (self.visitableView.webView != nil) {
			self.visitableView.webView!.scrollView.contentOffset = self.storedContentPosition
		}
	}
    
    open override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.hidesBackButton = (self.navigationController!.viewControllers.count <= 1)
        super.viewWillAppear(animated)
        self.title = route.title

        visitableDelegate?.visitableViewWillAppear(self)
               
        tapGestureRecognizer = UITapGestureRecognizer(target:self, action: #selector(self.navBarTapped(_:)))
        manager.navigation.navigationBar.addGestureRecognizer(tapGestureRecognizer)
		
		// add keyboard notifications
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        
        visitableDelegate?.visitableViewDidAppear(self)
    }
	
    @objc func navBarTapped(_ theObject: UITapGestureRecognizer){
        let pressedLocation = theObject.location(in: manager.navigation.navigationBar)
        
        let navbounds: CGRect = manager.mainNavigation().navigationBar.bounds
        let leftButtonBounds = CGRect(x: navbounds.minX, y: navbounds.minY, width: 50, height: navbounds.height)
        let rightButtonBounds = CGRect(x: navbounds.maxX - 50, y: navbounds.minY, width: 50, height: navbounds.height)
        // trigger left button
        if (manager.mainNavigation().topViewController?.navigationItem.leftBarButtonItem != nil)
            && leftButtonBounds.contains(pressedLocation) {
            let button: UIBarButtonItem = manager.mainNavigation().topViewController!.navigationItem.leftBarButtonItem!
            if ((button.customView != nil) && ((button.customView as? UIButton) != nil)) {
                (button.customView as! UIButton).sendActions(for: .touchUpInside)
            } else {
                UIApplication.shared.sendAction(button.action!, to: button.target, from: self, for: nil)
            }
            return
        }

        // trigger right button
        if (manager.mainNavigation().topViewController?.navigationItem.rightBarButtonItem != nil)
            && rightButtonBounds.contains(pressedLocation) {
            let button: UIBarButtonItem = manager.mainNavigation().topViewController!.navigationItem.rightBarButtonItem!
            if ((button.customView != nil) && ((button.customView as? UIButton) != nil)) {
                (button.customView as! UIButton).sendActions(for: .touchUpInside)
            } else {
                UIApplication.shared.sendAction(button.action!, to: button.target, from: self, for: nil)
            }
            return
        }
        
        if !manager.appDelegate.handleTitlePress(manager, url: self.visitableURL, location: pressedLocation) {
            manager.sendEvent(withName: "turbolinksTitlePress", body: [])
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
		if (self.visitableView.webView != nil) {
			self.storedContentPosition = self.visitableView.webView!.scrollView.contentOffset
		} else {
			self.storedContentPosition = CGPoint.zero
		}
        super.viewWillAppear(animated)
		if manager.hasNavigation {
			manager.navigation.navigationBar.removeGestureRecognizer(tapGestureRecognizer)
		}
		self.navigationController?.navigationBar.removeGestureRecognizer(tapGestureRecognizer)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

		NotificationCenter.default.removeObserver(self)
    }
   
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc open func keyboardWillShow() {
        keyboardVisible = true
    }
    
    @objc open func keyboardDidShow() {
    }
    
    @objc open func keyboardWillHide() {
        keyboardVisible = false
    }

    @objc open func keyboardDidHide() {
    }
    
}
