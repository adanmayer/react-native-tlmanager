//
//  TLTabBar.swift
//  CustomNavigation
//
//  Created by Alexander Danmayer on 12.12.18.
//  Copyright © 2018 Alexander Danmayer. All rights reserved.
//

import UIKit

open class TLTabBarItem: UITabBarItem {
    public var id: String?
}


open class TLTabBar : UITabBar, UIDropInteractionDelegate {
    open func createTabBarItem(withData item: Dictionary<String, String>, tag: Int) -> UITabBarItem {
        return UITabBarItem(title: item["title"] ?? "", image: UIImage.init(named: item["image"] ?? ""), tag: tag)
    }
    
    open func clearTabBarButtonViews() {
        // add cleanup here
    }
    
    open func defaultMenuBarImage(_ iconName: String) -> UIImage? {
        return UIImage.init(named: iconName)
    }
}

