//
//  SomePromise.swift
//  promise.practise
//
//  Created by oe on 2018/6/23.
//  Copyright © 2018年 oe. All rights reserved.
//

import UIKit

class SomePromise: NSObject {
    @objc public init(resolver body: (@escaping (Any?) -> Void) -> Int) {
//        box = EmptyBox<Any?>()
        super.init()
        //        body {let x: Any in
        //
        //        }

        let x = [1,2,3]
        x.map { (x: Int) -> Int in
            return 0
        }
        body {_ in
            
        }
        body({(x: Any?) in
            
            
        })
//        body {
//
//            if let p = $0 as? AnyPromise {
//                p.d.__pipe(self.box.seal)
//            } else {
//                self.box.seal($0)
//            }
//        }
    }
}
