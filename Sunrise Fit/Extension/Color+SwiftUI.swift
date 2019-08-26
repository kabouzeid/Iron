//
//  Color+SwiftUI.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 26.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

extension Color {
    // used when we want a gesture on a clear space
    // 0.0000001 for example would work too, Double.leastNonzeroMagnitude is treated as 0 though
    static let fakeClear = Color.black.opacity(Double(Float.leastNonzeroMagnitude))
}
