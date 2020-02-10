//
//  WorkoutPlan.swift
//  WorkoutDataKit
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

public class WorkoutRoutine: NSManagedObject {
    public func createWorkout(context: NSManagedObjectContext) -> Workout {
        let workout = Workout(context: context)
        workout.uuid = UUID()
        
        if let workoutRoutineExercises = workoutRoutineExercises?.compactMap({ $0 as? WorkoutRoutineExercise }) {
            // copy the exercises
            for workoutRoutineExercise in workoutRoutineExercises {
                let workoutExercise = WorkoutExercise(context: context)
                workout.addToWorkoutExercises(workoutExercise)
                workoutExercise.exerciseUuid = workoutRoutineExercise.exerciseUuid
                
                if let workoutRoutineSets = workoutRoutineExercise.workoutRoutineSets?.compactMap({ $0 as? WorkoutRoutineSet }) {
                    // copy the sets
                    for workoutRoutineSet in workoutRoutineSets {
                        let workoutSet = WorkoutSet(context: context)
                        workoutExercise.addToWorkoutSets(workoutSet)
                        workoutSet.isCompleted = false
                        workoutSet.weight = workoutRoutineSet.weight
                        workoutSet.repetitions = workoutRoutineSet.repetitions
                    }
                }
            }
        }
        
        addToWorkouts(workout)
        return workout
    }
}
