//
//  WorkoutDataHelper.swift
//  Sunrise FitTests
//
//  Created by Karim Abou Zeid on 13.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
@testable import Iron

private let testDate = Date(timeIntervalSince1970: 1565692122) // approx 13. August 2019

func createTestWorkoutData(context: NSManagedObjectContext) {
    let workout = Workout(context: context)
    workout.start = Calendar.current.date(byAdding: .day, value: -2, to: testDate)!
    workout.end = Calendar.current.date(byAdding: .minute, value: 110, to: workout.start!)!
    
    createTestWorkoutExercises(workout: workout)
}

private func createTestWorkoutExercises(workout: Workout) {
    let exerciseIds = [
        [42, 48, 206], // bench press, cable crossover, triceps pushdown
        [122], // squat
        [9001], // overhead press
        [291, 289], // crunches, cross-body crunches
        [99], // deadlift
        [211, 206], // biceps curls, triceps pushdown
    ]
    for ids in exerciseIds {
        for j in ids {
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseId = Int16(j)
            workoutExercise.workout = workout
            
            let numberOfSets = 5
            for setNumber in 1...numberOfSets {
                let workoutSet = WorkoutSet(context: workout.managedObjectContext!)
                workoutSet.weight = 50 + Double(setNumber) * 2.5
                workoutSet.repetitions = Int16(3 + setNumber)
                workoutSet.isCompleted = true
                workoutSet.workoutExercise = workoutExercise
            }
        }
    }
}

func createTestCurrentWorkout(context: NSManagedObjectContext) -> Workout {
    let workout = Workout(context: context)
    workout.start = Calendar.current.date(byAdding: .minute, value: -71, to: testDate)!
    workout.isCurrentWorkout = true
    
    for j in [42, 48, 206] { // bench press, cable crossover, triceps pushdown
        let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
        workoutExercise.exerciseId = Int16(j)
        workoutExercise.workout = workout
        
        let numberOfSets = 5
        for setNumber in 1...numberOfSets {
            let workoutSet = WorkoutSet(context: workout.managedObjectContext!)
            workoutSet.weight = 50 + Double(setNumber) * 2.5
            workoutSet.repetitions = Int16(3 + setNumber)
            workoutSet.isCompleted = true
            workoutSet.workoutExercise = workoutExercise
        }
    }
    for j in [291, 289] { // crunches, cross-body crunches
        let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
        workoutExercise.exerciseId = Int16(j)
        workoutExercise.workout = workout
        
        let numberOfSets = 6
        for setNumber in 1...numberOfSets {
            let workoutSet = WorkoutSet(context: workout.managedObjectContext!)
            workoutSet.workoutExercise = workoutExercise
            switch setNumber {
            case 1:
                workoutSet.weight = 50 + Double(setNumber) * 2.5
                workoutSet.repetitions = Int16(3 + setNumber)
                workoutSet.isCompleted = true
            case 2:
                workoutSet.weight = 50 + Double(setNumber) * 2.5
                workoutSet.repetitions = Int16(3 + setNumber)
                workoutSet.isCompleted = false
            default:
                workoutSet.isCompleted = false
            }
        }
    }
    for j in [211, 206] { // biceps curls, triceps pushdown
        let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
        workoutExercise.exerciseId = Int16(j)
        workoutExercise.workout = workout
        
        let numberOfSets = 3
        for _ in 1...numberOfSets {
            let workoutSet = WorkoutSet(context: workout.managedObjectContext!)
            workoutSet.workoutExercise = workoutExercise
            workoutSet.isCompleted = false
        }
    }
    return workout
}
