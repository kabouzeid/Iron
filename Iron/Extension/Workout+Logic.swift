//
//  Workout+Logic.swift
//  Iron
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit
import os.log

extension Workout {
    // TODO: would be better when SettingsStore, WatchConnectionManager, RestTimerStore etc are injected
    
    func start(startWatchCompanionErrorHandler: WatchConnectionManager.StartWatchCompanionErrorHandler? = nil) throws {
        guard let context = managedObjectContext else {
            os_log("Attempt to start workout without context", log: .workoutData, type: .error)
            assertionFailure("Attempt to start workout without context")
            return
        }

        start = Date()
        isCurrentWorkout = true
        try context.save() // this also checks that there is only one currentWorkout
        
        if SettingsStore.shared.watchCompanion {
            WatchConnectionManager.shared.prepareAndStartWatchWorkout(workout: self, startWatchCompanionErrorHandler: startWatchCompanionErrorHandler)
        }
        
        // TODO: move this to the current workout view controller, or maybe even when a notification is scheduled?
        NotificationManager.shared.requestAuthorization()
        
        if (workoutExercises?.count ?? 0) == 0 && workoutRoutine == nil {
            // only donate when we start an empty workout
            // we don't have apropriate intent parameters for other workouts yet
            Shortcuts.donateStartWorkoutInteraction(for: self)
        }
    }
    
    func cancel() throws {
        guard let context = managedObjectContext else {
            os_log("Attempt to cancel workout without context", log: .workoutData, type: .error)
            assertionFailure("Attempt to cancel workout without context")
            return
        }
        
        RestTimerStore.shared.cancel()
        
        if WatchConnectionManager.shared.currentWatchWorkoutUuid != nil, let uuid = uuid {
            WatchConnectionManager.shared.discardWatchWorkout(uuid: uuid)
        }
        
        // the user did not go through with the workout, we should remove our previous donation
        Shortcuts.deleteStartWorkoutInteractionDonation(for: self)
        
        context.delete(self)
        try context.save()
    }
    
    func finish() throws {
        guard let context = managedObjectContext else {
            os_log("Attempt to finish workout without context", log: .workoutData, type: .error)
            assertionFailure("Attempt to finish workout without context")
            return
        }
        
        try context.save() // just in case something goes wrong
        
        RestTimerStore.shared.cancel()
        
        deleteExercisesWhereAllSetsAreUncompleted()
        deleteUncompletedSets()
        start = safeStart // start/end should already be set, but just to be safe
        end = safeEnd
        isCurrentWorkout = false
        try context.save()
        
        // save workout in Health or tell Apple Watch to finish the workout
        if let watchWorkoutUuid = WatchConnectionManager.shared.currentWatchWorkoutUuid {
            if watchWorkoutUuid != uuid {
                os_log("currentWatchWorkoutUuid=%@ but workout uuid=%@, saving HealthKit workout on phone too to be safe", log: .watch, type: .error, watchWorkoutUuid.uuidString, uuid?.uuidString ?? "nil")
                HealthManager.shared.saveWorkout(workout: self, exerciseStore: ExerciseStore.shared)
            }
            if let start = start, let end = end, let uuid = uuid {
                WatchConnectionManager.shared.finishWatchWorkout(start: start, end: end, title: optionalDisplayTitle(in: ExerciseStore.shared.exercises), uuid: uuid)
            }
        } else {
            HealthManager.shared.saveWorkout(workout: self, exerciseStore: ExerciseStore.shared)
        }
    }
    
    func delete() throws {
        guard let context = managedObjectContext else {
            os_log("Attempt to delete workout without context", log: .workoutData, type: .error)
            assertionFailure("Attempt to delete workout without context")
            return
        }
        
        HealthManager.shared.deleteWorkout(workout: self)
        
        Shortcuts.deleteStartWorkoutInteractionDonation(for: self)
        
        context.delete(self)
        try context.save()
    }
    
    func copyForRepeat(blank: Bool) -> Workout? {
        guard let context = managedObjectContext else {
            os_log("Attempt to copy workout without context", log: .workoutData, type: .error)
            assertionFailure("Attempt to copy workout without context")
            return nil
        }
        
        // create the workout
        let newWorkout = Workout.create(context: context)
        
        if let workoutExercises = workoutExercises?.compactMap({ $0 as? WorkoutExercise }) {
            // copy the exercises
            for workoutExercise in workoutExercises {
                let newWorkoutExercise = WorkoutExercise.create(context: context)
                newWorkoutExercise.workout = newWorkout
                newWorkoutExercise.exerciseUuid = workoutExercise.exerciseUuid
                
                if let workoutSets = workoutExercise.workoutSets?.compactMap({ $0 as? WorkoutSet }) {
                    // copy the sets
                    for workoutSet in workoutSets {
                        let newWorkoutSet = WorkoutSet.create(context: context)
                        newWorkoutSet.workoutExercise = newWorkoutExercise
                        newWorkoutSet.isCompleted = false
                        if !blank {
                            let repetitions = workoutSet.repetitionsValue
                            newWorkoutSet.minTargetRepetitionsValue = repetitions
                            newWorkoutSet.maxTargetRepetitionsValue = repetitions
                            // don't copy weight, RPE, tag, comment, etc.
                        }
                    }
                }
            }
        }
        
        return newWorkout
    }
}

import CoreData
extension Workout {
    func startOrCrash(startWatchCompanionErrorHandler: WatchConnectionManager.StartWatchCompanionErrorHandler? = nil) {
        do {
            os_log("Starting workout", log: .workoutData)
            try start(startWatchCompanionErrorHandler: startWatchCompanionErrorHandler)
        } catch {
            let errorDescription = NSManagedObjectContext.descriptionWithDetailedErrors(error: error as NSError)
            os_log("Could not start workout: %@", log: .workoutData, type: .error, errorDescription)
            fatalError("Could not start workout: \(errorDescription)")
        }
    }
    
    func cancelOrCrash() {
        do {
            os_log("Cancelling workout", log: .workoutData)
            try cancel()
        } catch {
            let errorDescription = NSManagedObjectContext.descriptionWithDetailedErrors(error: error as NSError)
            os_log("Could not cancel workout: %@", log: .workoutData, type: .error, errorDescription)
            fatalError("Could not cancel workout: \(errorDescription)")
        }
    }
    
    func finishOrCrash() {
        do {
            os_log("Finishing workout", log: .workoutData)
            try finish()
        } catch {
            let errorDescription = NSManagedObjectContext.descriptionWithDetailedErrors(error: error as NSError)
            os_log("Could not finish workout: %@", log: .workoutData, type: .error, errorDescription)
            fatalError("Could not finish workout: \(errorDescription)")
        }
    }
    
    func deleteOrCrash() {
        do {
            os_log("Deleting workout", log: .workoutData)
            try delete()
        } catch {
            let errorDescription = NSManagedObjectContext.descriptionWithDetailedErrors(error: error as NSError)
            os_log("Could not delete workout: %@", log: .workoutData, type: .error, errorDescription)
            fatalError("Could not delete workout: \(errorDescription)")
        }
    }
}
