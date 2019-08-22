//
//  WorkoutSetTag+SwiftUI.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import SwiftUI

extension WorkoutSetTag {
    var color: Color {
        switch self {
        case .warmUp:
            return .yellow
        case .dropSet:
            return .purple
        case .failure:
            return .red
        }
    }
}
