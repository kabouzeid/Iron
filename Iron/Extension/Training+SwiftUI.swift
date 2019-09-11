//
//  Training+SwiftUI.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 26.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import SwiftUI

extension Training {
    var muscleGroupImage: some View {
        let muscleGroup = muscleGroups.first ?? ""
        return Exercise.imageFor(muscleGroup: muscleGroup).foregroundColor(Exercise.colorFor(muscleGroup: muscleGroup))
    }
    
    var muscleGroupColor: Color {
        let muscleGroup = muscleGroups.first ?? ""
        return Exercise.colorFor(muscleGroup: muscleGroup)
    }
}
