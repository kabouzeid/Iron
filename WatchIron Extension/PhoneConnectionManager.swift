//
//  PhoneConnectionManager.swift
//  WatchIron Extension
//
//  Created by Karim Abou Zeid on 02.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WatchConnectivity
import Combine
import HealthKit

class PhoneConnectionManager: NSObject, ObservableObject {
    static let shared = PhoneConnectionManager()
    
    private let session = WCSession.default
    
    var objectWillChange = ObservableObjectPublisher() // called when something with the connection changes
    
    func activateSession() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }
    
    var isReachable: Bool {
        session.isReachable
    }
    
    var isActivated: Bool {
        session.activationState == .activated
    }
}

// MARK: - Receiving
extension PhoneConnectionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print(#function + " \(activationState)")
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print(#function + " \(applicationContext)")
        
        receive(message: applicationContext)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print(#function + " \(userInfo)")
        
        receive(message: userInfo)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print(#function + " \(message)")
        
        receive(message: message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print(#function + " \(message)")
        
        receive(message: message)
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print(#function + " \(session.isReachable)")
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

// MARK: - Message Handling
extension PhoneConnectionManager {
    private func receive(message: [String : Any]) {
        if let startMessage = message[PayloadKey.startWorkoutSession] as? [String : Any] {
            handleStartWorkoutSessionMessage(message: startMessage)
        } else if let endMessage = message[PayloadKey.endWorkoutSession] as? [String : Any] {
            handleEndWorkoutSessionMessage(message: endMessage)
        } else if let updateStartMessage = message[PayloadKey.updateWorkoutSessionStart] as? [String : Any] {
            handleUpdateWorkoutSessionStartMessage(message: updateStartMessage)
        } else if let updateEndMessage = message[PayloadKey.updateWorkoutSessionEnd] as? [String : Any] {
            handleUpdateWorkoutSessionEndMessage(message: updateEndMessage)
        } else if let discardMessage = message[PayloadKey.discardWorkoutSession] as? [String : Any] {
            handleDiscardWorkoutSessionMessage(message: discardMessage)
        } else if let unprepare = message[PayloadKey.unprepareWorkoutSession] as? Bool, unprepare {
            handleUnprepareWorkoutSession()
        }
    }
    
    /**
     starts the workout session with the given uuid
     if there is a current workout session with the same uuid, only the start date will be updated
     if there is a current workout session with a different uuid, it is discarded and a new workout session is started
     */
    private func handleStartWorkoutSessionMessage(message: [String : Any]) {
        guard let start = message[PayloadKey.Arg.start] as? Date else {
            assertionFailure("start workout with no start parameter")
            return
        }
        guard let uuidString = message[PayloadKey.Arg.uuid] as? String, let uuid = UUID(uuidString: uuidString) else {
            assertionFailure("start workout with no uuid parameter")
            return
        }
        
        WorkoutSessionManager.perform {
            var workoutSessionManager: WorkoutSessionManager
            if let manager = WorkoutSessionManagerStore.shared.workoutSessionManager {
                workoutSessionManager = manager
            } else {
                print("warning: received start message but no workout session manager is set, creating new workout session")
                let workoutConfiguration = HKWorkoutConfiguration()
                workoutConfiguration.activityType = .traditionalStrengthTraining
                do {
                    let workoutSession = try HKWorkoutSession(healthStore: WorkoutSessionManager.healthStore, configuration: workoutConfiguration)
                    workoutSessionManager = WorkoutSessionManager(session: workoutSession)
                    WorkoutSessionManagerStore.shared.workoutSessionManager = workoutSessionManager
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
                WorkoutSessionManagerStore.shared.workoutSessionManager = nil
                do {
                    let workoutSession = try HKWorkoutSession(healthStore: WorkoutSessionManager.healthStore, configuration: workoutSessionManager.workoutSession.workoutConfiguration)
                    workoutSessionManager = WorkoutSessionManager(session: workoutSession)
                    WorkoutSessionManagerStore.shared.workoutSessionManager = workoutSessionManager
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
                WorkoutSessionManagerStore.shared.workoutSessionManager = nil
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
                        WorkoutSessionManagerStore.shared.workoutSessionManager = nil
                    }
                }
            }
        }
    }
    
    private func handleEndWorkoutSessionMessage(message: [String : Any]) {
        // this message is only valid if the current workoutSession was started with the same UUID
        
        guard let start = message[PayloadKey.Arg.start] as? Date else {
            assertionFailure("end workout with no start parameter")
            return
        }
        guard let end = message[PayloadKey.Arg.end] as? Date else {
            assertionFailure("end workout with no end parameter")
            return
        }
        guard let uuidString = message[PayloadKey.Arg.uuid] as? String, let uuid = UUID(uuidString: uuidString) else {
            assertionFailure("end workout with no uuid parameter")
            return
        }
        
        WorkoutSessionManager.perform {
            guard let workoutSessionManager = WorkoutSessionManagerStore.shared.workoutSessionManager else {
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
                    assertionFailure("attempt to end workout with no UUID")
                } else {
                    assertionFailure("attempt to end workout with different UUID")
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
                        WorkoutSessionManagerStore.shared.workoutSessionManager = nil
                        print("success: ended workout session")
                    case .failure(let error):
                        print(error)
                        workoutSessionManager.discard()
                        WorkoutSessionManagerStore.shared.workoutSessionManager = nil
                    }
                }
            }
        }
    }
    
    private func handleUpdateWorkoutSessionStartMessage(message: [String : Any]) {
        // this message is only valid if the current workoutSession was started with the same UUID
        
        guard let start = message[PayloadKey.Arg.start] as? Date else {
            assertionFailure("update workout start with no start parameter")
            return
        }
        guard let uuidString = message[PayloadKey.Arg.uuid] as? String, let uuid = UUID(uuidString: uuidString) else {
            assertionFailure("update workout start with no uuid parameter")
            return
        }
        
        WorkoutSessionManager.perform {
            guard let workoutSessionManager = WorkoutSessionManagerStore.shared.workoutSessionManager else {
                // invalid
                assertionFailure("attempt to update start time on workout while no workout session manager is set")
                return
            }
            
            // make sure the message means the current workout
            guard workoutSessionManager.uuid == uuid else {
                // invalid
                if workoutSessionManager.uuid == nil {
                    assertionFailure("attempt to update start for workout with no UUID")
                } else {
                    assertionFailure("attempt to update start for workout with different UUID")
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
    
    private func handleUpdateWorkoutSessionEndMessage(message: [String : Any]) {
        // this message is only valid if the current workoutSession was started with the same UUID
        
        let end = message[PayloadKey.Arg.end] as? Date // nil is allowed
        guard let uuidString = message[PayloadKey.Arg.uuid] as? String, let uuid = UUID(uuidString: uuidString) else {
            assertionFailure("update workout end with no uuid parameter")
            return
        }
        
        WorkoutSessionManager.perform {
            guard let workoutSessionManager = WorkoutSessionManagerStore.shared.workoutSessionManager else {
                // invalid
                assertionFailure("attempt to update end time on workout while no workout session manager is set")
                return
            }
            
            // make sure the message means the current workout
            guard workoutSessionManager.uuid == uuid else {
                // invalid
                if workoutSessionManager.uuid == nil {
                    assertionFailure("attempt to update end for workout with no UUID")
                } else {
                    assertionFailure("attempt to update end for workout with different UUID")
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
    
    private func handleDiscardWorkoutSessionMessage(message: [String : Any]) {
        // this message is only valid if the current workoutSession was started with the same UUID
        
        guard let uuidString = message[PayloadKey.Arg.uuid] as? String, let uuid = UUID(uuidString: uuidString) else {
            assertionFailure("discard workout with no uuid parameter")
            return
        }
        
        WorkoutSessionManager.perform {
            guard let workoutSessionManager = WorkoutSessionManagerStore.shared.workoutSessionManager else {
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
            WorkoutSessionManagerStore.shared.workoutSessionManager = nil
            print("success: discarded workout session")
        }
    }
    
    private func handleUnprepareWorkoutSession() {
        WorkoutSessionManager.perform {
            guard let workoutSessionManager = WorkoutSessionManagerStore.shared.workoutSessionManager else {
                // invalid
                // should not happen normally, but can happen
                assertionFailure("attempt to unprepare workout session while no workout session manager is set")
                return
            }
            
            guard workoutSessionManager.state == .prepared || workoutSessionManager.state == .notStarted else {
                // can happen, but something probably went wrong before
                print("warning: attempt to unprepare workout session that is not in .prepared or .notStarted state")
                return
            }
            
            workoutSessionManager.discard()
            WorkoutSessionManagerStore.shared.workoutSessionManager = nil
            print("success: unprepared workout session")
        }
    }
}

// MARK: - Sending
extension PhoneConnectionManager {
    /// wrapper to send either via message or transfer, depending on what's available
    private func sendUserInfo(userInfo: [String : Any]) {
        if session.isReachable {
            session.sendMessage(userInfo, replyHandler: nil) { error in
                self.session.transferUserInfo(userInfo)
            }
        } else {
            session.transferUserInfo(userInfo)
        }
    }
    
    func sendPreparedWorkoutSession() {
        print("send prepared workout session message")
        sendUserInfo(userInfo: [PayloadKey.preparedWorkoutSession : true])
    }
}
