//
//  HealthManager.swift
//  Iron
//
//  Created by Karim Abou Zeid on 02.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import HealthKit
import WorkoutDataKit
import os.log

class HealthManager {
    static let shared = HealthManager()
    
    let healthStore: HKHealthStore
    
    private init() {
        self.healthStore = HKHealthStore()
    }
}

extension HealthManager {
    // completion is called on a background queue!
    private func requestPermissions(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping () -> Void) {
        #if DEBUG
        guard !CommandLine.arguments.contains("-FASTLANE_SNAPSHOT") else { return }
        #endif
        
        os_log("Requesting HealthKit permissions share=%@ read=%@", log: .health, type: .default, typesToShare ?? [], typesToRead ?? [])
        
        guard HKHealthStore.isHealthDataAvailable() else {
            os_log("HealthKit is not available on this device", log: .health, type: .error)
            return
        }
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            guard success else {
                os_log("Could not request health authorization: %@", log: .health, type: .fault, error?.localizedDescription ?? "nil")
                return
            }
            completion()
        }
    }
    
    // completion is called on a background queue!
    func requestReadBodyWeightPermission(completion: @escaping () -> Void) {
        let read = Set([
            HKObjectType.quantityType(forIdentifier: .bodyMass)
        ].compactMap { $0 })
        requestPermissions(toShare: nil, read: read, completion: completion)
    }
    
    // completion is called on a background queue!
    func requestShareWorkoutPermission(completion: @escaping () -> Void) {
        let share: Set = [HKObjectType.workoutType()]
        requestPermissions(toShare: share, read: nil, completion: completion)
    }
}

extension HealthManager {
    var workoutConfiguration: HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        return configuration
    }
    
    func saveWorkout(workout: Workout, exerciseStore: ExerciseStore) {
        requestShareWorkoutPermission {
            DispatchQueue.main.async {
                guard let uuid = workout.uuid, let start = workout.start, let end = workout.end, let duration = workout.duration else { return }
                var metadata: [String : Any] = [HKMetadataKeyExternalUUID : uuid.uuidString]
                if let title = workout.optionalDisplayTitle(in: exerciseStore.exercises) {
                    metadata[HKMetadataKeyWorkoutBrandName] = title
                }
                let hkWorkout = HKWorkout(activityType: self.workoutConfiguration.activityType, start: start, end: end, duration: duration, totalEnergyBurned: nil, totalDistance: nil, device: .local(), metadata: metadata)
                self.healthStore.save(hkWorkout) { _,_ in }
            }
        }
    }
    
    func deleteWorkout(workout: Workout) {
        guard let uuid = workout.uuid else { return }
        
        let uuidPredicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyExternalUUID, allowedValues: [uuid.uuidString])
        let sourcePredicate = HKQuery.predicateForObjects(from: .default())
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [uuidPredicate, sourcePredicate])
        
        os_log("Deleting HealthKit workout with uuid=%@", log: .health, uuid as NSUUID)
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil) { (query, samples, error) in
                if let error = error {
                    os_log("Could not query HealthKit workout with uuid=%@: %@", log: .health, type: .fault, uuid as NSUUID, error.localizedDescription)
                    return
                }
                guard let workoutSample = samples?.first as? HKWorkout else {
                    os_log("No HealthKit workout with uuid=%@", log: .health, type: .fault, uuid as NSUUID)
                    return
                }
                
                self.healthStore.delete(workoutSample) { success, error in
                    guard success else {
                        os_log("Could not delete HealthKit workout with uuid=%@: %@", log: .health, type: .fault, uuid as NSUUID, error?.localizedDescription ?? "nil")
                        return
                    }
                    os_log("Successfully deleted HealthKit workout with uuid=%@", log: .health, type: .info, uuid as NSUUID)
                }
        }
        healthStore.execute(query)
    }
}

import CoreData
extension HealthManager {
    enum UpdateError: Error {
        case noSuccess
        case noHKWorkouts
    }
    
    struct WorkoutUpdates {
        let created: Int
        let deleted: Int
        let modified: Int
    }
    
    func updateHealthWorkouts(managedObjectContext: NSManagedObjectContext, exerciseStore: ExerciseStore, completion: @escaping (Result<WorkoutUpdates, Error>) -> Void) {
        os_log("Updating HealthKit workouts", log: .health, type: .default)
        
        self.requestShareWorkoutPermission {
            DispatchQueue.global(qos: .background).async {
                let workoutPredicate = HKQuery.predicateForWorkouts(with: .traditionalStrengthTraining)
                let sourcePredicate = HKQuery.predicateForObjects(from: .default())
                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [workoutPredicate, sourcePredicate])
                let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
                
                let query = HKSampleQuery(
                    sampleType: .workoutType(),
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]) { query, samples, error in
                        if let error = error {
                            os_log("Could not query the HealthKit workout: %@", log: .health, type: .fault, error.localizedDescription)
                            completion(.failure(error))
                            return
                        }
                        guard let workoutSamples = samples as? [HKWorkout] else {
                            os_log("Could not cast to HealthKit workouts", log: .health, type: .fault)
                            completion(.failure(UpdateError.noHKWorkouts))
                            return
                        }
                        
                        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                        backgroundContext.parent = managedObjectContext
                        
                        backgroundContext.perform {
                            do {
                                let request: NSFetchRequest<Workout> = Workout.fetchRequest()
                                request.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) != %@", NSNumber(booleanLiteral: true))
                                request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
                                let workouts = try backgroundContext.fetch(request)
                                
                                let group = DispatchGroup()
                                var _success = true
                                var _error: Error? = nil
                                
                                // delete HealthKit workout samples that are not in the database
                                let workoutSamplesToDelete = workoutSamples.filter { workoutSample in
                                    guard let externalUuid = workoutSample.externalUuid else { return true } // if the uuid is missing --> delete
                                    // if there is no workout for this uuid --> delete
                                    return !workouts.contains { $0.uuid == externalUuid }
                                }
                                os_log("Deleting HealthKit workouts: %@", log: .health, type: .info, workoutSamplesToDelete)
                                if !workoutSamplesToDelete.isEmpty {
                                    group.enter()
                                    self.healthStore.delete(workoutSamplesToDelete) { success, error in
                                        _success = _success && success
                                        _error = error
                                        group.leave()
                                    }
                                }
                                let deletedCount = workoutSamplesToDelete.count
                                
                                // save workouts that are missing from HealthKit
                                let workoutSamplesToSave: [HKWorkout] = workouts.filter { workout in
                                    guard let uuid = workout.uuid else { return false } // if the uuid is missing (should never happen) --> don't save
                                    // if there is no workout sample for this uuid --> save
                                    return !workoutSamples.contains { $0.externalUuid == uuid }
                                }
                                .compactMap { workout in
                                    guard let uuid = workout.uuid, let start = workout.start, let end = workout.end, let duration = workout.duration else { return nil } // should never fail
                                    var metadata: [String : Any] = [HKMetadataKeyExternalUUID : uuid.uuidString]
                                    if let title = workout.optionalDisplayTitle(in: exerciseStore.exercises) {
                                        metadata[HKMetadataKeyWorkoutBrandName] = title
                                    }
                                    return HKWorkout(activityType: .traditionalStrengthTraining, start: start, end: end, duration: duration, totalEnergyBurned: nil, totalDistance: nil, device: .local(), metadata: metadata)
                                }
                                os_log("Saving HealthKit workouts %@", log: .health, type: .info, workoutSamplesToSave)
                                if !workoutSamplesToSave.isEmpty {
                                    group.enter()
                                    self.healthStore.save(workoutSamplesToSave) { success, error in
                                        _success = success
                                        _error = error
                                        group.leave()
                                    }
                                }
                                let createdCount = workoutSamplesToSave.count
                                
                                // update start / end times
                                let workoutSamplesToModify: [(HKWorkout, Workout)] = workouts.compactMap { workout in
                                    guard let uuid = workout.uuid else { return nil }
                                    guard let workoutSample = workoutSamples.first(where: { $0.externalUuid == uuid }) else { return nil }
                                    return (workoutSample, workout)
                                }
                                .filter {
                                    !self.approximatelyEqual(date1: $0.0.startDate, date2: $0.1.safeStart) || !self.approximatelyEqual(date1: $0.0.endDate, date2: $0.1.safeEnd)
                                }
                                os_log("Modifying HealthKit workouts %@", log: .health, type: .info, workoutSamplesToModify)
                                var modifiedCount = 0
                                if !workoutSamplesToModify.isEmpty {
                                    group.enter()
                                    self.healthStore.delete(workoutSamplesToModify.map { $0.0 }) { success, error in
                                        _success = _success && success
                                        _error = error
                                        group.leave()
                                    }
                                    
                                    let modifiedWorkoutSamples = workoutSamplesToModify.compactMap { workoutSample, workout -> HKWorkout? in
                                        guard let start = workout.start, let end = workout.end, let duration = workout.duration else { return nil }
                                        
                                        var metadata = workoutSample.metadata
                                        if let title = workout.optionalDisplayTitle(in: exerciseStore.exercises) {
                                            metadata?[HKMetadataKeyWorkoutBrandName] = title
                                        }
                                        
                                        return HKWorkout(activityType: workoutSample.workoutActivityType, start: start, end: end, duration: duration, totalEnergyBurned: workoutSample.totalEnergyBurned, totalDistance: workoutSample.totalDistance, device: workoutSample.device, metadata: metadata)
                                    }
                                    
                                    group.enter()
                                    self.healthStore.save(modifiedWorkoutSamples) { success, error in
                                        _success = _success && success
                                        _error = error
                                        group.leave()
                                    }
                                    modifiedCount = modifiedWorkoutSamples.count
                                }
                                
                                group.wait()
                                if _success {
                                    os_log("Successfully updated HealthKit workouts", log: .health, type: .default)
                                    completion(.success((WorkoutUpdates(created: createdCount, deleted: deletedCount, modified: modifiedCount))))
                                } else if let error = _error {
                                    os_log("Could not update HealthKit workouts: %@", log: .health, type: .error, error.localizedDescription)
                                    completion(.failure(error))
                                } else {
                                    os_log("Could not update HealthKit workouts", log: .health, type: .error)
                                    completion(.failure(UpdateError.noSuccess))
                                }
                            } catch {
                                os_log("Could not update HealthKit workouts: %@", log: .health, type: .error, error.localizedDescription)
                                completion(.failure(error))
                            }
                        }
                }
                self.healthStore.execute(query)
            }
        }
    }
    
    private func approximatelyEqual(date1: Date, date2: Date) -> Bool {
        abs(date1.timeIntervalSince(date2)) < 1
    }
}

extension HKWorkout {
    var externalUuid: UUID? {
        guard let externalUuidString = metadata?[HKMetadataKeyExternalUUID] as? String else { return nil }
        return UUID(uuidString: externalUuidString)
    }
}
