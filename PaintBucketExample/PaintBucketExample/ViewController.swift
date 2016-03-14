//
//  ViewController.swift
//  PaintBucketExample
//
//  Created by Jack Flintermann on 3/14/16.
//  Copyright © 2016 jflinter. All rights reserved.
//

import UIKit
import PaintBucket

class ViewController: UIViewController {
    
    let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.orangeColor()
        self.view.addSubview(self.imageView)
        self.imageView.contentMode = .ScaleAspectFit
        self.imageView.image = UIImage(named: "Crystal")?.pbk_imageByReplacingColorAt(CGPoint.zero, withColor: UIColor.clearColor(), tolerance: 50)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.imageView.frame = self.view.bounds
    }

}
