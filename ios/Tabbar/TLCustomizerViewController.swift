//
//  TabbarCustomizer.swift
//  CustomNavigation
//
//  Created by Alexander Danmayer on 28.11.18.
//  Copyright © 2018 Alexander Danmayer. All rights reserved.
//

import UIKit

open class TLCustomizerViewController: CustomViewController {
    open func updateActiveItems(_ newItems: [Dictionary<String, String>]) {
        // update active items eg. during restore
    }
}

extension TLCustomizerViewController : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell.init(frame: .zero)
    }
}
    
