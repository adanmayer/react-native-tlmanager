import WebKit
import Turbolinks

public protocol MsgBridgeDelegate: class {
    func webView(_ sender: NSObject, webView: WebView, executeActionWithData data: Dictionary<String, AnyObject>, completion: (() -> Void)?)
    func webView(_ sender: NSObject, webView: WebView, notificationWithData data: Dictionary<String, AnyObject>)
}

open class TLWebView: WebView {
    public weak var msgBridgeDelegate: MsgBridgeDelegate?
    
    public override init(configuration: WKWebViewConfiguration) {
        super.init(configuration: configuration)
        
        let bundle = Bundle(for: type(of: self))
        let source = try! String(contentsOf: bundle.url(forResource: "TLWebView", withExtension: "js")!, encoding: String.Encoding.utf8)
        let userScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        self.configuration.userContentController.addUserScript(userScript)

        self.configuration.userContentController.removeScriptMessageHandler(forName: "MsgBridge")
        self.configuration.userContentController.add(self, name: "MsgBridge")

        if #available(iOS 11, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
	
	deinit {
		print("deinit")
	}
	
	public func releaseRessources() {
		self.configuration.userContentController.removeAllUserScripts()
		self.configuration.userContentController.removeScriptMessageHandler(forName: "turbolinks")
		self.configuration.userContentController.removeScriptMessageHandler(forName: "MsgBridge")
	}
    
    // MARK: JavaScript Evaluation
    
    private func callJavaScriptFunction(_ functionExpression: String, withArguments arguments: [AnyObject?] = [], completionHandler: ((AnyObject?) -> ())? = nil) {
        guard let script = scriptForCallingJavaScriptFunction(functionExpression, withArguments: arguments) else {
            NSLog("Error encoding arguments for JavaScript function `%@'", functionExpression)
            return
        }
        
        evaluateJavaScript(script) { (result, error) in
            if let result = result as? [String: AnyObject] {
                if let error = result["error"] as? String, let stack = result["stack"] as? String {
                    NSLog("Error evaluating JavaScript function `%@': %@\n%@", functionExpression, error, stack)
                } else {
                    completionHandler?(result["value"])
                }
            } else if let error = error {
                self.delegate?.webView(self, didFailJavaScriptEvaluationWithError: error as NSError)
            }
        }
    }
    
    private func scriptForCallingJavaScriptFunction(_ functionExpression: String, withArguments arguments: [AnyObject?]) -> String? {
        guard let encodedArguments = encodeJavaScriptArguments(arguments) else { return nil }
        
        return
            "(function(result) {\n" +
                "  try {\n" +
                "    result.value = " + functionExpression + "(" + encodedArguments + ")\n" +
                "  } catch (error) {\n" +
                "    result.error = error.toString()\n" +
                "    result.stack = error.stack\n" +
                "  }\n" +
                "  return result\n" +
        "})({})"
    }
    
    private func encodeJavaScriptArguments(_ arguments: [AnyObject?]) -> String? {
        let arguments = arguments.map { $0 == nil ? NSNull() : $0! }
        
        if let data = try? JSONSerialization.data(withJSONObject: arguments, options: []),
            let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String? {
            let startIndex = string.index(after: string.startIndex)
            let endIndex = string.index(before: string.endIndex)
            return String(string[startIndex..<endIndex])
        }
        
        return nil
    }

    override open func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let msg = TLScriptMessage.parse(message) ?? TLScriptMessage(name: .NotHandled, data: [:])
        switch msg.name {
        case .ClientInitialized:
            print("clientInitialized")
        case .ExecuteAction:
            msgBridgeDelegate?.webView(self, webView: self, executeActionWithData : msg.data, completion: nil)
        case .Notification:
            msgBridgeDelegate?.webView(self, webView: self, notificationWithData: msg.data)
        case .NotHandled:
            super.userContentController(userContentController, didReceive: message)
        }
        
    }
}
