//
//  TrainingExercise+SwiftUI.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 27.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import SwiftUI

extension TrainingExercise {
    var muscleGroupImage: some View {
        let muscleGroup = exercise?.muscleGroup ?? ""
        return Exercise.imageFor(muscleGroup: muscleGroup).foregroundColor(Exercise.colorFor(muscleGroup: muscleGroup))
    }
    
    var muscleGroupColor: Color {
        let muscleGroup = exercise?.muscleGroup ?? ""
        return Exercise.colorFor(muscleGroup: muscleGroup)
    }
}
