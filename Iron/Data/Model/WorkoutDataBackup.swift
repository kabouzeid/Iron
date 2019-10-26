//
//  WorkoutDataBackup.swift
//  Iron
//
//  Created by Karim Abou Zeid on 26.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

struct WorkoutDataBackup: Codable {
    let version: Int = 1
    let date: Date
    let customExercises: [Exercise]
    let workouts: [Workout]
}
