//
//  SomePromise.swift
//  promise.practise
//
//  Created by oe on 2018/6/23.
//  Copyright © 2018年 oe. All rights reserved.
//

import UIKit
import PromiseKit

class BViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firstly {
            login()
        }.then { name in
            return Promise()
        }.catch { e in
            print("\(e)")
        }
    }
    
    func login() -> Promise<String> {
        return Promise.init(resolver: { (r) in
            r.fulfill("Pbyi")
        })
    }
    
    func secondStep() -> Promise<NSNumber> {
        return Promise.init(resolver: { (r) in
            r.fulfill(NSNumber.init(value: 1))
        })
    }
}
