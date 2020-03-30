//
//  NestedScrollViewController.swift
//  NestedScrollView
//
//  Created by Andrey Yoshua Manik on 19/03/20.
//  Copyright © 2020 Brid. All rights reserved.
//

import UIKit

public class NestedScrollViewController: UIViewController {
    private var nested: NestedScrollView?
    public override func loadView() {
        nested = NestedScrollView()
        view = nested
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let nested = self.nested else {
            return
        }
        
    }
}


extension UIView {
    
    public func removeAllConstraints() {
        var _superview = self.superview

        while let superview = _superview {
            for constraint in superview.constraints {

                if let first = constraint.firstItem as? UIView, first == self {
                    superview.removeConstraint(constraint)
                }

                if let second = constraint.secondItem as? UIView, second == self {
                    superview.removeConstraint(constraint)
                }
            }

            _superview = superview.superview
        }

        self.removeConstraints(self.constraints)
        self.translatesAutoresizingMaskIntoConstraints = true
    }
    
    public func pinToSuperview(with insets: UIEdgeInsets = .zero, edges: UIRectEdge = .all) {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        if edges.contains(.top) {
            topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top).isActive = true
        }
        if edges.contains(.bottom) {
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom).isActive = true
        }
        if edges.contains(.left) {
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left).isActive = true
        }
        if edges.contains(.right) {
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -insets.right).isActive = true
        }
    }
    
    public func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}



extension UIPanGestureRecognizer {

    enum VerticalDirection {
        case up
        case down
        case none
    }

    var yDirection: VerticalDirection {
        let yVelocity = velocity(in: nil).y
        if yVelocity == 0 {
            return .none
        }
        if yVelocity < 0 {
            return .up
        }
        return .down
    }
}

extension UIScrollView {
    internal var nsAdjustedContentInset: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return self.adjustedContentInset
        } else {
            // Fallback on earlier versions
            return self.contentInset
        }
    }
    

    internal var scrollsUp: Bool {
        return panGestureRecognizer.yDirection == .up
    }

    internal var isContentOriginInBounds: Bool {
        return contentOffset.y <= -nsAdjustedContentInset.top
    }

    internal func scrollToTop() {
        contentOffset.y = -nsAdjustedContentInset.top
    }
}
