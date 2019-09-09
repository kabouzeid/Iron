//
//  UIImage+Tinting.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

extension UIImage {
//    func tinted(with color: UIColor) -> UIImage? {
//        UIGraphicsBeginImageContextWithOptions(size, false, scale)
//
//        let context = UIGraphicsGetCurrentContext()
//        context?.translateBy(x: 0, y: size.height)
//        context?.scaleBy(x: 1.0, y: -1.0)
//        context?.setBlendMode(.normal)
//
//        let rect = CGRect(origin: .zero, size: size)
//        context?.clip(to: rect, mask: cgImage!)
//        color.setFill()
//        context?.fill(rect)
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        return image
//    }

    func tinted(with color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        color.set()
        withRenderingMode(.alwaysTemplate).draw(in: CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return image
    }
}
