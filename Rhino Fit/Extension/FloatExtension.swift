//
//  FloatExtension.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 28.03.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension Float {
    var clean: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}
