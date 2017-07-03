//
//  TopBottomAnimation.swift
//  SwiftMessages
//
//  Created by Timothy Moose on 6/4/17.
//  Copyright © 2017 SwiftKick Mobile. All rights reserved.
//

import UIKit

public class TopBottomAnimation: NSObject, Animator {
    
    enum Direction {
        case fromTop
        case fromBottom
    }
    
    //Animation Style
    public enum Style {
        //No animation
        case appear
        //Linear animation
        case slide
        //Spring animation
        case bounce
        //Alpha Animation
        case fade
        
        //Animation Speed
        public enum Speed {
            //1s
            case slow
            //0.55s
            case medium
            //0.35s //default
            case fast
            //sets animationDuration
            case custom
        }
    }
    
    public weak var delegate: AnimationDelegate?
    
    var direction: Direction
    
    var translationConstraint: NSLayoutConstraint! = nil
    
    weak var messageView: UIView?
    
    weak var containerView: UIView?
    
    
    var viewHeight: CGFloat = 0.0
    
    public var animationDuration :TimeInterval = 0.75
    public var animateOutSpeed: Style.Speed = .medium
    public var animateInSpeed: Style.Speed = .slow
    public var animationStyle: Style = .bounce
    
    var animationSpeed: Style.Speed = .medium {
        didSet {
            switch animationSpeed {
            case .slow: animationDuration = 0.75
            case .medium: animationDuration = 0.45
            case .fast: animationDuration = 0.2
            default: break
            }
        }
    }
    
    
    init(direction: Direction, delegate: AnimationDelegate) {
        self.direction = direction
        self.delegate = delegate
    }
    
    public func show(context: AnimationContext, completion: @escaping AnimationCompletion) {
        install(context: context)
        animationSpeed = .medium
        animateInWith(animationStyle, completion: completion)
    }
    
    public func hide(context: AnimationContext, completion: @escaping AnimationCompletion) {
        let view = context.messageView
        let container = context.containerView
        animateViewOut(view, in: container, completion: completion)
    }
    
    func install(context: AnimationContext) {
        let view = context.messageView
        let container = context.containerView
        messageView = view
        viewHeight = -(messageView?.bounds.height)!
        containerView = container
        if let adjustable = context.messageView as? MarginAdjustable {
            bounceOffset = adjustable.bounceAnimationOffset
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        let leading = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.00, constant: 0.0)
        let trailing = NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.00, constant: 0.0)
        switch direction {
        case .fromTop:
            translationConstraint = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.00, constant: viewHeight)
        case .fromBottom:
            translationConstraint = NSLayoutConstraint(item: container, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.00, constant: 0.0)
        }
        container.addConstraints([leading, trailing, translationConstraint])
        if let adjustable = view as? MarginAdjustable {
            var top: CGFloat = 0.0
            var bottom: CGFloat = 0.0
            switch direction {
            case .fromTop:
                top += adjustable.bounceAnimationOffset
                if context.behindStatusBar {
                    top += adjustable.statusBarOffset
                }
            case .fromBottom:
                bottom += adjustable.bounceAnimationOffset
            }
            view.layoutMargins = UIEdgeInsets(top: top, left: 0.0, bottom: bottom, right: 0.0)
        }
        let size = view.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        translationConstraint.constant -= size.height
        container.layoutIfNeeded()
        if context.interactiveHide {
            let pan = UIPanGestureRecognizer()
            pan.addTarget(self, action: #selector(pan(_:)))
            if let view = view as? BackgroundViewable {
                view.backgroundView.addGestureRecognizer(pan)
            } else {
                view.addGestureRecognizer(pan)
            }
        }
    }
    
    fileprivate var bounceOffset: CGFloat = 5
    func animateInWith(_ style:Style , completion: @escaping AnimationCompletion) {
        animationSpeed = animateInSpeed
        if style == .bounce {
            bounceAnimateIn(completion: completion)
        }
        else if style == .fade {
            fadeAnimateIn(completion: completion)
        }
        else if style == .slide {
            slideAnimateIn(completion: completion)
        }
    }
    
    func animateViewOut(_ view:UIView, in container:UIView, completion: @escaping AnimationCompletion) {
        animationSpeed = animateOutSpeed
        self.animationStyle = .slide
        if self.animationStyle == .fade {
            fadeAnimateOut(completion: completion)
        }
        else {
            slideAnimateViewOut(view, from: container, completion: completion)
        }
    }
    
    func bounceAnimateIn(completion: @escaping AnimationCompletion) {
        guard let container = containerView else {
            completion(false)
            return
        }
        let animationDistance = self.translationConstraint.constant + bounceOffset
        // Cap the initial velocity at zero because the bounceOffset may not be great
        // enough to allow for greater bounce induced by a quick panning motion.
        //        let initialSpringVelocity = animationDistance == 0.0 ? 0.0 : min(0.0, closeSpeed / animationDistance)
        UIView.animate(withDuration: animationDuration, delay: 1.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.25, options: [.beginFromCurrentState, .curveLinear, .allowUserInteraction], animations: {
            self.translationConstraint.constant = -self.bounceOffset
            container.layoutIfNeeded()
        }, completion: { completed in
            completion(completed)
        })
    }
    
    func slideAnimateIn(completion: @escaping AnimationCompletion) {
        guard let container = containerView else {
            completion(false)
            return
        }
        UIView.animate(withDuration: animationDuration, delay: 1.0, options: [.curveLinear, .allowUserInteraction], animations: {
            self.translationConstraint.constant = 0
            container.layoutIfNeeded()
        }) { (completed) in
            completion(completed)
        }
    }
    
    
    func slideAnimateViewOut(_ view:UIView, from container:UIView, completion: @escaping AnimationCompletion) {
        UIView.animate(withDuration: animationDuration, delay: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
            let offset = view.bounds.height
            self.translationConstraint.constant = self.viewHeight
            container.layoutIfNeeded()
        }, completion: { completed in
            completion(completed)
        })
    }
    
    func fadeAnimateIn(completion: @escaping AnimationCompletion) {
        guard let container = containerView else {
            completion(false)
            return
        }
        self.translationConstraint.constant = -self.bounceOffset
        self.messageView?.alpha = 0.0
        container.layoutIfNeeded()
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.messageView?.alpha = 1.0
        }) { (completed) in
            completion(completed)
        }
    }
    
    func fadeAnimateOut(completion: @escaping AnimationCompletion) {
        UIView.animate(withDuration: animationDuration, delay: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
            self.messageView?.alpha = 0.0
        }, completion: { completed in
            completion(completed)
        })
    }
    
    
    /*
     MARK: - Pan to close
     */
    
    fileprivate var closing = false
    fileprivate var closeSpeed: CGFloat = 0.0
    fileprivate var closePercent: CGFloat = 0.0
    fileprivate var panTranslationY: CGFloat = 0.0
    
    @objc func pan(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .changed:
            guard let view = pan.view else { return }
            let height = view.bounds.height - bounceOffset
            if height <= 0 { return }
            let point = pan.location(ofTouch: 0, in: view)
            var velocity = pan.velocity(in: view)
            var translation = pan.translation(in: view)
            if case .fromTop = direction {
                velocity.y *= -1.0
                translation.y *= -1.0
            }
            if !closing {
                if view.bounds.contains(point) && velocity.y > 0.0 && velocity.x / velocity.y < 5.0 {
                    closing = true
                    pan.setTranslation(CGPoint.zero, in: view)
                    delegate?.panStarted(animator: self)
                }
            }
            if !closing { return }
            let translationAmount = -bounceOffset - max(0.0, translation.y)
            translationConstraint.constant = translationAmount
            closeSpeed = velocity.y
            closePercent = translation.y / height
            panTranslationY = translation.y
        case .ended, .cancelled:
            if closeSpeed > 750.0 || closePercent > 0.33 {
                delegate?.hide(animator: self)
            } else {
                closing = false
                closeSpeed = 0.0
                closePercent = 0.0
                panTranslationY = 0.0
                animateInWith(animationStyle, completion: {[weak self] (completed)  in
                    self?.delegate?.panEnded(animator: self!)
                })
            }
        default:
            break
        }
    }
}
