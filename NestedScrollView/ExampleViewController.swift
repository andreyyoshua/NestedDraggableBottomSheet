//
//  File.swift
//  NestedScrollView
//
//  Created by Andrey Yoshua Manik on 19/03/20.
//  Copyright © 2020 Brid. All rights reserved.
//

import UIKit

public class ContohViewController: UIViewController {
    public override func loadView() {
        view = ContohTableView()
    }
}

public class ContohTableView: UITableView, UITableViewDataSource, UITableViewDelegate {
    var totalData = 50
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalData
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = totalData == 50 ? "\(indexPath.row)" : "Hahahaha \(indexPath.row)"
        return cell
    }
    
    init() {
        super.init(frame: .zero, style: .plain)
        
        dataSource = self
        bounces = false
        register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.totalData = 80
            self.reloadData()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

public class Contoh: UIScrollView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentSize = CGSize(width: frame.width, height: frame.height * 2)
        let label = UILabel(frame: CGRect.init(origin: .zero, size: CGSize(width: 100, height: 100)))
        label.text = "Hahahaha"
        addSubview(label)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
