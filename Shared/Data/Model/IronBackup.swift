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
import os.log

enum IronBackup {
    private struct IronBackup: Codable {
        /*
         Version History
         ===============
         
         Version 1: initial
         Version 2: workout UUIDs
         Version 3: workout plans, all entities have mandatory UUIDs
         */
        var version: Int = 3 // var not let so it can be overwritten by decodable
        let date: Date
        let customExercises: [Exercise]
        let workoutPlans: [WorkoutPlan]
        let workouts: [Workout]
        
        // MARK: - Codable
        
        private enum CodingKeys: String, CodingKey {
            case version
            case date
            case customExercises
            case workoutPlans
            case workouts
        }
        
        init(date: Date, customExercises: [Exercise], workoutPlans: [WorkoutPlan], workouts: [Workout]) {
            self.date = date
            self.customExercises = customExercises
            self.workoutPlans = workoutPlans
            self.workouts = workouts
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            version = try container.decode(Int.self, forKey: .version)
            date = try container.decode(Date.self, forKey: .date)
            customExercises = try container.decode([Exercise].self, forKey: .customExercises)
            workoutPlans = try container.decodeIfPresent([WorkoutPlan].self, forKey: .workoutPlans) ?? []
            // workout plans must be decoded before workouts
            workouts = try container.decode([Workout].self, forKey: .workouts)
        }
        
//        public func encode(to encoder: Encoder) throws {
//            let container = encoder.container(keyedBy: CodingKeys.self)
//            try container.encode(version, forKey: .version)
//            try container.encode(date, forKey: .date)
//            try container.encode(customExercises, forKey: .customExercises)
//            try container.encode(workoutPlans, forKey: .workoutPlans)
//            try container.encode(workouts, forKey: .workouts)
//        }
    }
    
    static func createBackupData(managedObjectContext: NSManagedObjectContext, exerciseStore: ExerciseStore) throws -> Data
    {
        let workoutRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        workoutRequest.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) != %@", NSNumber(booleanLiteral: true))
        workoutRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        let workouts = try managedObjectContext.fetch(workoutRequest)
        
        let workoutPlanRequest: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
        workoutPlanRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutPlan.title, ascending: false)]
        let workoutPlans = try managedObjectContext.fetch(workoutPlanRequest)
        
        let backup = IronBackup(date: Date(), customExercises: exerciseStore.customExercises, workoutPlans: workoutPlans, workouts: workouts)
        
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
                os_log("Restoring backup data was unsuccessful, trying to undo changes", log: .backup, type: .default)
                do {
                    try ExerciseStore.shared.replaceCustomExercises(with: previousCustomExercises)
                    os_log("Successfully reverted changes to custom exercises", log: .backup, type: .default)
                } catch {
                    os_log("Could not revert changes to custom exercises", log: .backup, type: .error)
                }
            }
            restoringBackupData = false
        }
        restoringBackupData = true
        
        // use a child context so we don't lose the current data if anything goes wrong
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = WorkoutDataStorage.shared.persistentContainer.viewContext
        
        // delete all workouts (except for the current workout)
        os_log("Deleting all workouts", log: .backup, type: .default)
        let workoutRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        workoutRequest.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) != %@", NSNumber(booleanLiteral: true))
        let workouts = try context.fetch(workoutRequest)
        for workout in workouts {
            context.delete(workout)
        }
        
        // try to restore the workouts
        os_log("Restoring workouts", log: .backup, type: .default)
        guard let managedObjectContextKey = CodingUserInfoKey.managedObjectContextKey else { throw "Managed object context key is nill" }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.userInfo[managedObjectContextKey] = context
        let workoutDataBackup = try decoder.decode(IronBackup.self, from: data) // this already inserts the workout into the context
        
        // try to restore the custom exercises
        os_log("Restoring custom exercises", log: .backup, type: .default)
        try ExerciseStore.shared.replaceCustomExercises(with: workoutDataBackup.customExercises)
        
        // if everything went well, save the changes
        try context.save()
        success = true
        os_log("Successfully restored backup data", log: .backup, type: .info)
    }
}
