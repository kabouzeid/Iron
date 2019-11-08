//
//  NSManagedObjectContext+Publisher.swift
//  Iron
//
//  Created by Karim Abou Zeid on 08.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Combine
import CoreData

extension NSManagedObjectContext {
    struct ObjectChanges {
        let inserted: Set<NSManagedObject>
        let updated: Set<NSManagedObject>
        let deleted: Set<NSManagedObject>
    }
    
    private static let publisher: AnyPublisher<(ObjectChanges, NSManagedObjectContext), Never> = {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)
            .compactMap { notification -> (ObjectChanges, NSManagedObjectContext)? in
                guard let userInfo = notification.userInfo else { return nil }
                guard let managedObjectContext = notification.object as? NSManagedObjectContext else { return nil }
                
                // instruments
                let signPostID = OSSignpostID(log: SignpostLog.workoutDataPublisher)
                let signPostName: StaticString = "process MOC change notification"
                os_signpost(.begin, log: SignpostLog.workoutDataPublisher, name: signPostName, signpostID: signPostID, "%{public}s", managedObjectContext.description)
                defer { os_signpost(.end, log: SignpostLog.workoutDataPublisher, name: signPostName, signpostID: signPostID) }

                let inserted = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set()
                let updated = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
                let deleted = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()
                
                return (ObjectChanges(inserted: inserted, updated: updated, deleted: deleted), managedObjectContext)
            }
            .share()
            .eraseToAnyPublisher()
    }()
    
    var publisher: AnyPublisher<ObjectChanges, Never> {
        Self.publisher
            .filter { $0.1 === self } // only publish changes belonging to this context
            .map { $0.0 }
            .eraseToAnyPublisher()
    }
}

// MARK: - Workout Data

import os.signpost
extension NSManagedObjectContext {
    func observeWorkoutDataChanges() -> AnyCancellable {
        publisher
            .drop(while: { _ in IronBackup.restoringBackupData }) // better to ignore the spam while we are restoring
            .sink {
                for changedObject in $0.inserted.union($0.updated).union($0.deleted) {
                    // instruments
                    let signPostID = OSSignpostID(log: SignpostLog.workoutDataPublisher)
                    let signPostName: StaticString = "process single workout data change"
                    os_signpost(.begin, log: SignpostLog.workoutDataPublisher, name: signPostName, signpostID: signPostID, "%{public}s", changedObject.objectID.description)
                    defer { os_signpost(.end, log: SignpostLog.workoutDataPublisher, name: signPostName, signpostID: signPostID) }
                    
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
                    } else {
                        print("change in unknown NSManagedObject \(changedObject)")
                    }
                }
            }
    }
}
