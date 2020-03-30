//
//  BottomSheetViewController.swift
//  NestedScrollView
//
//  Created by Andrey Yoshua Manik on 19/03/20.
//  Copyright © 2020 Brid. All rights reserved.
//

import UIKit
import FLEX

public protocol BottomSheetContent: UIViewController {
    var scrollView: UIScrollView? { get }
    func maximumNotchHeightWithAvailableSpace(_ availableSpace: CGFloat) -> CGFloat
    func minimumNotchHeightWithAvailableSpace(_ availableSpace: CGFloat) -> CGFloat
}

public final class BottomSheetViewController: UIViewController {
    
    private let content: BottomSheetContent
    
    private let containerView = NestedScrollView()
    private lazy var containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 0)
    private var containerHeight: CGFloat {
        return containerHeightConstraint.constant
    }
    private let containerDelegateProxy = ScrollViewDelegateProxy()
    
    fileprivate var lastContentOffsetWhileScrolling: CGPoint = .zero
    fileprivate var scrollViewTranslation: CGFloat = 0
    fileprivate var bottomSheetTranslation: CGFloat = 0
    fileprivate var destination: CGFloat = 0
    
    private var containerHeightObserver: NSKeyValueObservation?
    
    public init(content: BottomSheetContent) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }
    
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        view = PassThroughView()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        FLEXManager.shared().showExplorer()
        view.addSubview(containerView)
        containerView.pinToSuperview(edges: [.left, .bottom, .right])
        containerHeightConstraint.isActive = true
        
        addChild(content)
        containerView.addView(content.view)
        content.didMove(toParent: self)
        
        if let _ = content.view as? NestedScrollView {
            containerDelegateProxy.forward(to: self, delegateInvocationsFrom: containerView)
        } else if let contentScrollView = content.scrollView {
            containerDelegateProxy.forward(to: self, delegateInvocationsFrom: contentScrollView)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupGestureToContentView()
        setupContentAndContainerView()
        animateThePresenceOfBottomSheet()
    }
    
    private func setupGestureToContentView() {
        let panGesture = ScrollViewCaringGestureRecognizer(target: self, action: #selector(contentPanned(_:)))
        if let _ = content.view as? NestedScrollView {
            panGesture.drivingScrollView = containerView
        } else if let contentScrollView = content.scrollView {
            panGesture.drivingScrollView = contentScrollView
        }
        content.view.addGestureRecognizer(panGesture)
    }
    
    @objc
    private func contentPanned(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: nil)
        let velocity = gesture.velocity(in: nil)
        print(velocity)
        switch gesture.state {
        case .changed:
            let newHeight = self.destination - translation.y
            containerHeightConstraint.constant = max(max(minimumReachableNotchHeight, min(newHeight, maximumReachableNotchHeight)), 0)
        case .ended:
            goToNearestNotch()
        default:
            break
        }
    }
    
    private func animateThePresenceOfBottomSheet() {
        UIView.animate(withDuration: 0.3) {
            self.containerHeightConstraint.constant = self.content.minimumNotchHeightWithAvailableSpace(self.view.frame.height)
            self.destination = self.containerHeight
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupContentAndContainerView() {
//        content.view.roundCorners(corners: [.topLeft, .topRight], radius: 20)
        
        content.view.layer.backgroundColor = UIColor.clear.cgColor
        content.view.clipsToBounds = true
        content.view.layer.masksToBounds = true
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowOffset = CGSize(width: 0, height: -5)
        containerView.layer.shadowRadius = 7
        containerView.layer.cornerRadius = 20
//        containerView.layer.masksToBounds = false
        
    }
    
    public func showIn(vc: UIViewController) {
        vc.addChild(self)
        vc.view.addSubview(view)
        view.frame = vc.view.bounds
        didMove(toParent: vc)
    }
}

enum BottomSheetTranslationPosition {
    case top, bottom, inFlight, stationary
}

extension BottomSheetViewController: UIScrollViewDelegate {
    
    var maximumReachableNotchHeight: CGFloat {
        return content.maximumNotchHeightWithAvailableSpace(view.frame.height)
    }
    
    var minimumReachableNotchHeight: CGFloat {
        return content.minimumNotchHeightWithAvailableSpace(view.frame.height)
    }
    
    private func adjustedContentOffset(dragging scrollView: UIScrollView) -> CGPoint {
        var contentOffset = lastContentOffsetWhileScrolling
        let topInset = -scrollView.nsAdjustedContentInset.top
        switch translationPosition {
        case .inFlight, .top:
            // (gz) 2018-11-26 The user raised its finger in the top or in flight positions while scrolling bottom.
            // If the scroll's animation did not finish when the user translates the overlay,
            // the content offset may have exceeded the top inset. We adjust it.
            if contentOffset.y < topInset {
                contentOffset.y = topInset
            }
        case .bottom, .stationary:
            break
        }
        // (gz) 2018-11-26 Between two `overlayScrollViewDidScroll:` calls,
        // the scrollView exceeds the top's contentInset. We adjust the target.
        if (contentOffset.y - topInset) * (scrollView.contentOffset.y - topInset) < 0 {
            contentOffset.y = topInset
        }
        return contentOffset
    }
    
    var translationPosition: BottomSheetTranslationPosition {
        let isAtTop = containerHeight == maximumReachableNotchHeight
        let isAtBottom = containerHeight == minimumReachableNotchHeight
        if isAtTop && isAtBottom {
            return .stationary
        }
        if isAtTop {
            return .top
        } else if isAtBottom {
            return .bottom
        } else {
            return .inFlight
        }
    }

    private func shouldDragOverlay(following scrollView: UIScrollView) -> Bool {
        guard scrollView.isTracking else { return false }
        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView).y
        let movesUp = velocity < 0
        switch translationPosition {
        case .bottom:
            return !scrollView.isContentOriginInBounds && scrollView.scrollsUp
        case .top:
            return scrollView.isContentOriginInBounds && !movesUp
        case .inFlight:
            return scrollView.isContentOriginInBounds || scrollView.scrollsUp
        case .stationary:
            return false
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let maximumHeight = maximumReachableNotchHeight
        let minimumHeight = minimumReachableNotchHeight
        let previousTranslation = scrollViewTranslation
        scrollViewTranslation = scrollView.panGestureRecognizer.translation(in: scrollView).y
        if shouldDragOverlay(following: scrollView) {
            let offset = adjustedContentOffset(dragging: scrollView)
            lastContentOffsetWhileScrolling = offset
            scrollView.contentOffset = offset
            bottomSheetTranslation += scrollViewTranslation - previousTranslation
            let newHeight = max(max(minimumHeight, min(maximumHeight, self.destination - bottomSheetTranslation)), 0)
            guard newHeight != containerHeight else { return }
            containerHeightConstraint.constant = newHeight
        } else {
            lastContentOffsetWhileScrolling = scrollView.contentOffset
        }
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        print("Hahahaha", velocity, targetContentOffset.pointee)
        bottomSheetTranslation = 0
        scrollViewTranslation = 0
        scrollView.panGestureRecognizer.setTranslation(.zero, in: nil)
        // (gz) 2018-01-24 We adjust the content offset and the velocity only if the overlay will be dragged.
        switch translationPosition {
        case .bottom where targetContentOffset.pointee.y > -scrollView.nsAdjustedContentInset.top:
            // (gz) 2018-11-26 The user raises its finger in the bottom position
            // and the content offset will exceed the top content inset.
            targetContentOffset.pointee.y = -scrollView.nsAdjustedContentInset.top
        case .inFlight where !(containerHeight == minimumReachableNotchHeight || containerHeight == maximumReachableNotchHeight):
            targetContentOffset.pointee.y = lastContentOffsetWhileScrolling.y
        case .top, .bottom, .inFlight, .stationary:
            break
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        goToNearestNotch()
    }
    
    private func goToNearestNotch() {

        UIView.animate(withDuration: 0.2) {
            self.destination = self.containerHeight
            if self.maximumReachableNotchHeight - self.containerHeight < self.containerHeight - self.minimumReachableNotchHeight { // near maximum
                self.destination = self.maximumReachableNotchHeight
            } else if self.containerHeight - self.minimumReachableNotchHeight <= self.maximumReachableNotchHeight - self.containerHeight { // near minimum
                self.destination = self.minimumReachableNotchHeight
            }
            self.containerHeightConstraint.constant = self.destination
            self.view.layoutIfNeeded()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        goToNearestNotch()
    }
    
}

extension UIViewController {
    public func showBottomSheet(content: BottomSheetContent) -> BottomSheetViewController {
        let bottomSheet = BottomSheetViewController(content: content)
        
        return bottomSheet
    }
}

public class NyobaViewController: UIViewController, BottomSheetContent {
    private var nestedScrollView: NestedScrollView?
    public var scrollView: UIScrollView? {
        return nestedScrollView
    }
    
    public func maximumNotchHeightWithAvailableSpace(_ availableSpace: CGFloat) -> CGFloat {
        return availableSpace * 0.8
    }
    
    public func minimumNotchHeightWithAvailableSpace(_ availableSpace: CGFloat) -> CGFloat {
        return availableSpace * 0.3
    }
    
    public override func loadView() {
        nestedScrollView = NestedScrollView()
        view = nestedScrollView!
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
//        let label = UILabel(frame: CGRect(x: 10, y: 10, width: 100, height: 100))
//        label.text = "Hahahaha"
//        view.addSubview(label)
        
        view.backgroundColor = .yellow
        
//        nestedScrollView = NestedScrollView()
//        view.addSubview(nestedScrollView!)
//        nestedScrollView?.pinToSuperview()
        nestedScrollView?.setupContoh(count: 10)
    }
}
