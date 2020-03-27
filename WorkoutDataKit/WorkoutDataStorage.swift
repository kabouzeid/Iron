//
//  WorkoutDataStorage.swift
//  WorkoutDataKit
//
//  Created by Karim Abou Zeid on 05.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import CoreData
import Combine
import os.log

public class WorkoutDataStorage {
    public static var model: NSManagedObjectModel {
        // TODO: try to use NSManagedObjectModel.mergedModel(from: [Bundle(for: Self.self))
        guard let modelURL = Bundle(for: Self.self).url(forResource: "WorkoutData", withExtension: "momd") else { fatalError("invalid WorkoutData model URL") }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else { fatalError("could not create managed object model from \(modelURL)") }
        return model
    }
    
    public let persistentContainer: NSPersistentContainer
    
    private var workoutDataObserverCancellable: Cancellable?
    
    public init(storeDescription: NSPersistentStoreDescription? = nil) {
        // create the core data stack
        persistentContainer = NSPersistentContainer(name: "WorkoutData", managedObjectModel: Self.model)
        if let storeDescription = storeDescription {
            assert(storeDescription.shouldAddStoreAsynchronously == false) // this is the default value
            persistentContainer.persistentStoreDescriptions = [storeDescription]
        }
        os_log("Loading persistent store", log: .workoutDataStorage, type: .default)
        loadPersistentStores(tryToRecoverFromFailedMigration: true) { storeDescription in
            os_log("Successfully loaded persistent store: %@", log: .workoutDataStorage, type: .info, storeDescription)
        }
    }
    
    private func loadPersistentStores(tryToRecoverFromFailedMigration: Bool, completion: @escaping (NSPersistentStoreDescription) -> Void) {
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                os_log("Could not load persistent store", log: .workoutDataStorage, type: .fault, error)
                guard tryToRecoverFromFailedMigration && error.code == NSMigrationError else {
                    fatalError("Could not load persistent store \(storeDescription): \(error.localizedDescription)")
                }
                os_log("Trying to recover from migration error", log: .workoutDataStorage, type: .default)
                self.loadPersistentStores(tryToRecoverFromFailedMigration: false) { storeDescription in
                    Self.tryToRecoverFromMigrationError(context: self.persistentContainer.viewContext)
                    completion(storeDescription)
                }
            } else {
                completion(storeDescription)
            }
        })
    }
}

extension WorkoutDataStorage {
    static func tryToRecoverFromMigrationError(context: NSManagedObjectContext) {
        context.performAndWait {
            let workoutRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
            workoutRequest.predicate = NSPredicate(format: "\(#keyPath(Workout.uuid)) == NULL")
            let workouts = try? context.fetch(workoutRequest)
            workouts?.forEach { $0.uuid = UUID() }
            (workouts?.count).map { os_log("Adding UUIDs for %d workouts", log: .migration, type: .info, $0) }
            
            let workoutExerciseRequest: NSFetchRequest<WorkoutExercise> = WorkoutExercise.fetchRequest()
            workoutExerciseRequest.predicate = NSPredicate(format: "\(#keyPath(WorkoutExercise.uuid)) == NULL")
            let workoutExercises = try? context.fetch(workoutExerciseRequest)
            workoutExercises?.forEach { $0.uuid = UUID() }
            (workoutExercises?.count).map { os_log("Adding UUIDs for %d workout exercises", log: .migration, type: .info, $0) }

            let workoutSetRequest: NSFetchRequest<WorkoutSet> = WorkoutSet.fetchRequest()
            workoutSetRequest.predicate = NSPredicate(format: "\(#keyPath(WorkoutSet.uuid)) == NULL")
            let workoutSets = try? context.fetch(workoutSetRequest)
            workoutSets?.forEach { $0.uuid = UUID() }
            (workoutSets?.count).map { os_log("Adding UUIDs for %d workout sets", log: .migration, type: .info, $0) }
            
            let workoutPlanRequest: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
            workoutPlanRequest.predicate = NSPredicate(format: "\(#keyPath(WorkoutPlan.uuid)) == NULL")
            let workoutPlans = try? context.fetch(workoutPlanRequest)
            workoutPlans?.forEach { $0.uuid = UUID() }
            (workoutPlans?.count).map { os_log("Adding UUIDs for %d workout plans", log: .migration, type: .info, $0) }
            
            let workoutRoutineRequest: NSFetchRequest<WorkoutRoutine> = WorkoutRoutine.fetchRequest()
            workoutRoutineRequest.predicate = NSPredicate(format: "\(#keyPath(WorkoutRoutine.uuid)) == NULL")
            let workoutRoutines = try? context.fetch(workoutRoutineRequest)
            workoutRoutines?.forEach { $0.uuid = UUID() }
            (workoutRoutines?.count).map { os_log("Adding UUIDs for %d workout routines", log: .migration, type: .info, $0) }
            
            let workoutRoutineExerciseRequest: NSFetchRequest<WorkoutRoutineExercise> = WorkoutRoutineExercise.fetchRequest()
            workoutRoutineExerciseRequest.predicate = NSPredicate(format: "\(#keyPath(WorkoutRoutineExercise.uuid)) == NULL")
            let workoutRoutineExercises = try? context.fetch(workoutRoutineExerciseRequest)
            workoutRoutineExercises?.forEach { $0.uuid = UUID() }
            (workoutRoutineExercises?.count).map { os_log("Adding UUIDs for %d workout routine exercises", log: .migration, type: .info, $0) }
            
            let workoutRoutineSetRequest: NSFetchRequest<WorkoutRoutineSet> = WorkoutRoutineSet.fetchRequest()
            workoutRoutineSetRequest.predicate = NSPredicate(format: "\(#keyPath(WorkoutRoutineSet.uuid)) == NULL")
            let workoutRoutineSets = try? context.fetch(workoutRoutineSetRequest)
            workoutRoutineSets?.forEach { $0.uuid = UUID() }
            (workoutRoutineSets?.count).map { os_log("Adding UUIDs for %d workout routine sets", log: .migration, type: .info, $0) }
        }
    }
}

import os.signpost
extension WorkoutDataStorage {
    public static func sendObjectsWillChange(changes: NSManagedObjectContext.ObjectChanges) {
        for changedObject in changes.inserted.union(changes.updated).union(changes.deleted) {
            // instruments debugging
            let signPostID = OSSignpostID(log: .coreDataMonitor)
            let signPostName: StaticString = "process single workout data change"
            os_signpost(.begin, log: .coreDataMonitor, name: signPostName, signpostID: signPostID, "%@", changedObject.objectID)
            defer { os_signpost(.end, log: .coreDataMonitor, name: signPostName, signpostID: signPostID) }
            //
            
            changedObject.objectWillChange.send()
            if let workout = changedObject as? Workout {
                workout.workoutExercises?.compactMap { $0 as? WorkoutExercise }
                    .forEach { workoutExercise in
                        workoutExercise.objectWillChange.send()
                        workoutExercise.workoutSets?.compactMap { $0 as? WorkoutSet }
                            .forEach { $0.objectWillChange.send() }
                }
            } else if let workoutExercise = changedObject as? WorkoutExercise {
                workoutExercise.workout?.objectWillChange.send()
                workoutExercise.workoutSets?.compactMap { $0 as? WorkoutSet }
                    .forEach { $0.objectWillChange.send() }
            } else if let workoutSet = changedObject as? WorkoutSet {
                workoutSet.workoutExercise?.objectWillChange.send()
                workoutSet.workoutExercise?.workout?.objectWillChange.send()
            } else if let workoutPlan = changedObject as? WorkoutPlan {
                workoutPlan.workoutRoutines?.compactMap { $0 as? WorkoutRoutine }
                    .forEach { workoutRoutine in
                        workoutRoutine.objectWillChange.send()
                        workoutRoutine.workoutRoutineExercises?.compactMap { $0 as? WorkoutRoutineExercise }
                            .forEach { workoutRoutineExercise in
                                workoutRoutineExercise.objectWillChange.send()
                                workoutRoutineExercise.workoutRoutineSets?.compactMap { $0 as? WorkoutRoutineSet }
                                    .forEach { $0.objectWillChange.send() }
                        }
                }
            } else if let workoutRoutine = changedObject as? WorkoutRoutine {
                workoutRoutine.workoutPlan?.objectWillChange.send()
                workoutRoutine.workoutRoutineExercises?.compactMap { $0 as? WorkoutRoutineExercise }
                    .forEach { workoutRoutineExercise in
                        workoutRoutineExercise.objectWillChange.send()
                        workoutRoutineExercise.workoutRoutineSets?.compactMap { $0 as? WorkoutRoutineSet }
                            .forEach { $0.objectWillChange.send() }
                }
            } else if let workoutRoutineExercise = changedObject as? WorkoutRoutineExercise {
                workoutRoutineExercise.workoutRoutine?.objectWillChange.send()
                workoutRoutineExercise.workoutRoutine?.workoutPlan?.objectWillChange.send()
                workoutRoutineExercise.workoutRoutineSets?.compactMap { $0 as? WorkoutRoutineSet }
                    .forEach { $0.objectWillChange.send() }
            } else if let workoutRoutineSet = changedObject as? WorkoutRoutineSet {
                workoutRoutineSet.workoutRoutineExercise?.objectWillChange.send()
                workoutRoutineSet.workoutRoutineExercise?.workoutRoutine?.objectWillChange.send()
                workoutRoutineSet.workoutRoutineExercise?.workoutRoutine?.workoutPlan?.objectWillChange.send()
            } else {
                os_log("Change for unknown NSManagedObject: %@", log: .coreDataMonitor, type: .error, changedObject)
            }
        }
    }
}
