//
//  ScrollViewDelegateProxy.swift
//  NestedScrollView
//
//  Created by Andrey Yoshua Manik on 19/03/20.
//  Copyright © 2020 Brid. All rights reserved.
//

import UIKit

protocol ScrollViewDelegate: class {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollView(_ scrollView: UIScrollView,
                           willEndDraggingwithVelocity velocity: CGPoint,
                           targetContentOffset: UnsafeMutablePointer<CGPoint>)
}


internal class ScrollViewDelegateProxy: NSObject, UIScrollViewDelegate {

    private var scrollViewObservation: NSKeyValueObservation?
    private weak var originalDelegate: UIScrollViewDelegate?
    private weak var scrollView: UIScrollView?
    private weak var delegate: UIScrollViewDelegate?

    // MARK: - Life Cycle

    deinit {
        cancelForwarding()
    }

    // MARK: - NSObject

    override func responds(to aSelector: Selector!) -> Bool {
        let originalDelegateRespondsToSelector = originalDelegate?.responds(to: aSelector) ?? false
        return super.responds(to: aSelector) || originalDelegateRespondsToSelector
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if originalDelegate?.responds(to: aSelector) == true {
            return originalDelegate
        } else {
            return super.forwardingTarget(for: aSelector)
        }
    }

    // MARK: - Public

    func cancelForwarding() {
        cancelForwarding(restoresDelegate: true)
    }

    func forward(to delegate: UIScrollViewDelegate, delegateInvocationsFrom scrollView: UIScrollView) {
        guard !(scrollView.delegate === self) else { return }
        cancelForwarding()
        self.delegate = delegate
        self.originalDelegate = scrollView.delegate
        self.scrollView = scrollView
        scrollView.delegate = self
        scrollViewObservation = scrollView.observe(\.delegate) { [weak self] (scrollView, delegate) in
            guard !(scrollView.delegate === self) else { return }
            if let proxy = scrollView.delegate as? ScrollViewDelegateProxy {
                proxy.originalDelegate = self?.originalDelegate
                self?.cancelForwarding(restoresDelegate: false)
            } else {
                self?.originalDelegate = scrollView.delegate
                self?.scrollView = scrollView
                scrollView.delegate = self
            }
        }
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidScroll?(scrollView)
        originalDelegate?.scrollViewDidScroll?(scrollView)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity.multiply(by: -1000), targetContentOffset: targetContentOffset)
        originalDelegate?.scrollViewWillEndDragging?(
            scrollView,
            withVelocity: velocity,
            targetContentOffset: targetContentOffset
        )
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.scrollViewWillBeginDragging?(scrollView)
        originalDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
        originalDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidEndDecelerating?(scrollView)
        originalDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    private func cancelForwarding(restoresDelegate: Bool) {
        scrollViewObservation?.invalidate()
        guard restoresDelegate else { return }
        scrollView?.delegate = originalDelegate
    }
}

extension CGPoint {
    func offset(by point: CGPoint) -> CGPoint {
        return offsetBy(dx: point.x, dy: point.y)
    }

    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: x + dx, y: y + dy)
    }

    func multiply(by multiplier: CGFloat) -> CGPoint {
        return multiplyBy(dx: multiplier, dy: multiplier)
    }

    func multiplyBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: x * dx, y: y * dy)
    }
}
