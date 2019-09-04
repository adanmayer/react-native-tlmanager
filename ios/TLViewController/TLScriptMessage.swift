import WebKit

enum TLScriptMessageName: String {
    case ClientInitialized = "clientInitialized"
    case ExecuteAction     = "executeAction"
    case Notification      = "notification"
    case ErrorRaised       = "errorRaised"
    case NotHandled        = "notHandled"
}

public enum TLAction: String {
    case Advance = "advance"
    case Replace = "replace"
    case Restore = "restore"
}

class TLScriptMessage {
    let name: TLScriptMessageName
    let data: [String: AnyObject]
    
    init(name: TLScriptMessageName, data: [String: AnyObject]) {
        self.name = name
        self.data = data
    }
    
    var identifier: String? {
        return data["identifier"] as? String
    }
    
    var restorationIdentifier: String? {
        return data["restorationIdentifier"] as? String
    }
    
    var location: URL? {
        if let locationString = data["location"] as? String {
            return URL(string: locationString)
        }
        
        return nil
    }
    
    var action: TLAction? {
        if let actionString = data["action"] as? String {
            return TLAction(rawValue: actionString)
        }
        
        return nil
    }
    
    static func parse(_ message: WKScriptMessage) -> TLScriptMessage? {
        guard let body = message.body as? [String: AnyObject],
            let rawName = body["name"] as? String, let name = TLScriptMessageName(rawValue: rawName),
            let data = body["data"] as? [String: AnyObject] else { return nil }
        return TLScriptMessage(name: name, data: data)
    }
}
