//
//  ViewController.swift
//  NestedScrollViewExample
//
//  Created by Andrey Yoshua Manik on 18/02/20.
//  Copyright © 2020 Brid. All rights reserved.
//

import UIKit
import NestedScrollView

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        NestedScrollView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            BottomSheetViewController(content: NyobaViewController()).showIn(vc: self)
        }
    }

}

