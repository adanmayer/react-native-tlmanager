//
//  TLManager+WebViewDeletage.swift
//  RNTLWebView
//
//  Created by Alexander Danmayer on 26.02.19.
//  Copyright © 2019 Faria. All rights reserved.
//
import WebKit
import Turbolinks

extension TLManager: MsgBridgeDelegate {

    public func webView(_ sender: NSObject, webView: WebView, executeActionWithData data: Dictionary<String, AnyObject>, completion: (() -> Void)? = nil) {
        defaultExecuteActionWithData(data, completion: completion)
    }
    
    public func webView(_ sender: NSObject, webView: WebView, notificationWithData data: Dictionary<String, AnyObject>) {
        defaultNotificationWithData(data)
    }
}

extension TLManager: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let msg = TLScriptMessage.parse(message) ?? TLScriptMessage(name: .NotHandled, data: [:])
        //print("\(msg.name): \(msg.data)")
        if self.navigation != nil {
            switch msg.name {
            case .ExecuteAction:
                webView(self, webView: self.navSession.webView, executeActionWithData: msg.data)
            case .Notification:
                webView(self, webView: self.navSession.webView, notificationWithData: msg.data)
            case .ClientInitialized:
                print("clientInitialized")
            case .NotHandled:
                print("not handled!")
            }
        }
    }
}
