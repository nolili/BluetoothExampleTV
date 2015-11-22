//
//  ViewController.swift
//  BluetoothExampleTV
//
//  Created by Noritaka Kamiya on 2015/10/30.
//  Copyright © 2015年 Noritaka Kamiya. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController {
    
    let bluetoothManager = BluetoothManager()
    
    @IBOutlet var label:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetoothManager.heartRateUpdateHandler = { bpm in
            self.label?.text = "❤️" + String(bpm)
            let current = self.label.transform
            UIView.animateWithDuration(0.1, animations: {
                self.label.transform = CGAffineTransformScale(current, 1.1, 1.1)
                }, completion: { completed in
                    self.label.transform = current
            })
        }
    }
}
