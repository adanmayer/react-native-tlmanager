//
//  String+Extension.swift
//  CustomNavigation
//
//  Created by Alexander Danmayer on 11.12.18.
//  Copyright © 2018 Alexander Danmayer. All rights reserved.
//

import UIKit

let ellipsis:String = "…"

extension String {
    
    func stringByTruncatingToWidth(_ width: CGFloat, font: UIFont) -> String {
        var truncatedString = self
        if (self.size(withAttributes: [NSAttributedString.Key.font: font]).width > width) {
            truncatedString = ""
            let endString = NSString.init(string: ellipsis)
            let maxWidth = width - endString.size(withAttributes: [NSAttributedString.Key.font: font]).width
            if (maxWidth > 0) {
                truncatedString = String(self.dropLast())
                while (truncatedString.count > 0 && truncatedString.size(withAttributes: [NSAttributedString.Key.font: font]).width > maxWidth) {
                    truncatedString = String(truncatedString.dropLast())
                }
                if truncatedString.count > 0 {
                    truncatedString = "\(truncatedString)\(ellipsis)"
                }
            }
        }
        return truncatedString
    }
    
}
