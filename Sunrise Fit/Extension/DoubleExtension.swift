//
//  FloatExtension.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 28.03.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension Double {
    var shortStringValue: String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        } else if (self * 10).truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.1f", self)
        }
        return String(format: "%.2f", self)
    }
}
