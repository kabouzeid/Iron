//
//  TrainingExtension.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 26.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import SwiftUI

extension Training {
    var muscleGroupImage: some View {
        switch muscleGroups.first ?? "" {
        case "abdominals":
            return Image(systemName: "a.circle.fill").foregroundColor(.yellow)
        case "arms":
            return Image(systemName: "a.circle.fill").foregroundColor(.purple)
        case "shoulders":
            return Image(systemName: "s.circle.fill").foregroundColor(.orange)
        case "back":
            return Image(systemName: "b.circle.fill").foregroundColor(.blue)
        case "legs":
            return Image(systemName: "l.circle.fill").foregroundColor(.green)
        case "chest":
            return Image(systemName: "c.circle.fill").foregroundColor(.red)
        default:
            return Image(systemName: "o.circle.fill").foregroundColor(.secondary)
        }
    }
}
