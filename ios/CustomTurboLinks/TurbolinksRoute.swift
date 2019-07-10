import UIKit
import Turbolinks

public enum RequestSource : String {
    case generic
    case tabBar
    case replaceLink
    case subPageLink
}

public class TurbolinksRoute {
    public var title: String?
    public var subtitle: String?
    public var titleImage: UIImage?
    public var action: Action?
    public var source: RequestSource
    public var url: URL?
    public var actionButtons: Array<Dictionary<AnyHashable, String>>?
    public var leftButton: Dictionary<AnyHashable, String>?
    public var popToRoot: Bool

    #if RCT_PROFILE

    init(_ route: Dictionary<AnyHashable, Any>) {
        let action = RCTConvert.nsString(route["action"])
        let source = RCTConvert.nsString(route["source"])
        self.title = RCTConvert.nsString(route["title"])
        self.subtitle = RCTConvert.nsString(route["subtitle"])
        self.titleImage = RCTConvert.uiImage(route["titleImage"])
        self.action = Action(rawValue: action ?? "advance")!
        self.url = RCTConvert.nsurl(route["href"])
        self.leftButton = RCTConvert.nsDictionary(route["leftButton"])
        self.actionButtons = RCTConvert.nsDictionaryArray(route["actionButtons"])
        self.popToRoot = RCTConvert.bool(root["popToRoot"])
        self.source = RequestSource(rawValue: source ?? "generic")!
    }

    #else

    init(_ route: Dictionary<AnyHashable, Any>) {
        let action = route["action"] as? String
        let source = route["source"] as? String
        self.title = route["title"] as? String
        self.subtitle = route["subtitle"] as? String
        self.titleImage = route["titleImage"] as? UIImage
        self.action = Action(rawValue: action ?? "advance")!
        self.url = URL.init(string: route["href"] as! String)
        self.leftButton = route["leftButton"] as? Dictionary<AnyHashable, String>
        self.actionButtons = route["actionButtons"] as? Array<Dictionary<AnyHashable, String>>
        self.popToRoot = (route["popToRoot"] as? Bool) ?? false
        self.source = RequestSource(rawValue: source ?? "generic")!
    }

    #endif
}
