//
//  CustomizerViewModel.swift
//  CustomNavigation
//
//  Created by Alexander Danmayer on 29.11.18.
//  Copyright © 2018 Alexander Danmayer. All rights reserved.
//

import UIKit

class TLCustomizerDragItem : NSObject, Codable, NSItemProviderReading, NSItemProviderWriting {
    static var readableTypeIdentifiersForItemProvider: [String] = ["CustomizerDragItem"]
    static var writableTypeIdentifiersForItemProvider: [String] = ["CustomizerDragItem"]
    
    var item: Dictionary<String, String>?
    
    enum CodingKeys: String, CodingKey {
        case item
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(item, forKey: .item)
    }

    override init() {
        super.init()
    }
    
    convenience public init(item: Dictionary<String, String>) {
        self.init()
        self.item = item
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        item = try values.decode(Dictionary<String, String>.self, forKey: .item)
    }
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 100)
        do {
            //Here the object is encoded to a JSON data object and sent to the completion handler
            let data = try JSONEncoder().encode(self)
            progress.completedUnitCount = 100
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        return progress
    }

    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        let decoder = JSONDecoder()
        do {
            //Here we decode the object back to it's class representation and return it
            let item = try decoder.decode(self, from: data)
            return item
        } catch {
            fatalError("Could not convert to customizerItem")
        }
    }
}

struct TLCustomizerViewModel {
    private(set) var items: [Dictionary<String, String>] = []
    private(set) var activeItems: [Dictionary<String, String>] = []
    private(set) var activeItemCount: Int
    
    mutating func initializeWith(availableItems: [Dictionary<String, String>], activeItems: [Dictionary<String, String>]?, activeCount: Int) {
        items = availableItems
        activeItemCount = activeCount
        if let items = activeItems {
            setActiveItems(Array(items.prefix(upTo: min(activeCount, items.count))))
        } else {
            self.activeItems = Array.init(repeating: [:], count: activeCount)
        }
    }
    
    mutating func setActiveItems(_ items: [Dictionary<String, String>]) {
        self.activeItems = Array(items.prefix(upTo: min(activeItemCount, items.count) ))
        while self.activeItems.count < activeItemCount {
            self.activeItems.append([:])
        }
    }
    
    mutating func setActive(itemAtIndex: Int, at: Int) {
        guard itemAtIndex >= 0 && itemAtIndex < items.count else {
            fatalError("Index out of bounds (setActive[items]): \(itemAtIndex)")
        }

        guard at >= 0 && at < activeItemCount else {
            fatalError("Index out of bounds (setActive[activeitem]): \(at)")
        }
        activeItems[at] = items[itemAtIndex]
    }
    
    func isActive(itemAtIndex: Int) -> Bool {
        guard itemAtIndex >= 0 && itemAtIndex < items.count else {
            fatalError("Index out of bounds (isActive[items]): \(itemAtIndex)")
        }
        
        return activeItems.contains(items[itemAtIndex])
    }
    
    // Method for drag
    func dragItem(itemAtIndex: IndexPath) -> [UIDragItem] {
        let dataItem = items[itemAtIndex.row]
        let item = TLCustomizerDragItem.init(item: dataItem)
        let itemProvider = NSItemProvider(object: item)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }
    
    // Method for drop
    //
    func canHandle(_ session: UIDropSession) -> Bool {
        // Only works with strings
        //
        return session.canLoadObjects(ofClass: TLCustomizerDragItem.self)
    }
}
