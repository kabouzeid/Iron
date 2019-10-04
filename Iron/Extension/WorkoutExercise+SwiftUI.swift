//
//  WorkoutExercise+SwiftUI.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 27.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import SwiftUI

extension WorkoutExercise {
    func muscleGroupImage(in exercises: [Exercise]) -> some View {
        let muscleGroup = exercise(in: exercises)?.muscleGroup ?? ""
        return Exercise.imageFor(muscleGroup: muscleGroup).foregroundColor(Exercise.colorFor(muscleGroup: muscleGroup))
    }
    
    func muscleGroupColor(in exercises: [Exercise]) -> Color {
        let muscleGroup = exercise(in: exercises)?.muscleGroup ?? ""
        return Exercise.colorFor(muscleGroup: muscleGroup)
    }
}
