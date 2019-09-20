//
//  Exercise+SwiftUI.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 27.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import SwiftUI

extension Exercise {
    static func colorFor(muscleGroup: String) -> Color {
        switch muscleGroup {
        case "abdominals":
            return .yellow
        case "arms":
            return .purple
        case "shoulders":
            return .orange
        case "back":
            return .blue
        case "legs":
            return .green
        case "chest":
            return .red
        default:
            return .secondary
        }
    }
    
    static func imageFor(muscleGroup: String) -> Image {
        switch muscleGroup {
        case "abdominals":
            return Image(systemName: "a.circle.fill")
        case "arms":
            return Image(systemName: "a.circle.fill")
        case "shoulders":
            return Image(systemName: "s.circle.fill")
        case "back":
            return Image(systemName: "b.circle.fill")
        case "legs":
            return Image(systemName: "l.circle.fill")
        case "chest":
            return Image(systemName: "c.circle.fill")
        default:
            return Image(systemName: "o.circle.fill")
        }
    }
}

extension Exercise {
    var muscleGroupImage: some View {
        Exercise.imageFor(muscleGroup: muscleGroup).foregroundColor(Exercise.colorFor(muscleGroup: muscleGroup))
    }
    
    var muscleGroupColor: Color {
        Exercise.colorFor(muscleGroup: muscleGroup)
    }
}
