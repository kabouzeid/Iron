//
//  ExerciseStore+shared.swift
//  Iron
//
//  Created by Karim Abou Zeid on 06.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit

extension ExerciseStore {
    static let shared = ExerciseStore(customExercisesURL: customExercisesURL, userDefaults: UserDefaults.appGroup)
    
    static let customExercisesURL = FileManager.default.appGroupContainerApplicationSupportURL.appendingPathComponent("custom_exercises").appendingPathExtension("json")
}
