//
//  SimpleFadeAnimator.swift
//  RNTLWebView
//
//  Created by Alexander Danmayer on 10.01.19.
//  Copyright © 2019 Faria. All rights reserved.
//

import Foundation

class SimpleFadeAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var popStyle: Bool = false
    var shiftView: UIView?
    
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.20
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if popStyle {
            animatePop(using: transitionContext)
        } else {
            animatePush(using: transitionContext)
        }
    }
    
    func animatePush(using transitionContext: UIViewControllerContextTransitioning) {
        let fz = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let tz = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        //let f = transitionContext.finalFrame(for: tz)
        //tz.view.frame = f.offsetBy(dx: 50, dy: 0)
        
        tz.view.alpha = 0.5
        transitionContext.containerView.insertSubview(tz.view, aboveSubview: fz.view)
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                tz.view.alpha = 1
        }, completion: {_ in
            transitionContext.completeTransition(true)
        })
    }
    
    func animatePop(using transitionContext: UIViewControllerContextTransitioning) {
        
        let fz = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let tz = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        //let f = transitionContext.finalFrame(for: tz)
        transitionContext.containerView.insertSubview(tz.view, belowSubview: fz.view)
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                fz.view.alpha = 0
                if let subView = self.shiftView {
                    subView.frame = subView.frame.offsetBy(dx: 50, dy: 0)
                }
                //fz.view.frame = f.offsetBy(dx: 50, dy: 0)
        }, completion: {_ in
            self.shiftView = nil
            transitionContext.completeTransition(true)
        })
    }
}
