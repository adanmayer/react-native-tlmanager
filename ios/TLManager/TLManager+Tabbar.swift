//
//  TLViewController+Toolbar.swift
//  CustomNavigation
//
//  Created by Alexander Danmayer on 20.11.18.
//  Copyright © 2018 Alexander Danmayer. All rights reserved.
//

import UIKit
import Turbolinks

let TLTabBarMaxCount = 4

extension TLManager : UITabBarDelegate {
    
    @objc public func showTabBarCustomizer() {
        if (customizerView == nil) && isTabBarDataAvailable() {
            navSession.webView.endEditing(true)
            let viewController = TLCustomizerViewController.init(manager: self)
            navigation.pushViewController(viewController, animated: true)
            customizerView = viewController
        }
    }
    
    func addTabBarView(toView view: UIView) {
        if (tabBar == nil) {
            tabBar = TLTabBar(frame: .zero)
            tabBar!.translatesAutoresizingMaskIntoConstraints = false
            tabBar!.items = []
            
            view.addSubview(tabBar!)

            let tabBarHeight : CGFloat  = 50.0
            let safeGuide = view.safeAreaLayoutGuide
            tabBar!.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            tabBar!.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            tabBar!.bottomAnchor.constraint(equalTo: safeGuide.bottomAnchor).isActive = true
            tabBar!.heightAnchor.constraint(equalToConstant: tabBarHeight).isActive = true
            
            let dropInteraction = UIDropInteraction(delegate: tabBar!)
            tabBar!.addInteraction(dropInteraction)

            if let vc = self.navigation.topViewController as? TLViewController {
                vc.updateScrollViewInsets()
            }
        }
    }
    
    func removeTabBar() {
        if (tabBar != nil) {
			print("removing TabBar")
            tabBar?.clearTabBarButtonViews()
            tabBar?.removeFromSuperview()
            tabBar = nil;
        }
    }
    
    func initTabbar(activeIds: Array<String>, defaultIds: Array<String>) {
        updateTabbar(activeIds: activeIds, defaultIds: defaultIds)
        tabBar?.delegate = self
    }
    
    func updateTabbar(activeIds: Array<String>, defaultIds: Array<String>) {
        var items = [Dictionary<String, String>]()
        for (id) in defaultIds {
            if let data = tabBarItemFor(id: id) {
                items.append(data)
            }
        }
        tabBarDefaultItems = items
        
        items = [Dictionary<String, String>]()
        for (id) in activeIds {
            if let data = tabBarItemFor(id: id) {
                items.append(data)
            }
        }
        
        // add empty tabBarItems
        if items.count < TLTabBarMaxCount {
            for _ in (items.count...TLTabBarMaxCount) {
                let emptyData = [
                    "id":       "placeholder-\(UUID().uuidString)",
                    "icon":     "empty",
                    "title":    "",
                    "href":     ""]
                items.append(emptyData)
            }
        }
        
        tabBarActiveItems = items
        updateTabBarItems()
    }
    
    func updateTabBarItems() {
        var items = [UITabBarItem]()
        if (tabBarActiveItems.count > 0) {
            for item in tabBarActiveItems[0...min(tabBarActiveItems.count - 1, (TLTabBarMaxCount - 1))] {
                let barItem = TLTabBar.createTabBarItem(withData: item, tag: tabBarActiveItems.firstIndex(of: item)!)
                items.append(barItem)
            }
        }
            
        let image = (UIApplication.shared.delegate as! TLManagerAppDelegate).imageFromString(menuIcon, size: CGSize(width: TabBarItemDimensions.imageWidth, height: TabBarItemDimensions.imageHeight), fallbackAsset: nil)
        
        items.insert(UITabBarItem(title: TLManager.i18NItem("menu"),
                                  image: image, tag: -1), at:0)
        let reselectMenu = (tabBar?.selectedItem?.tag == -1)
        tabBar?.items = items
        if (reselectMenu) {
            tabBar?.selectedItem = tabBar?.items?.last
            fadeSelection()
        } else {
            selectTabBarItemWith(url: self.navSession.topmostVisitable?.visitableURL ?? nil)
        }
    }
    
    func restoreDefaultItems() {
        self.tabBarActiveItems = self.tabBarDefaultItems
        customizerView?.updateActiveItems(self.tabBarDefaultItems)
        updateTabBarItems()
        notifyTabBarChange()
    }
    
    public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        // called when a new view is selected by the user (but not programatically)
        if (item.tag >= 0) {
            if let data = tabBarItemFor(tag: item.tag), data["href"] != "" {
                let url = URL.init(string: data["href"]!)!
                popToRoot()
                DispatchQueue.main.async {
                    self.sendEvent(withName: "turbolinksVisit", body: ["href": url.absoluteString, "path": url.path, "action": Action.Replace.rawValue])
                }
            }
        } else {
            DispatchQueue.main.async {
                self.sendEvent(withName: "turbolinksShowMenu", body: [:])
            }
        }
        fadeSelection()
    }
    
    func fadeSelection() {
        // hide selection again after 0.3 sec
        UIView.animate(withDuration: 0.2, delay: 0.3, options: [.curveEaseInOut], animations: {
            self.tabBar?.selectedItem = nil
        }, completion: nil)
    }
    
    func tabBarItemFor(tag: Int) -> Dictionary<String, String>? {
        if (tag>=0) && (tag < tabBarActiveItems.count) {
            return tabBarActiveItems[tag]
        }
        return nil
    }

    func tabBarItemFor(id: String) -> Dictionary<String, String>? {
        if let data = tabBarItems.first(where: {$0["id"] == id}) {
            return data
        }
        return nil
    }
    
    func selectTabBarItemWith(url: URL?) {
        if let url = url, ((tabBar != nil) && (tabBarActiveItems != nil)) {
            for item in tabBarActiveItems {
                if (url.relativePath == URL.init(string: item["href"] ?? "")?.relativePath) {
                    if let items = self.tabBar?.items {
                        if let index = tabBarActiveItems.index(of: item), (index + 1) < items.count {
                            tabBar?.selectedItem = items[index + 1]
                            fadeSelection()
                            return;
                        }
                    }
                }
            }
            // ignore dummy loading
            if (url.absoluteString != "about:blank") {
                tabBar?.selectedItem = nil
            }
        }
    }
    
    func dataItemForTabBarIndex(_ index: Int) -> Dictionary<String, String> {
        guard (index >= 0) && (index < tabBarActiveItems.count) else {
             fatalError("Index out of bounds (dataItemForTabBarIndex): \(index)") }
        
        return tabBarActiveItems[index]
    }
    
    func assignTabBarItem(item: Dictionary<String, String>, atIndex index: Int) {
        if let itemData = tabBarItemFor(id: item["id"]!) {
            // if item is already in list switch data
            if let oldIndex = tabBarActiveItems.firstIndex(of: itemData) {
                tabBarActiveItems[oldIndex] = tabBarActiveItems[index - 1]
                tabBarActiveItems[index - 1] = itemData
                updateTabBarItems()
            } else {
                var newItems = self.tabBar!.items!
				let newItem = TLTabBar.createTabBarItem(withData: itemData, tag: index - 1)
				newItems[index] = newItem
				tabBarActiveItems[index - 1] = itemData
                UIView.animate(withDuration: 0.2) {
                    self.tabBar?.items = newItems
                }
            }
			self.notifyTabBarChange()

			DispatchQueue.main.async {
                self.customizerView?.updateActiveItems(self.tabBarActiveItems)
            }
        }
    }
    
    func notifyTabBarChange() {
        var ids = [String]()
        for item in tabBarActiveItems { ids.append( item["id"] ?? "" ) }
        sendEvent(withName: "turbolinksActiveTabItemsChanged", body: ["ids": ids])
    }
}

