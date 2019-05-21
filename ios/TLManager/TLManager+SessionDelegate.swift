//
//  SessionDelegate.swift
//  CustomNavigation
//
//  Created by Alexander Danmayer on 13.11.18.
//  Copyright © 2018 Alexander Danmayer. All rights reserved.
//

import Foundation
import Turbolinks

let turbolinksSanityScript = """
    Rails.toString();
    var _state = "unknown";
    if (Turbolinks.controller.currentVisit) {
        _state = Turbolinks.controller.currentVisit.state;
    } else {
        if (Turbolinks.controller.history.pageIsLoaded()) {
            _state = "completed";
        }
    }
    _state;
"""

extension TLManager: SessionDelegate {
    public func session(_ session: Session, didProposeVisitToURL URL: URL, withAction action: Action) {
        if (!self.session(session, preProcessingForURL: URL)) {
            sendEvent(withName: "turbolinksVisit", body: ["href": URL.absoluteString, "path": URL.path, "action": action.rawValue])
        }
    }
    
    public func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        // ignore errors for blank page
        if visitable.visitableURL.absoluteString != "about:blank" {
            visitable.visitableView.hideActivityIndicator()
            let statusCode: Int = error.userInfo["statusCode"] as? Int ?? 0

            if let webView = visitable.visitableView.webView, error.domain == "com.basecamp.Turbolinks" {
                webView.evaluateJavaScript(turbolinksSanityScript) { requestState, jsError in
                    let noContent = (jsError != nil) || ((requestState as? String) != "completed") || ((statusCode >= 400) && (statusCode <= 599));
                    (visitable.visitableViewController as? TLViewController)?.hasContent = (!noContent)
                    DispatchQueue.main.async {
                        self.sendEvent(withName: "turbolinksError", body: ["code": error.code,
                                                                           "statusCode": statusCode,
                                                                           "description": error.localizedDescription, "noContent": noContent])
                    }
                }
            } else {
                let noContent = ((statusCode >= 400) && (statusCode <= 599));
                self.sendEvent(withName: "turbolinksError", body: ["code": error.code,
                                                                   "statusCode": statusCode,
                                                                   "description": error.localizedDescription, "noContent": noContent])
            }
        }
    }
    
    public func session(_ session: Session, openExternalURL URL: URL) {
        if !(URL.absoluteString.starts(with: self.baseURLString ?? URL.absoluteString)) {
            UIApplication.shared.open(URL, options: [:], completionHandler: nil)
        } else {
            self.session(session, didProposeVisitToURL: URL, withAction: .Advance)
        }
    }
    
    public func session(_ session: Session, didRedirectToURL URL: URL) {
        sendEvent(withName: "turbolinksRedirect", body: ["href": URL.absoluteString, "path": URL.path])
    }

    public func session(_ session: Session, preProcessingForURL URL: URL) -> Bool {
        return defaultPreprocessingForURL(URL)
    }

    public func session(_ session: Session, postProcessingForResponse response: WKNavigationResponse) -> Bool {
        return defaultPostprocessingForResponse(response)
    }
    
    public func sessionDidStartRequest(_ session: Session) {
        application.isNetworkActivityIndicatorVisible = true
        (session.topmostVisitable?.visitableViewController as? TLViewController)?.hasContent = true
    }
    
    public func sessionDidFinishRequest(_ session: Session) {
        application.isNetworkActivityIndicatorVisible = false
        var url = session.webView.url
        if (url == nil) {
            url = URL.init(string: "/")!
        }
        
        sendEvent(withName: "turbolinksSessionFinished", body: ["href": url!.absoluteString, "path": url!.path])
    }
}
