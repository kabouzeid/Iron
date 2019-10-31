//
//  HealthManager.swift
//  Iron
//
//  Created by Karim Abou Zeid on 02.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import HealthKit

class HealthManager {
    static let shared = HealthManager()
    
    let healthStore: HKHealthStore
    
    private init() {
        self.healthStore = HKHealthStore()
    }
}

extension HealthManager {
    private func requestPermissions(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping () -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            guard success else {
                if let error = error { print(error) }
                return
            }
            completion()
        }
    }
    
    func requestReadBodyWeightPermission(completion: @escaping () -> Void) {
        let read = Set([
            HKObjectType.quantityType(forIdentifier: .bodyMass)
        ].compactMap { $0 })
        requestPermissions(toShare: nil, read: read, completion: completion)
    }
    
    func requestShareWorkoutPermission(completion: @escaping () -> Void) {
        let share: Set = [HKObjectType.workoutType()]
        requestPermissions(toShare: share, read: nil, completion: completion)
    }
}

import CoreData
extension HealthManager {
    enum UpdateError: Error {
        case noSuccess
        case noHKWorkouts
    }
    
    func updateHealthWorkouts(managedObjectContext: NSManagedObjectContext, exerciseStore: ExerciseStore, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.requestShareWorkoutPermission {
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
                            completion(.failure(error))
                            return
                        }
                        guard let workoutSamples = samples as? [HKWorkout] else {
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
                                
                                let workoutSamplesToDelete = workoutSamples.filter { workoutSample in
                                    !workouts.contains(where: { workout in
                                        self.datesApproximatelyEqual(date1: workout.safeStart, date2: workoutSample.startDate) &&
                                            self.datesApproximatelyEqual(date1: workout.safeEnd, date2: workoutSample.endDate)
                                    })
                                }
                                if !workoutSamplesToDelete.isEmpty {
                                    group.enter()
                                    self.healthStore.delete(workoutSamplesToDelete) { success, error in
                                        _success = _success && success
                                        _error = error
                                        group.leave()
                                    }
                                }
                                
                                let workoutSamplesToSave: [HKWorkout] = workouts.filter { workout in
                                    !workoutSamples.contains(where: { workoutSample in
                                        self.datesApproximatelyEqual(date1: workout.safeStart, date2: workoutSample.startDate) &&
                                            self.datesApproximatelyEqual(date1: workout.safeEnd, date2: workoutSample.endDate)
                                    })
                                }
                                .compactMap { workout in
                                    guard let start = workout.start, let end = workout.end, let duration = workout.duration else { return nil } // should never fail
                                    let title = workout.displayTitle(in: exerciseStore.exercises)
                                    return HKWorkout(activityType: .traditionalStrengthTraining, start: start, end: end, duration: duration, totalEnergyBurned: nil, totalDistance: nil, device: .local(), metadata: [HKMetadataKeyWorkoutBrandName : title])
                                }
                                if !workoutSamplesToSave.isEmpty {
                                    group.enter()
                                    self.healthStore.save(workoutSamplesToSave) { success, error in
                                        _success = success
                                        _error = error
                                        group.leave()
                                    }
                                }
                                
                                group.wait()
                                if _success {
                                    completion(.success(()))
                                } else if let error = _error {
                                    completion(.failure(error))
                                } else {
                                    completion(.failure(UpdateError.noSuccess))
                                }
                            } catch {
                                completion(.failure(error))
                            }
                        }
                }
                HealthManager.shared.healthStore.execute(query)
            }
        }
    }
    
    private func datesApproximatelyEqual(date1: Date, date2: Date) -> Bool {
        date1.timeIntervalSince(date2).magnitude < 1
    }
}
