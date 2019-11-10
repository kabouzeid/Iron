//
//  WorkoutSessionManagerStore.swift
//  WatchIron Extension
//
//  Created by Karim Abou Zeid on 09.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import HealthKit
import Combine

class WorkoutSessionManagerStore: ObservableObject {
    static let shared = WorkoutSessionManagerStore()
    
    let objectWillChange = ObjectWillChangePublisher()
    
    private var _workoutSessionManager: WorkoutSessionManager? {
        didSet { // don't use willSet, somehow this is sometimes to early in this case
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    var workoutSessionManager: WorkoutSessionManager? {
        get {
            return _workoutSessionManager
        }
        set {
            dispatchPrecondition(condition: DispatchPredicate.onQueue(WorkoutSessionManager.accessQueue))
            _workoutSessionManager = newValue
        }
    }
}

extension WorkoutSessionManagerStore {
    func ensurePreparedWorkoutSession(configuration: HKWorkoutConfiguration, completion: @escaping (Result<Void, Error>) -> Void) {
        WorkoutSessionManager.perform {
            // check if there already is a current workout session
            if let workoutSessionManager = self.workoutSessionManager {
                let state = workoutSessionManager.state
                // only create a new session if the current session is not running
                guard state == .ended || state == .notStarted else {
                    // there already is a running workout session, startWorkout will take care of it
                    completion(.success(()))
                    return
                }
            }
            
            do {
                let workoutSession = try HKWorkoutSession(healthStore: WorkoutSessionManager.healthStore, configuration: configuration)
                self.workoutSessionManager = WorkoutSessionManager(session: workoutSession)
            } catch {
                completion(.failure(error))
                return
            }
            
            guard let workoutSessionManager = self.workoutSessionManager else {
                completion(.failure(NSError()))
                return
            }
            do {
                try workoutSessionManager.prepare()
            } catch {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    func startWorkoutSession(start: Date, uuid: UUID) {
        WorkoutSessionManager.perform {
            var workoutSessionManager: WorkoutSessionManager
            if let manager = self.workoutSessionManager {
                workoutSessionManager = manager
            } else {
                print("warning: received start message but no workout session manager is set, creating new workout session")
                let workoutConfiguration = HKWorkoutConfiguration()
                workoutConfiguration.activityType = .traditionalStrengthTraining
                do {
                    let workoutSession = try HKWorkoutSession(healthStore: WorkoutSessionManager.healthStore, configuration: workoutConfiguration)
                    workoutSessionManager = WorkoutSessionManager(session: workoutSession)
                    self.workoutSessionManager = workoutSessionManager
                } catch {
                    print("could not create new workout session: \(error)")
                    return
                }
            }
            
            if let currentUuid = workoutSessionManager.uuid {
                guard currentUuid != uuid else {
                    // the workout session was already started
                    if workoutSessionManager.state != .ended {
                        do {
                             try workoutSessionManager.updateStartDate(start)
                         } catch {
                             print("could not update start date: \(error)")
                         }
                    } else {
                        print("warning: received start message for workout session that is already ended")
                    }
                    return
                }
                
                if workoutSessionManager.state != .ended {
                    print("warning: discarding workout session \(currentUuid) and starting workout session \(uuid)")
                    workoutSessionManager.discard()
                }
                self.workoutSessionManager = nil
                do {
                    let workoutSession = try HKWorkoutSession(healthStore: WorkoutSessionManager.healthStore, configuration: workoutSessionManager.workoutSession.workoutConfiguration)
                    workoutSessionManager = WorkoutSessionManager(session: workoutSession)
                    self.workoutSessionManager = workoutSessionManager
                } catch {
                    print("could not create new workout session: \(error)")
                    return
                }
            }
            
            do {
                try workoutSessionManager.setUuid(uuid)
            } catch {
                print(error)
                workoutSessionManager.discard()
                self.workoutSessionManager = nil
                return
            }
            
            workoutSessionManager.start(start: start) { result in
                switch result {
                case .success:
                    // TODO send confirmation
                    print("success: started workout session")
                case .failure(let error):
                    print(error)
                    WorkoutSessionManager.perform {
                        workoutSessionManager.discard()
                        self.workoutSessionManager = nil
                    }
                }
            }
        }
    }
    
    func endWorkoutSession(start: Date, end: Date, uuid: UUID) {
        WorkoutSessionManager.perform {
            guard let workoutSessionManager = self.workoutSessionManager else {
                // invalid
                // should not happen normally, but can happen
                assertionFailure("attempt to end workout while no workout session manager is set")
                return
            }
            
            // make sure the message means the current workout
            guard workoutSessionManager.uuid == uuid else {
                // invalid
                // should not happen normally, but can happen
                if workoutSessionManager.uuid == nil {
                    print("warning: attempt to end workout with no UUID")
                } else {
                    print("warning: attempt to end workout with different UUID")
                }
                return
            }
            
            do {
                try workoutSessionManager.updateStartDate(start)
            } catch {
                print("could not update start date: \(error)")
                // continue though
            }
            workoutSessionManager.end(end: end) { result in
                WorkoutSessionManager.perform {
                    switch result {
                    case .success:
                        self.workoutSessionManager = nil
                        print("success: ended workout session")
                    case .failure(let error):
                        print(error)
                        workoutSessionManager.discard()
                        self.workoutSessionManager = nil
                    }
                }
            }
        }
    }
    
    func updateWorkoutSessionStart(start: Date, uuid: UUID) {
        WorkoutSessionManager.perform {
            guard let workoutSessionManager = self.workoutSessionManager else {
                // invalid
                print("warning: attempt to update start time on workout while no workout session manager is set")
                return
            }
            
            // make sure the message means the current workout
            guard workoutSessionManager.uuid == uuid else {
                // invalid
                if workoutSessionManager.uuid == nil {
                    print("warning: attempt to update start for workout with no UUID")
                } else {
                    print("warning: attempt to update start for workout with different UUID")
                }
                return
            }
            
            do {
                try workoutSessionManager.updateStartDate(start)
            } catch {
                print(error)
                // TODO: should we discard() ?
                return
            }
        }
    }
    
    func updateWorkoutSessionEnd(end: Date?, uuid: UUID) {
        WorkoutSessionManager.perform {
            guard let workoutSessionManager = self.workoutSessionManager else {
                // invalid
                print("warning: attempt to update end time on workout while no workout session manager is set")
                return
            }
            
            // make sure the message means the current workout
            guard workoutSessionManager.uuid == uuid else {
                // invalid
                if workoutSessionManager.uuid == nil {
                    print("warning: attempt to update end for workout with no UUID")
                } else {
                    print("warning: attempt to update end for workout with different UUID")
                }
                return
            }
            
            do {
                try workoutSessionManager.updateEndDate(end)
            } catch {
                print(error)
                // TODO: should we discard() ?
                return
            }
        }
    }
    
    func discardWorkoutSession(uuid: UUID) {
        WorkoutSessionManager.perform {
            guard let workoutSessionManager = self.workoutSessionManager else {
                // invalid
                // should not happen normally, but can happen
                print("warning: attempt to discard workout while no workout session manager is set")
                return
            }
            
            // make sure the message means the current workout
            guard workoutSessionManager.uuid == uuid else {
                // invalid
                // should not happen normally, but can happen
                print("warning: attempt to discard workout with different UUID")
                return
            }
            
            workoutSessionManager.discard()
            self.workoutSessionManager = nil
            print("success: discarded workout session")
        }
    }
    
    func unprepareWorkoutSession() {
        WorkoutSessionManager.perform {
            guard let workoutSessionManager = self.workoutSessionManager else {
                // invalid
                // should not happen normally, but can happen
                print("warning: attempt to unprepare workout session while no workout session manager is set")
                return
            }
            
            guard workoutSessionManager.state == .prepared || workoutSessionManager.state == .notStarted else {
                // can happen, but something probably went wrong before
                print("warning: attempt to unprepare workout session that is not in .prepared or .notStarted state")
                return
            }
            
            workoutSessionManager.discard()
            self.workoutSessionManager = nil
            print("success: unprepared workout session")
        }
    }
}
