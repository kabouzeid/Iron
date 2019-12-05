//
//  IronBackup.swift
//  Iron
//
//  Created by Karim Abou Zeid on 26.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import CoreData
import WorkoutDataKit

enum IronBackup {
    private struct IronBackup: Codable {
        /*
         Version History
         ===============
         
         Version 1: initial
         Version 2: workout UUIDs
         */
        var version: Int = 2 // var not let so it can be overwritten by decodable
        let date: Date
        let customExercises: [Exercise]
        let workouts: [Workout]
    }
    
    static func createBackupData(managedObjectContext: NSManagedObjectContext, exerciseStore: ExerciseStore) throws -> Data
    {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) != %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        let workouts = try managedObjectContext.fetch(request)
        
        let backup = IronBackup(date: Date(), customExercises: exerciseStore.customExercises, workouts: workouts)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let exercisesKey = CodingUserInfoKey.exercisesKey {
            encoder.userInfo[exercisesKey] = ExerciseStore.shared.exercises
        }
        
        return try encoder.encode(backup)
    }
    
    static var restoringBackupData = false
    static func restoreBackupData(data: Data, managedObjectContext: NSManagedObjectContext, exerciseStore: ExerciseStore) throws {
        // save the current state before we touch anything
        let previousCustomExercises = ExerciseStore.shared.customExercises
        
        var success = false
        defer {
            if !success {
                // if something went wrong, undo all changes
                try? ExerciseStore.shared.replaceCustomExercises(with: previousCustomExercises)
            }
            restoringBackupData = false
        }
        restoringBackupData = true
        
        // use a child context so we don't lose the current data if anything goes wrong
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = WorkoutDataStorage.shared.persistentContainer.viewContext
        
        // delete all workouts (except for the current workout)
        let workoutRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        workoutRequest.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) != %@", NSNumber(booleanLiteral: true))
        let workouts = try context.fetch(workoutRequest)
        for workout in workouts {
            context.delete(workout)
        }
        
        // try to restore the workouts
        guard let managedObjectContextKey = CodingUserInfoKey.managedObjectContextKey else { throw "Managed object context key is nill" }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.userInfo[managedObjectContextKey] = context
        let workoutDataBackup = try decoder.decode(IronBackup.self, from: data) // this already inserts the workout into the context
        
        // try to restore the custom exercises
        try ExerciseStore.shared.replaceCustomExercises(with: workoutDataBackup.customExercises)
        
        // if everything went well, save the changes
        try context.save()
        success = true
    }
}
