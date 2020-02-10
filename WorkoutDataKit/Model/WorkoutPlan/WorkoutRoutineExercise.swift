//
//  WorkoutPlan.swift
//  WorkoutDataKit
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

public class WorkoutRoutineExercise: NSManagedObject {
    public func exercise(in exercises: [Exercise]) -> Exercise? {
        ExerciseStore.find(in: exercises, with: exerciseUuid)
    }
}
