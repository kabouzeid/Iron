//
//  WorkoutPlan.swift
//  WorkoutDataKit
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

public class WorkoutPlan: NSManagedObject {
    public var displayTitle: String {
        title ?? "Workout Plan"
    }
    
    public func duplicate(context: NSManagedObjectContext) -> WorkoutPlan {
        let workoutPlanCopy = WorkoutPlan(context: context)
        workoutPlanCopy.title = self.title
        workoutPlanCopy.workoutRoutines = NSOrderedSet(array:
            self.workoutRoutines?
                .compactMap { $0 as? WorkoutRoutine }
                .map { workoutRoutine in
                    let workoutRoutineCopy = WorkoutRoutine(context: context)
                    workoutRoutineCopy.title = workoutRoutine.title
                    workoutRoutineCopy.workoutRoutineExercises = NSOrderedSet(array:
                        workoutRoutine.workoutRoutineExercises?
                            .compactMap { $0 as? WorkoutRoutineExercise }
                            .map { workoutRoutineExercise in
                                let workoutRoutineExerciseCopy = WorkoutRoutineExercise(context: context)
                                workoutRoutineExerciseCopy.exerciseUuid = workoutRoutineExercise.exerciseUuid
                                workoutRoutineExerciseCopy.workoutRoutineSets = NSOrderedSet(array:
                                    workoutRoutineExercise.workoutRoutineSets?
                                        .compactMap { $0 as? WorkoutRoutineSet }
                                        .map { workoutRoutineSet in
                                            let workoutRoutineSetCopy  = WorkoutRoutineSet(context: context)
                                            workoutRoutineSetCopy.repetitionsMax = workoutRoutineSet.repetitionsMax
                                            workoutRoutineSetCopy.repetitionsMin = workoutRoutineSet.repetitionsMin
                                            return workoutRoutineSetCopy
                                        }
                                ?? [])
                                return workoutRoutineExerciseCopy
                            }
                    ?? [])
                    return workoutRoutineCopy
                }
        ?? [])
        return workoutPlanCopy
    }
}
