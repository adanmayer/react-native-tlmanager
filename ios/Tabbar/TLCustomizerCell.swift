//
//  TBCustomizerCell.swift
//  CustomNavigation
//
//  Created by Alexander Danmayer on 28.11.18.
//  Copyright © 2018 Alexander Danmayer. All rights reserved.
//

import UIKit

struct CustomizerCellDimensions {
    static let itemHeight: CGFloat =  55
    static let itemWidth: CGFloat = 80
    
    static let imageHeight: CGFloat = 20
    static let imageWidth: CGFloat = 20
    
    static let titleFontSize: CGFloat = 9

    //    static let equalSpacedCount: CGFloat = 4
    static let horizontalEdge: CGFloat = 15
    static let verticalEdge: CGFloat = 8
    static let horizontalInnerItemSpace: CGFloat = 4
    static let verticalInnerItemSpace: CGFloat = 7
    static let lineItemSpace: CGFloat = 18
    static let itemInnerSpacing: CGFloat = 4
}

class TLCustomizerHeaderView : UIView {
    var title : UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initialize() {
        if (title == nil) {
            title = UILabel.init(frame: CGRect(origin: .zero, size: frame.size))
            title.textAlignment = .left
            title.adjustsFontSizeToFitWidth = false
            title.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
            title.textColor = UIColor.gray
            title.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(title)
            
            NSLayoutConstraint.activate([
                title.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -12),
                title.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15)])
        }
    }
}

class TLCustomizerFooterView : UIView {
    var title : UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initialize() {
        if (title == nil) {
            title = UILabel.init(frame: CGRect(origin: .zero, size: frame.size))
            title.textAlignment = .left
            title.adjustsFontSizeToFitWidth = false
            title.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
            title.textColor = UIColor.gray
            title.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(title)
            
            NSLayoutConstraint.activate([
                title.topAnchor.constraint(equalTo: self.topAnchor, constant: 12),
                title.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15)])
        }
    }
}

class TLCustomizerCell : UICollectionViewCell {
    var title : UILabel!
    var image : UIImageView!
    var badgeLabel: EdgeInsetLabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func assignImageFromSVGString(_ str: String?) {
        image.image = (UIApplication.shared.delegate as! TLManagerAppDelegate).imageFromString(str, size: CGSize(width: CustomizerCellDimensions.imageWidth, height: CustomizerCellDimensions.imageHeight), fallbackAsset: nil)
    }
    
    func initialize() {
        if (image == nil) {
            image = UIImageView(frame: CGRect(origin: .zero, size: frame.size))
            image.translatesAutoresizingMaskIntoConstraints = false
            image.contentMode = .scaleAspectFit
            self.contentView.addSubview(image)
            NSLayoutConstraint.activate([
                image.topAnchor.constraint(equalTo: contentView.topAnchor, constant: CustomizerCellDimensions.verticalEdge),
                image.heightAnchor.constraint(equalToConstant: CustomizerCellDimensions.imageHeight),
                image.widthAnchor.constraint(equalToConstant: CustomizerCellDimensions.imageWidth),
                image.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
                ])
        }
        
        if (title == nil) {
            title = UILabel.init(frame: CGRect(origin: .zero, size: frame.size))
            title.textAlignment = .center
            title.numberOfLines = 1
            title.lineBreakMode = .byTruncatingTail
            title.adjustsFontSizeToFitWidth = false
            title.font = UIFont.systemFont(ofSize: CustomizerCellDimensions.titleFontSize)
            title.textColor = UIColor.black
            title.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(title)
            
            NSLayoutConstraint.activate([
                title.topAnchor.constraint(equalTo: image.bottomAnchor, constant: CustomizerCellDimensions.verticalInnerItemSpace),
                title.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -CustomizerCellDimensions.itemInnerSpacing),
                title.leftAnchor.constraint(equalTo:contentView.leftAnchor, constant: CustomizerCellDimensions.itemInnerSpacing),
                ])
        }
        
        if (badgeLabel == nil) {
            badgeLabel = EdgeInsetLabel.init(frame: CGRect(origin: .zero, size: frame.size))
            badgeLabel.textAlignment = .center
            badgeLabel.backgroundColor = UIColor.red
            badgeLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
            badgeLabel.textColor = UIColor.white
            badgeLabel.clipsToBounds = true
            badgeLabel.layer.cornerRadius = badgeLabel.font.pointSize * 1.3 / 2
            badgeLabel.translatesAutoresizingMaskIntoConstraints = false
            badgeLabel.textInsets = UIEdgeInsets(top: 1, left: 4, bottom: 1, right: 4)
            badgeLabel.text = nil
            self.contentView.addSubview(badgeLabel)
            
            NSLayoutConstraint.activate([
                badgeLabel.topAnchor.constraint(equalTo: image.topAnchor, constant: -5),
                badgeLabel.leftAnchor.constraint(equalTo: image.rightAnchor, constant: -4 * 2)
                ])
        }
        
		self.contentView.backgroundColor = nil
    }
    
    var isActive: Bool = false {
        didSet{
            self.initColors()
        }
    }
    
    func initColors() {
        if self.isActive {
            image.alpha = 0.3
            title.textColor = UIColor.gray
            badgeLabel.backgroundColor = UIColor.lightGray
        } else {
            image.alpha = 1.0
            title.textColor = UIColor.black
            badgeLabel.backgroundColor = UIColor.red
        }
    }
}

