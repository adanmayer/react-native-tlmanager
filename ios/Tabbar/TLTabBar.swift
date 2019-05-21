//
//  TLTabBar.swift
//  CustomNavigation
//
//  Created by Alexander Danmayer on 12.12.18.
//  Copyright © 2018 Alexander Danmayer. All rights reserved.
//

import UIKit

struct TabBarItemDimensions {
    static let imageHeight: CGFloat =  20
    static let imageWidth: CGFloat = 20
    static let fontSize: CGFloat = 10
}

open class TLTabBarItem: UITabBarItem {
    var id: String?
}

open class TLTabBar : UITabBar {
    var tabBarButtons = [UIView]()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open override func setItems(_ items: [UITabBarItem]?, animated: Bool) {
        clearTabBarButtonViews()
        super.setItems(items, animated: animated)
    }
    
    func clearTabBarButtonViews() {
        tabBarButtons = []
    }
    
    func getTabBarButtonViews() {
        clearTabBarButtonViews()
        // find the UITabBarButton instance.
        for subview in self.subviews.sorted(by: { (left, right) -> Bool in
            return (left.frame.origin.x < right.frame.origin.x)
        }) {
            if String(describing: type(of:subview)) == "UITabBarButton" {
                tabBarButtons.append(subview)
            }
        }
    }
    
    func getViewFromTabBarButton(index: Int) -> UIView {
        guard (index >= 0) && (index < tabBarButtons.count) else {
            fatalError("Index out of bounds (getViewFromTabBarButton): \(index)")
        }
        return tabBarButtons[index];
    }
    
    static func createTabBarItem(withData item: Dictionary<String, String>, tag: Int) -> UITabBarItem {
		let img = (UIApplication.shared.delegate as! TLManagerAppDelegate).imageFromString(item["icon"] ?? "", size: CGSize(width: TabBarItemDimensions.imageWidth, height: TabBarItemDimensions.imageHeight), fallbackAsset: nil)
		let title = (item["title"])?.stringByTruncatingToWidth(CustomizerCellDimensions.itemWidth, font: UIFont.systemFont(ofSize: TabBarItemDimensions.fontSize))
        let barItem = TLTabBarItem(title: title, image: img, tag: tag)
		barItem.id = (item["id"])
		if (item["badgeValue"] != "") && (item["badgeValue"] != "0") {
			barItem.badgeColor = UIColor.red
			barItem.badgeValue = item["badgeValue"]
		}
        return barItem
    }
}

extension TLTabBar : UIDropInteractionDelegate {
    func getButtonIndexFrom(session: UIDropSession) -> Int? {
        for index in 0..<tabBarButtons.count {
            let btnView = self.getViewFromTabBarButton(index: index)
            if btnView.bounds.contains(session.location(in: btnView)) {
                return index
            }
        }
        return nil
    }

    func updateDropTargetHighlight(withId dropTargetId: String?) {
        if (tabBarButtons.count == 0) { return } // if no views get out!
        for (buttonItem) in self.items! {
            if let btnIndex = self.items!.firstIndex(of: buttonItem) {
                let btnView = self.getViewFromTabBarButton(index: btnIndex)
                if let bItem = buttonItem as? TLTabBarItem, dropTargetId != nil, bItem.id == dropTargetId {
                    UIView.animate(withDuration: 0.2) {
                        btnView.backgroundColor = UIColor(red:0.6, green:0.6, blue:0.7, alpha:0.5)
                        btnView.layer.cornerRadius = 3
                        btnView.clipsToBounds = true
                    }
                } else {
                    UIView.animate(withDuration: 0.2) {
                        btnView.backgroundColor = nil
                        btnView.layer.cornerRadius = 0
                        btnView.clipsToBounds = false
                    }
                }
            }
        }
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        getTabBarButtonViews()
        updateDropTargetHighlight(withId: nil)
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        updateDropTargetHighlight(withId: nil)
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        updateDropTargetHighlight(withId: nil)
        clearTabBarButtonViews()
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: TLCustomizerDragItem.self)
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        if let idx = getButtonIndexFrom(session: session) {
            
            if let item = self.items![idx] as? TLTabBarItem, (item.tag >= 0) {
                updateDropTargetHighlight(withId: item.id)
                return UIDropProposal.init(operation: .move)
            } else {
                return UIDropProposal.init(operation: .forbidden)
            }
        }
        updateDropTargetHighlight(withId: nil)
        return UIDropProposal.init(operation: .cancel)
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        getTabBarButtonViews()
        for item in session.items {
            let itemProvider = item.itemProvider
            guard itemProvider.canLoadObject(ofClass: TLCustomizerDragItem.self)
                else {continue}
            
            if let idx = getButtonIndexFrom(session: session) {
                updateDropTargetHighlight(withId: nil) // clear drop highlight
                clearTabBarButtonViews()
                
                itemProvider.loadObject(ofClass: TLCustomizerDragItem.self, completionHandler: { (object, error) in
                    if let dragItem = object as? TLCustomizerDragItem {
                        DispatchQueue.main.async {
                            let manager = self.delegate as! TLManager
                            manager.assignTabBarItem(item: dragItem.item!, atIndex: idx)
                        }
                    }
                })
            }
        }
    }
}

