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
import WatchKit
import os.log

class WorkoutSessionManagerStore: ObservableObject {
    static let shared = WorkoutSessionManagerStore()
    
    let objectWillChange = PassthroughSubject<Void, Never>()
    
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
    func recoverWorkoutSession(workoutSession: HKWorkoutSession) {
        WorkoutSessionManager.perform {
            assert(self.workoutSessionManager == nil)
            // TODO: also recover custom start / end dates
            let workoutSessionManager = WorkoutSessionManager(session: workoutSession) // documentation says this must happen immediately
            self.workoutSessionManager = workoutSessionManager
        }
    }
    
    
    /// - Parameters:
    ///   - completion: When the result is successful, the `workoutSessionManager` is set and the workout session is in a state other than `.ended` or `.notStarted`.
    ///                 If a workout session that is not `.ended` or `.notStarted` existed, nothing is done. Otherwise a new workout session is prepared.
    func ensurePreparedWorkoutSession(configuration: HKWorkoutConfiguration, completion: @escaping (Result<Void, Error>) -> Void) {
        WorkoutSessionManager.perform {
            os_log("Ensuring prepared workout session")
            // check if there already is a current workout session
            if let workoutSessionManager = self.workoutSessionManager {
                let state = workoutSessionManager.state
                os_log("Workout session manager with state=%@ exists", type: .debug, state.name)
                // only create a new session if the current session is not running
                guard state == .ended || state == .notStarted else {
                    // there already is a running workout session, startWorkout will take care of it
                    os_log("Keeping workout session with state=%@", state.name)
                    completion(.success(()))
                    return
                }
            }
            
            let workoutSession: HKWorkoutSession
            do {
                os_log("Creating new workout session")
                workoutSession = try HKWorkoutSession(healthStore: WorkoutSessionManager.healthStore, configuration: configuration)
            } catch {
                completion(.failure(error))
                return
            }
            
            self.workoutSessionManager = WorkoutSessionManager(session: workoutSession)
            self.workoutSessionManager?.prepare()
            
            completion(.success(()))
        }
    }
    
    /**
     Starts a `WorkoutSessionManager`, creating/reusing/overwriting any existing `workoutSessionManager` as necessary.
     - Postcondition
     If an error occured, `workoutSessionManager` is set to `nil`, otherwise `workoutSessionManager.uuid` is set to `uuid` and the `workoutSessionManager` is being started.
     */
    func startWorkoutSession(start: Date, uuid: UUID) {
        WorkoutSessionManager.perform {
            os_log("Starting workout session start=%@ uuid=%@", start as NSDate, uuid as NSUUID)
            
            // 1. make sure we have a workout session manager, create it if necessary
            
            var workoutSessionManager: WorkoutSessionManager
            if let manager = self.workoutSessionManager {
                workoutSessionManager = manager
            } else {
                os_log("No workout session manager is set", type: .info)
                
                let workoutConfiguration = HKWorkoutConfiguration()
                workoutConfiguration.activityType = .traditionalStrengthTraining
                
                // create a new workout session manager
                do {
                    os_log("Creating workout session")
                    let session = try HKWorkoutSession(healthStore: WorkoutSessionManager.healthStore, configuration: workoutConfiguration)
                    workoutSessionManager = WorkoutSessionManager(session: session)
                    self.workoutSessionManager = workoutSessionManager
                } catch {
                    os_log("Could not create new workout session: %@", type: .error, error.localizedDescription)
                    return
                }
            }
            
            // 2. What if the session is not .prepared or .notStarted ?
            
            if let currentUuid = workoutSessionManager.uuid {
                // consider workout session manager as started
                os_log("Workout session manager already has uuid, treating as already started", type: .fault, workoutSessionManager.state.name)
                
                if currentUuid == uuid {
                    
                    // 2.1 If the workout session manager has the same uuid, reuse the manager or create a new if the state is .ended
                    
                    os_log("Workout session manager uuid=%@ matches new uuid", type: .fault, currentUuid as NSUUID, workoutSessionManager.state.name)
                    switch workoutSessionManager.state {
                    case .prepared, .notStarted:
                        break
                    case .ended:
                        // we can have a ended workout session manager that was not set to nil when it was ended by the OS
                        os_log("Discarding workout session manager")
                        workoutSessionManager.discard()
                        self.workoutSessionManager = nil
                        
                        // create a new workout session manager
                        do {
                            os_log("Creating workout session")
                            let session = try HKWorkoutSession(healthStore: WorkoutSessionManager.healthStore, configuration: workoutSessionManager.workoutConfiguration)
                            workoutSessionManager = WorkoutSessionManager(session: session)
                            self.workoutSessionManager = workoutSessionManager
                        } catch {
                            os_log("Could not create new workout session: %@", type: .error, error.localizedDescription)
                            return
                        }
                    default:
                        // the session is not ended and was already started, reuse it
                        os_log("Falling back to just updating the start date for workout session manager")
                        workoutSessionManager.updateStartDate(start)
                        return
                    }
                    
                } else {
                    
                    // 2.2 If the workout session manager has a different uuid, create a new manager
                    
                    os_log("Workout session manager uuid=%@ differs from new uuid=%@", type: .fault, (currentUuid as NSUUID?) ?? "nil", uuid as NSUUID)
                    
                    os_log("Discarding workout session manager")
                    workoutSessionManager.discard()
                    self.workoutSessionManager = nil
                    
                    do {
                        os_log("Creating workout session")
                        let session = try HKWorkoutSession(healthStore: WorkoutSessionManager.healthStore, configuration: workoutSessionManager.workoutConfiguration)
                        workoutSessionManager = WorkoutSessionManager(session: session)
                        self.workoutSessionManager = workoutSessionManager
                    } catch {
                        os_log("Could not create new workout session: %@", type: .error, error.localizedDescription)
                        return
                    }
                }
            } else {
                // consider workout as not started
                switch workoutSessionManager.state {
                case .prepared, .notStarted:
                    break
                default:
                    os_log("Discarding workout session manager without uuid state=%@", type: .fault, workoutSessionManager.state.name)
                    assertionFailure("This should not happen, because a workout gets assigned a UUID when it is started")
                    workoutSessionManager.discard()
                    self.workoutSessionManager = nil
                    
                    // create a new workout session manager
                    do {
                        os_log("Creating workout session")
                        let session = try HKWorkoutSession(healthStore: WorkoutSessionManager.healthStore, configuration: workoutSessionManager.workoutConfiguration)
                        workoutSessionManager = WorkoutSessionManager(session: session)
                        self.workoutSessionManager = workoutSessionManager
                    } catch {
                        os_log("Could not create new workout session: %@", type: .error, error.localizedDescription)
                        return
                    }
                }
            }
            
            // 3. Set the UUID
            
            assert(workoutSessionManager.state == .prepared || workoutSessionManager.state == .notStarted)
            
            do {
                os_log("Setting uuid=%@ for workout session manager", uuid as NSUUID)
                try workoutSessionManager.setUuid(uuid)
            } catch {
                os_log("Could not set uuid: %@", type: .error, error.localizedDescription)
                os_log("Discarding workout session manager", type: .info)
                workoutSessionManager.discard()
                self.workoutSessionManager = nil
                return
            }
            
            // 4. Start!
            
            os_log("Starting workout session manager")
            workoutSessionManager.start(start: start) { result in
                switch result {
                case .success:
                    WKInterfaceDevice.current().play(.start)
                    // TODO send confirmation to phone
                    os_log("Successfully started workout session manager")
                case .failure(let error):
                    WKInterfaceDevice.current().play(.failure)
                    os_log("Could not start workout session manager: %@", type: .error, error.localizedDescription)
                    WorkoutSessionManager.perform {
                        os_log("Discarding workout session manager", type: .info)
                        workoutSessionManager.discard()
                        self.workoutSessionManager = nil
                    }
                }
            }
        }
    }
    
    func endWorkoutSession(start: Date, end: Date, title: String?, uuid: UUID) {
        WorkoutSessionManager.perform {
            os_log("Ending workout session start=%@ end=%@ title=%@ uuid=%@", start as NSDate, end as NSDate, title ?? "nil", uuid as NSUUID)
            
            guard let workoutSessionManager = self.workoutSessionManager else {
                // invalid
                // should not happen normally, but maybe could happen?
                os_log("Attempt to end workout session manager while no workout session manager is set", type: .fault)
                return
            }
            
            // make sure the message means the current workout
            guard workoutSessionManager.uuid == uuid else {
                // invalid
                // should not happen normally, but maybe could happen?
                if workoutSessionManager.uuid == nil {
                    os_log("Attempt to end workout session manager that has no UUID", type: .fault)
                } else {
                    os_log("Attempt to end workout session manager with different UUID", type: .fault)
                }
                return
            }
            
            workoutSessionManager.updateStartDate(start)

            if let title = title {
                do {
                    os_log("Setting title for workout session manager")
                    try workoutSessionManager.setTitle(title)
                } catch {
                    os_log("Could not set title: %@", type: .error, error.localizedDescription)
                    // continue though
                }
            }
            
            os_log("Ending workout session manager")
            workoutSessionManager.end(end: end) { result in
                WorkoutSessionManager.perform {
                    switch result {
                    case .success:
                        WKInterfaceDevice.current().play(.stop)
                        self.workoutSessionManager = nil
                        os_log("Successfully ended workout session manager", type: .info)
                    case .failure(let error):
                        WKInterfaceDevice.current().play(.failure)
                        os_log("Could not end workout session manager: %@", type: .error, error.localizedDescription)
                        os_log("Discarding workout session manager", type: .info)
                        workoutSessionManager.discard()
                        self.workoutSessionManager = nil
                    }
                }
            }
        }
    }
    
    func updateWorkoutSessionStart(start: Date, uuid: UUID) {
        WorkoutSessionManager.perform {
            os_log("Updating workout session start=%@ uuid=%@", start as NSDate, uuid as NSUUID)
            guard let workoutSessionManager = self.workoutSessionManager else {
                // invalid
                os_log("Attempt to update start time on workout while no workout session manager is set", type: .fault)
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
            
            workoutSessionManager.updateStartDate(start)
        }
    }
    
    func updateWorkoutSessionEnd(end: Date?, uuid: UUID) {
        WorkoutSessionManager.perform {
            os_log("Updating workout session end=%@ uuid=%@", (end as NSDate?) ?? "nil", uuid as NSUUID)
            guard let workoutSessionManager = self.workoutSessionManager else {
                // invalid
                print("warning: attempt to update end time on workout while no workout session manager is set")
                return
            }
            
            // make sure the message means the current workout
            guard workoutSessionManager.uuid == uuid else {
                // invalid
                // should not happen normally, but maybe could happen?
                if workoutSessionManager.uuid == nil {
                    os_log("Attempt to update end for workout session manager that has no UUID", type: .fault)
                } else {
                    os_log("Attempt to update end for workout session manager with different UUID", type: .fault)
                }
                return
            }
            
            workoutSessionManager.updateEndDate(end)
        }
    }
    
    func discardWorkoutSession(uuid: UUID) {
        WorkoutSessionManager.perform {
            os_log("Discarding workout session uuid=%@", uuid as NSUUID)
            guard let workoutSessionManager = self.workoutSessionManager else {
                // invalid
                // should not happen normally, but can happen
                print("warning: attempt to discard workout while no workout session manager is set")
                return
            }
            
            // make sure the message means the current workout
            guard workoutSessionManager.uuid == uuid else {
                // invalid
                // should not happen normally, but maybe could happen?
                if workoutSessionManager.uuid == nil {
                    os_log("Attempt to discard workout session manager that has no UUID", type: .fault)
                } else {
                    os_log("Attempt to discard workout session manager with different UUID", type: .fault)
                }
                return
            }
            
            workoutSessionManager.discard()
            self.workoutSessionManager = nil
            print("success: discarded workout session")
        }
    }
    
    func discardUnstartedWorkoutSession() {
        WorkoutSessionManager.perform {
            os_log("Discarding unstarted workout session")
            guard let workoutSessionManager = self.workoutSessionManager else {
                // invalid
                // should not happen normally, but can happen
                os_log("Attempt to discard unstarted workout session while no workout session manager is set", type: .fault)
                return
            }
            
            // make sure no UUID is set
            if let uuid = workoutSessionManager.uuid {
                // can happen, but something probably went wrong before
                os_log("Attempt to discard unstarted workout session with uuid=%@", type: .fault, uuid as NSUUID)
                return // treat a workout session with a UUID as started, return here!
            }
            
            guard workoutSessionManager.state == .prepared || workoutSessionManager.state == .notStarted else {
                // can happen, but something probably went wrong before
                os_log("Attempt to discard unstarted workout session with state=%@", type: .fault, workoutSessionManager.state.name)
                return
            }
            
            workoutSessionManager.discard()
            self.workoutSessionManager = nil
            os_log("Discarded unstarted workout session", type: .info)
        }
    }
    
    func discardWorkoutSession() {
        WorkoutSessionManager.perform {
            os_log("Discarding workout session")
            guard let workoutSessionManager = self.workoutSessionManager else {
                // invalid
                // should not happen normally, but can happen
                print("warning: attempt to discard workout session while no workout session manager is set")
                return
            }
            
            workoutSessionManager.discard()
            self.workoutSessionManager = nil
            print("success: discarded workout session")
        }
    }
    
    func updateWorkoutSessionRestTimerEnd(end: Date?, uuid: UUID) {
        WorkoutSessionManager.perform {
            os_log("Updating workout session rest timer end=%@ uuid=%@", (end as NSDate?) ?? "nil", uuid as NSUUID)
            guard let workoutSessionManager = self.workoutSessionManager else {
                // invalid
                // should not happen normally, but can happen
                print("warning: attempt to update rest timer end while no workout session manager is set")
                return
            }
            
            // make sure the message means the current workout
            guard workoutSessionManager.uuid == uuid else {
                // invalid
                // should not happen normally, but maybe could happen?
                if workoutSessionManager.uuid == nil {
                    os_log("Attempt to update rest timer for workout session manager that has no UUID", type: .fault)
                } else {
                    os_log("Attempt to update rest timer for workout session manager with different UUID", type: .fault)
                }
                return
            }
            
            workoutSessionManager.restTimerEnd = end
        }
    }
    
    func updateWorkoutSessionSelectedSetText(text: String?, uuid: UUID) {
        WorkoutSessionManager.perform {
            os_log("Updating workout session selected text=%@ uuid=%@", text ?? "nil", uuid as NSUUID)
            guard let workoutSessionManager = self.workoutSessionManager else {
                // invalid
                // should not happen normally, but can happen
                print("warning: attempt to update selected set text while no workout session manager is set")
                return
            }
            
            // make sure the message means the current workout
            guard workoutSessionManager.uuid == uuid else {
                // invalid
                // should not happen normally, but maybe could happen?
                if workoutSessionManager.uuid == nil {
                    os_log("Attempt to update selected text for workout session manager that has no UUID", type: .fault)
                } else {
                    os_log("Attempt to update selected text for workout session manager with different UUID", type: .fault)
                }
                return
            }
            
            workoutSessionManager.selectedSetText = text
        }
    }
}
