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
        let fractionDigits = significantFractionDigits(precision: 2)
        switch fractionDigits {
        case 0:
            return String(format: "%.0f", self)
        case 1:
            return String(format: "%.1f", self)
        default:
            return String(format: "%.2f", self)
        }
    }
    
    func significantFractionDigits(precision: Int) -> Int {
        guard precision > 0 else { return 0 }
        let precisionFactor = pow(Double(10), Double(precision))
        var fractionDigits = Int((self.truncatingRemainder(dividingBy: 1) * precisionFactor).magnitude)
        assert(fractionDigits >= 0)
        guard fractionDigits > 0 else { return 0 }
        var n = precision
        while fractionDigits % 10 == 0 {
            fractionDigits /= 10
            n -= 1
        }
        return n
    }
}
