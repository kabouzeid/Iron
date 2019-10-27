//
//  WorkoutDataBackup.swift
//  Iron
//
//  Created by Karim Abou Zeid on 26.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import CoreData

struct WorkoutDataBackup: Codable {
    let version: Int = 1
    let date: Date
    let customExercises: [Exercise]
    let workouts: [Workout]
}

var restoringFromBackup = false
func restoreWorkoutDataFromBackup(backupData: Data) throws {
    restoringFromBackup = true
    // save the current state before we touch anything
    let previousCustomExercises = ExerciseStore.shared.customExercises
    
    var success = false
    defer {
        if !success {
            // if something went wrong, undo all changes
            try? ExerciseStore.shared.replaceCustomExercises(with: previousCustomExercises)
        }
        restoringFromBackup = false
    }
    
    // use a child context so we don't lose the current data if anything goes wrong
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.parent = AppDelegate.instance.persistentContainer.viewContext
    
    // delete all workouts (except for the current workout)
    let workoutRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
    workoutRequest.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) != %@", NSNumber(booleanLiteral: true))
    let workouts = try context.fetch(workoutRequest)
    for workout in workouts {
        context.delete(workout)
    }
    
    // try to restore the workouts
    guard let managedObjectContextKey = CodingUserInfoKey.managedObjectContextKey else { throw CodingUserInfoKey.DecodingError.managedObjectContextKeyIsNil }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.userInfo[managedObjectContextKey] = context
    let workoutDataBackup = try decoder.decode(WorkoutDataBackup.self, from: backupData) // this already inserts the workout into the context
    
    // try to restore the custom exercises
    try ExerciseStore.shared.replaceCustomExercises(with: workoutDataBackup.customExercises)
    
    // if everything went well, save the changes
    try context.save()
    success = true
}
