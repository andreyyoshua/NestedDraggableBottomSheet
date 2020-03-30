//
//  ScrollViewCaringGestureRecognizer.swift
//  NestedScrollView
//
//  Created by Andrey Yoshua Manik on 19/03/20.
//  Copyright © 2020 Brid. All rights reserved.
//

import UIKit

class ScrollViewCaringGestureRecognizer: UIPanGestureRecognizer {

    weak var drivingScrollView: UIScrollView?

    private(set) var startingLocation: CGPoint = .zero

    // MARK: - Public

    func cancel() {
        isEnabled = false
        isEnabled = true
    }

    // MARK: - UIGestureRecognizer

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        startingLocation = location(in: view)
    }

    override func shouldRequireFailure(of otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gestures = drivingScrollView?.gestureRecognizers else {
            return super.shouldRequireFailure(of: otherGestureRecognizer)
        }
        if gestures.contains(otherGestureRecognizer) {
            return true
        } else {
            return super.shouldRequireFailure(of: otherGestureRecognizer)
        }
    }
}
