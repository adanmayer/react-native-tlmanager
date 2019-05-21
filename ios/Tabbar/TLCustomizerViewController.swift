//
//  TabbarCustomizer.swift
//  CustomNavigation
//
//  Created by Alexander Danmayer on 28.11.18.
//  Copyright © 2018 Alexander Danmayer. All rights reserved.
//

import UIKit

let customizerCellReuseIdentifier = "customizerCellIdentifer";
let customizerDescriptionCellReuseIdentifier = "customizerDescriptionCellIdentifier"

struct CustomizerDimensions {
    static let headerHeight: CGFloat = 67
    static let footerHeight: CGFloat = 61
    static let defaultButtonHeight: CGFloat = 44
}

class TLCustomizerViewController : CustomViewController {
    
    var model = TLCustomizerViewModel(items: [], activeItems: [], activeItemCount: 0)
    var heightConstraint: NSLayoutConstraint!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    public override init(manager: TLManager) {
        super.init(manager: manager)
        view.backgroundColor = UIColor(red:0.936, green:0.966, blue:0.999, alpha:1.000)
        self.manager = manager
        self.title = TLManager.i18NItem("menu-customization")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: TLManager.i18NItem("done"), style: .plain, target: self, action: #selector(doneCustomizing(_:)))
        model.initializeWith(availableItems: manager.tabBarItems, activeItems: manager.tabBarActiveItems, activeCount: 4)
        installCollectionView()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc func doneCustomizing(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func restoreDefaultItems(_ sender: Any) {
        manager.restoreDefaultItems()
    }
    
    func updateActiveItems(_ newItems: [Dictionary<String, String>]) {
        model.setActiveItems(manager.tabBarActiveItems)
        collectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.hidesBackButton = true
        super .viewWillAppear(animated)
        
        heightConstraint.constant = collectionViewHeight()
    }

    // MARK: Visitable View
    
    func collectionViewHeight() -> CGFloat {
        let orient = UIApplication.shared.statusBarOrientation
        var collectionHeight:CGFloat = 0
        switch orient {
        case .portrait:
            let height:CGFloat = ceil(CGFloat(model.items.count) / 4.0) * (CustomizerCellDimensions.itemHeight + CustomizerCellDimensions.lineItemSpace) + 15.0
            let tabBarHeight = (manager.tabBar != nil) ? manager.tabBar!.frame.height : 0
            let navigationHeight: CGFloat = 60.0
            collectionHeight = min(self.view.bounds.height - (CustomizerDimensions.footerHeight + CustomizerDimensions.headerHeight + CustomizerDimensions.defaultButtonHeight + tabBarHeight + navigationHeight), height)
        default:
            collectionHeight = (CustomizerCellDimensions.itemHeight + CustomizerCellDimensions.lineItemSpace) + 15.0
        }
        return collectionHeight
    }
    
    open private(set) lazy var collectionView: UICollectionView! = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.sectionInset = UIEdgeInsets(top: 15, left: 8, bottom: 0, right: 8)
        let view = UICollectionView(frame: self.view.bounds, collectionViewLayout: flowLayout)
        view.register(TLCustomizerCell.self, forCellWithReuseIdentifier: customizerCellReuseIdentifier)
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.dataSource = self
        view.delegate = self
        view.dragDelegate = self
        view.dragInteractionEnabled = true
        heightConstraint = view.heightAnchor.constraint(equalToConstant: collectionViewHeight())
        heightConstraint.isActive = true
        return view
    }()
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            let orient = UIApplication.shared.statusBarOrientation
            switch orient {
            case .portrait:
                (self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .vertical
                break
            default:
                (self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
                break
            }
            self.heightConstraint.constant = self.collectionViewHeight()
        }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
        })
        
        super .viewWillTransition(to: size, with: coordinator)
    }
    
    
    open private(set) lazy var headerView: TLCustomizerHeaderView! = {
        let view = TLCustomizerHeaderView(frame: CGRect.zero)
        view.initialize()
        view.title.text = TLManager.i18NItem("menu-tabs")
        view.title.font = UIFont.systemFont(ofSize: 15)
        view.title.textColor = UIColor(red:0.356, green:0.422, blue:0.527, alpha:1.000)
        view.heightAnchor.constraint(equalToConstant: CustomizerDimensions.headerHeight).isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    open private(set) lazy var footerView: TLCustomizerFooterView! = {
        let view = TLCustomizerFooterView(frame: CGRect.zero)
        view.initialize()
        view.title.text = TLManager.i18NItem("drag-info")
        view.title.textColor = UIColor(red:0.521, green:0.607, blue:0.733, alpha:1.000)
        view.heightAnchor.constraint(equalToConstant: CustomizerDimensions.footerHeight).isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    open private(set) lazy var restoreDefaultButton: UIButton! = {
        let view = UIButton(frame: CGRect.zero)
        view.setTitle(TLManager.i18NItem("menu-reset-default"), for: .normal)
        view.setTitleColor(UIColor(red:0.988, green:0.323, blue:0.332, alpha:1.000), for: .normal)
        view.setTitleColor(UIColor.gray, for: .highlighted)

        view.addTarget(self, action: #selector(restoreDefaultItems(_:)), for: UIControl.Event.touchUpInside)
        view.backgroundColor = UIColor.white
        view.heightAnchor.constraint(equalToConstant: CustomizerDimensions.defaultButtonHeight).isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: Visitable
    
    func installCollectionView() {
        
        view.addSubview(headerView)
        view.addSubview(collectionView)
        view.addSubview(footerView)
        view.addSubview(restoreDefaultButton)
        
        let safeGuide = view.safeAreaLayoutGuide
        headerView.topAnchor.constraint(equalTo: safeGuide.topAnchor).isActive = true
        headerView.leftAnchor.constraint(equalTo: safeGuide.leftAnchor).isActive = true
        headerView.rightAnchor.constraint(equalTo: safeGuide.rightAnchor).isActive = true

        collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: safeGuide.leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: safeGuide.rightAnchor).isActive = true
        //collectionView.bottomAnchor.constraint(equalTo: safeGuide.bottomAnchor).isActive = true
        
        footerView.topAnchor.constraint(equalTo: collectionView.bottomAnchor).isActive = true
        footerView.leftAnchor.constraint(equalTo: safeGuide.leftAnchor).isActive = true
        footerView.rightAnchor.constraint(equalTo: safeGuide.rightAnchor).isActive = true
        
        restoreDefaultButton.topAnchor.constraint(equalTo: footerView.bottomAnchor).isActive = true
        restoreDefaultButton.leftAnchor.constraint(equalTo: safeGuide.leftAnchor).isActive = true
        restoreDefaultButton.rightAnchor.constraint(equalTo: safeGuide.rightAnchor).isActive = true
    }
}


extension TLCustomizerViewController : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: Collection View delegate
    
    //UICollectionViewDatasource methods
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: customizerCellReuseIdentifier, for: indexPath) as! TLCustomizerCell
        cell.initialize()
        cell.title.text = model.items[indexPath.row]["title"]
        cell.badgeLabel.text = model.items[indexPath.row]["badgeValue"]
        cell.assignImageFromSVGString(model.items[indexPath.row]["icon"])
        cell.isActive = model.isActive(itemAtIndex: indexPath.row)
        cell.layer.masksToBounds = true;
        cell.layer.cornerRadius = 3;
        return cell as UICollectionViewCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: CustomizerCellDimensions.itemWidth, height: CustomizerCellDimensions.itemHeight)
    }
   
    //UICollectionViewDelegateFlowLayout methods
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return CustomizerCellDimensions.lineItemSpace;
    }
}

// Drag delegate
//
extension TLCustomizerViewController: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        collectionView.isScrollEnabled = false
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        collectionView.isScrollEnabled = true
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return model.dragItem(itemAtIndex: indexPath)
    }
    
}
