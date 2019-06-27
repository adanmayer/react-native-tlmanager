//
//  CustomViewController.swift
//  CustomNavigation
//
//  Created by Alexander Danmayer on 03.12.18.
//  Copyright © 2018 Alexander Danmayer. All rights reserved.
//

import UIKit

open class TLBaseViewController: UIViewController {
    public var manager: TLManager
    
    public init(manager: TLManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }
    
    public func isIpad() -> Bool {
        return ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad )
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class CustomViewController: TLBaseViewController {
    let MaxActionButtons = 1
    
    public var actionButtons: Array<Dictionary<AnyHashable, Any>>?
    public var auxiliaryButton: UIButton?

    public var menuButtonData: Dictionary<AnyHashable, Any>?
    public var menuButton: UIBarButtonItem?
    
    open func setupBackButton(_ forced: Bool = false, _ enabled: Bool = true) {
        if ((self.navigationController?.viewControllers.count ?? 0) > 1) || forced {
            let backbutton = UIButton(type: .custom)
            let image = UIImage(named: "Back")?.withRenderingMode(.alwaysTemplate)
            backbutton.tintColor = UIColor.white
            backbutton.setImage(image, for: .normal)
            backbutton.widthAnchor.constraint(equalToConstant: 40).isActive = true
            if enabled {
                backbutton.addTarget(self, action: #selector(backAction), for: .touchUpInside)
            } else {
                // do nothing
            }
            backbutton.translatesAutoresizingMaskIntoConstraints = false;
            backbutton.contentEdgeInsets = UIEdgeInsets(top: 0, left: -22, bottom: 0, right: 0)
            let barButton = UIBarButtonItem(customView: backbutton)
            self.navigationItem.leftBarButtonItem = barButton
        }
    }
    
    open func setupMenuButton() {
        if (menuButton != nil) {
            self.navigationItem.leftBarButtonItem = menuButton
        } else {
            let spacer = UIBarButtonItem.init(image: UIImage.init(named: "empty"), style: .plain, target: nil, action: nil)
            self.navigationItem.leftBarButtonItem = spacer
        }
    }

    open func assignMenuButton(_ buttonData: Dictionary<AnyHashable, Any>?) {
        self.menuButtonData = buttonData
        self.menuButton = nil
        if let item = self.menuButtonData {
            if (item["name"] as? String) != nil, let bIcon = (item["icon"] as? String) {
                let button = UIButton(type: .custom)
                let image = (UIApplication.shared.delegate as! TLManagerAppDelegate).imageFromString(bIcon, size: CGSize(width: ActionButtonDimensions.imageWidth, height: ActionButtonDimensions.imageHeight), fallbackAsset: nil).withRenderingMode(.alwaysTemplate)
                button.tag = 0
                button.tintColor = UIColor.white
                button.setImage(image, for: .normal)
                button.widthAnchor.constraint(equalToConstant: 40).isActive = true
                button.addTarget(self, action: #selector(menuButtonPressed(_:)), for: .touchUpInside)
                button.translatesAutoresizingMaskIntoConstraints = false;
                button.contentEdgeInsets = UIEdgeInsets(top: 0, left: -22, bottom: 0, right: 0)
                let barButton = UIBarButtonItem(customView: button)
                self.menuButton = barButton
            }
        }
    }
    
    open func assignActionButtons(_ buttons: Array<Dictionary<AnyHashable, Any>>?) {
        self.actionButtons = buttons
        self.auxiliaryButton = nil
        if (self.actionButtons != nil), self.actionButtons!.count > 0, MaxActionButtons > 0 {
            let buttons = self.actionButtons![0...min(self.actionButtons!.count - 1, MaxActionButtons - 1)]
            var rightBarButtons = Array<UIBarButtonItem>()
            var idx = 0
            for item in buttons {
                if (item["name"] as? String) != nil, let bIcon = (item["icon"] as? String) {
                    let button = UIButton(type: .custom)
                    let image = (UIApplication.shared.delegate as! TLManagerAppDelegate).imageFromString(bIcon, size: CGSize(width: ActionButtonDimensions.imageWidth, height: ActionButtonDimensions.imageHeight), fallbackAsset: nil).withRenderingMode(.alwaysTemplate)
                    button.tag = idx
                    button.tintColor = UIColor.white
                    button.setImage(image, for: .normal)
                    button.widthAnchor.constraint(equalToConstant: 40).isActive = true
                    button.addTarget(self, action: #selector(actionButtonPressed(_:)), for: .touchUpInside)
                    if ((item["name"] as! String) == "auxiliaryPage") {
                        self.auxiliaryButton = button
                    }
                    button.translatesAutoresizingMaskIntoConstraints = false;
                    button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 22, bottom: 0, right: 0)
                    let barButton = UIBarButtonItem(customView: button)
                    rightBarButtons.append(barButton)
                }
                idx = idx + 1
            }
            navigationItem.rightBarButtonItems = rightBarButtons
        } else {
            navigationItem.rightBarButtonItems = []
        }
    }
    
    @objc func backAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        if !self.navigationItem.hidesBackButton {
            setupBackButton()
        } else {
            setupMenuButton()
        }
        super.viewWillAppear(animated)
    }

    @objc public func menuButtonPressed(_ sender:UIButton!) {
        if (sender != nil) && (menuButtonData != nil) {
            manager.sendEvent(withName: "turbolinksExecuteAction", body: menuButtonData)
        }
    }
    
    @objc public func actionButtonPressed(_ sender:UIButton!) {
        if (sender != nil) && (actionButtons != nil), sender.tag < actionButtons!.count {
            let item = actionButtons![sender.tag]
            manager.sendEvent(withName: "turbolinksExecuteAction", body: item)
        }
    }
}
