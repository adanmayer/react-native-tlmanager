import UIKit

class TurbolinksMenuItem {
    
    var id: Int
    var title: String?
    var icon: UIImage?
    var button: Bool = false

    
    #if RCT_PROFILE
    init(_ action: Dictionary<AnyHashable, Any>) {
        self.id = RCTConvert.nsInteger(action["id"])
        self.title = RCTConvert.nsString(action["title"])
        self.icon = RCTConvert.uiImage(action["icon"])
        self.button = RCTConvert.bool(action["button"])
    }
    #else
    init(_ menuItem: Dictionary<AnyHashable, Any>) {
        self.id = menuItem["id"] as! Int
        self.title = menuItem["title"] as? String
        self.icon = menuItem["icon"] as? UIImage
        self.button = menuItem["button"] as! Bool
    }
    #endif

}
