//
//  NestedTableViewCell.swift
//  NestedScrollView
//
//  Created by Andrey Yoshua Manik on 19/03/20.
//  Copyright © 2020 Brid. All rights reserved.
//

import UIKit

internal class NestedCell: UITableViewCell {
    
    internal static var identifier: String = "Cell"
    
    internal var askingForChildCallback: (() -> (tableView: UITableView, indexPath: IndexPath, child: UIView?))? {
        didSet {
            commonPreparation()
        }
    }
    private var observer: NSKeyValueObservation?
    
    private func commonPreparation() {
        observer?.invalidate()
        
        guard let callback = askingForChildCallback?(), let child = callback.child, contentView.subviews.contains(child) == false else { return }
        backgroundColor = .clear
        contentView.subviews.forEach { $0.removeFromSuperview() }
        contentView.addSubview(child)
        child.pinToSuperview()
        if let scrollview = child as? UIScrollView {
            observer = scrollview.observe(\.contentSize, options: [.new]) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    callback.tableView.beginUpdates()
                    callback.tableView.endUpdates()
                }
            }
        }
    }
}
