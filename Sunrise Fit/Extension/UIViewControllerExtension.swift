//
//  UIViewControllerExtension.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 09.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

extension UIViewController {
    func wrappedViewController() -> UIViewController {
        if self is UINavigationController {
            if let topVC = (self as! UINavigationController).topViewController {
                return topVC
            }
        }
        return self
    }
}
