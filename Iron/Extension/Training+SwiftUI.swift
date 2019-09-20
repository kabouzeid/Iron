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
    func muscleGroupImage(in exercises: [Exercise]) -> some View {
        let muscleGroup = muscleGroups(in: exercises).first ?? ""
        return Exercise.imageFor(muscleGroup: muscleGroup).foregroundColor(Exercise.colorFor(muscleGroup: muscleGroup))
    }
    
    func muscleGroupColor(in exercises: [Exercise]) -> Color {
        let muscleGroup = muscleGroups(in: exercises).first ?? ""
        return Exercise.colorFor(muscleGroup: muscleGroup)
    }
}
