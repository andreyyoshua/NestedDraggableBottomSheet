//
//  NestedScrollView.swift
//  NestedScrollView
//
//  Created by Andrey Yoshua Manik on 18/02/20.
//  Copyright © 2020 Brid. All rights reserved.
//

import UIKit

internal struct NestedChildren {
    let view: UIView
    var forcedHeight: CGFloat?
}

public class NestedScrollView: UITableView, UITableViewDataSource, UITableViewDelegate {
    
    private var children: [NestedChildren] = []
    
    public init() {
        super.init(frame: .zero, style: .plain)
        commonInit()
    }
    
    public override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: .plain)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        register(NestedCell.self, forCellReuseIdentifier: NestedCell.identifier)
        allowsSelection = false
        allowsSelectionDuringEditing = false
        allowsMultipleSelection = false
        allowsMultipleSelectionDuringEditing = false
        
        delegate = self
        dataSource = self
        backgroundColor = .clear
    }
    
    public func setupContoh(count: Int = 5) {
        
        for _ in 0..<count {
            addView(ContohTableView())
        }
    }
    
    public func addView(_ view: UIView, at position: Int? = nil, forcingHeight: CGFloat? = nil) {
        if let nested = view as? NestedScrollView {
            nested.reloadData()
        }
        children.append(NestedChildren(view: view, forcedHeight: forcingHeight))
        beginUpdates()
        insertRows(at: [IndexPath(row: children.count - 1, section: 0)], with: .none)
        endUpdates()
        
        guard let scrollView = view as? UIScrollView else { return }
        scrollView.isScrollEnabled = false
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return children.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NestedCell.identifier, for: indexPath) as? NestedCell else { return UITableViewCell() }
        
        let child = self.children[indexPath.row].view
        cell.askingForChildCallback = { (tableView, indexPath, child) }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let scrollview = children[indexPath.row].view as? UIScrollView else {
            return children[indexPath.row].forcedHeight ?? children[indexPath.row].view.frame.height
        }
        return scrollview.contentSize.height
    }
}
