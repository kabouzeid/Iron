//
//  MockWorkoutData.swift
//  IronTests
//
//  Created by Karim Abou Zeid on 13.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
import WorkoutDataKit
@testable import Iron

private let testDate = Date(timeIntervalSince1970: 1565692122) // approx 13. August 2019

private func toUuid(_ id: Int) -> UUID? {
    ExerciseStore.shared.exercises.first { $0.everkineticId == id }?.uuid
}

private func toUuid(_ ids: [Int]) -> [UUID] {
    ids.compactMap { toUuid($0) }
}

private func toUuid(_ ids: [[Int]]) -> [[UUID]] {
    ids.map { toUuid($0) }
}

func createTestWorkoutData(context: NSManagedObjectContext) {
    let workout = Workout(context: context)
    workout.uuid = UUID()
    workout.start = Calendar.current.date(byAdding: .day, value: -2, to: testDate)!
    workout.end = Calendar.current.date(byAdding: .minute, value: 110, to: workout.start!)!
    
    createTestWorkoutExercises(workout: workout)
}

private func createTestWorkoutExercises(workout: Workout) {
    let exerciseUuids = toUuid([
        [42, 48, 206], // bench press, cable crossover, triceps pushdown
        [122], // squat
        [9001], // overhead press
        [291, 289], // crunches, cross-body crunches
        [99], // deadlift
        [211, 206], // biceps curls, triceps pushdown
    ])
    for uuids in exerciseUuids {
        for uuid in uuids {
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseUuid = uuid
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
    workout.uuid = UUID()
    workout.start = Calendar.current.date(byAdding: .minute, value: -71, to: testDate)!
    workout.isCurrentWorkout = true
    
    for uuid in toUuid([42, 48, 206]) { // bench press, cable crossover, triceps pushdown
        let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
        workoutExercise.exerciseUuid = uuid
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
    for uuid in toUuid([291, 289]) { // crunches, cross-body crunches
        let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
        workoutExercise.exerciseUuid = uuid
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
    for uuid in toUuid([211, 206]) { // biceps curls, triceps pushdown
        let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
        workoutExercise.exerciseUuid = uuid
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
