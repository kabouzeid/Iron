//
//  Comparable+Clamped.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 05.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
