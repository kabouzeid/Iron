//
//  WorkoutPlan.swift
//  WorkoutDataKit
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

public class WorkoutRoutineExercise: NSManagedObject {
    public class func create(context: NSManagedObjectContext) -> WorkoutRoutineExercise {
        let workoutRoutineExercise = WorkoutRoutineExercise(context: context)
        workoutRoutineExercise.uuid = UUID()
        return workoutRoutineExercise
    }
    
    public var subtitle: String? {
        guard let workoutRoutineSets = workoutRoutineSets?.compactMap({ $0 as? WorkoutRoutineSet }) else { return nil }
        
        if let firstSet = workoutRoutineSets.first, let minReps = firstSet.repetitionsMinValue, let maxReps = firstSet.repetitionsMaxValue {
            var sameReps = true
            for set in workoutRoutineSets {
                if minReps != set.repetitionsMinValue || maxReps != set.repetitionsMaxValue {
                    sameReps = false
                    break
                }
            }
            if sameReps {
                let reps = minReps == maxReps ? "\(minReps)" : "\(minReps)-\(maxReps)"
                return "\(workoutRoutineSets.count) sets of \(reps) reps"
            }
        }
        
        return "\(workoutRoutineSets.count) sets"
    }
    
    public func exercise(in exercises: [Exercise]) -> Exercise? {
        ExerciseStore.find(in: exercises, with: exerciseUuid)
    }
}
