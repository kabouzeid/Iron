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
import os.log

class PhoneConnectionManager: NSObject, ObservableObject {
    static let shared = PhoneConnectionManager()
    
    private let session = WCSession.default
    
    var objectWillChange = ObservableObjectPublisher() // called when something with the connection changes
    
    func activateSession() {
        assert(WCSession.isSupported())
        session.delegate = self
        session.activate()
    }
    
    var isReachable: Bool {
        session.isReachable
    }
    
    var isActivated: Bool {
        session.activationState == .activated
    }
    
    private let scheduleDiscardUnstartedWorkoutSessionSubject = PassthroughSubject<Void, Never>()
    private var cancellable: AnyCancellable?

    override init() {
        cancellable = scheduleDiscardUnstartedWorkoutSessionSubject
            .debounce(for: .seconds(60), scheduler: RunLoop.main) // seems to be a bug in watchOS, when using the accessQueue, debounce fires immediately (watchOS 6.2)
            .receive(on: WorkoutSessionManager.accessQueue)
            .sink {
                os_log("Running scheduled check whether current workout session was never started")
                guard let state = WorkoutSessionManagerStore.shared.workoutSessionManager?.state, state == .prepared || state == .notStarted else { return } // not really necessary
                guard WorkoutSessionManagerStore.shared.workoutSessionManager?.uuid == nil else { return } // make sure the UUID is nil
                os_log("Discarding workout session that is still in the prepared state after 60 seconds have passed since last prepare message")
                WorkoutSessionManagerStore.shared.discardUnstartedWorkoutSession()
            }
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
        } else if let updateRestTimerMessage = message[PayloadKey.updateWorkoutSessionRestTimer] as? [String : Any] {
            handleUpdateRestTimerMessage(message: updateRestTimerMessage)
        } else if let updateSelectedSetMessage = message[PayloadKey.updateWorkoutSessionSelectedSet] as? [String : Any] {
            handleUpdateSelectedSetMessage(message: updateSelectedSetMessage)
        } else if let discardMessage = message[PayloadKey.discardWorkoutSession] as? [String : Any] {
            handleDiscardWorkoutSessionMessage(message: discardMessage)
        } else if let unprepare = message[PayloadKey.ignoredPreparedWorkoutSession] as? Bool, unprepare {
            handleIgnoredPreparedWorkoutSession()
        } else {
            assertionFailure("Unrecognized message: \(message)")
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
        
        WorkoutSessionManagerStore.shared.startWorkoutSession(start: start, uuid: uuid)
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
        let title = message[PayloadKey.Arg.title] as? String // nil is allowed
        guard let uuidString = message[PayloadKey.Arg.uuid] as? String, let uuid = UUID(uuidString: uuidString) else {
            assertionFailure("end workout with no uuid parameter")
            return
        }
        
        WorkoutSessionManagerStore.shared.endWorkoutSession(start: start, end: end, title: title, uuid: uuid)
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

        WorkoutSessionManagerStore.shared.updateWorkoutSessionStart(start: start, uuid: uuid)
    }
    
    private func handleUpdateWorkoutSessionEndMessage(message: [String : Any]) {
        // this message is only valid if the current workoutSession was started with the same UUID
        
        let end = message[PayloadKey.Arg.end] as? Date // nil is allowed
        guard let uuidString = message[PayloadKey.Arg.uuid] as? String, let uuid = UUID(uuidString: uuidString) else {
            assertionFailure("update workout end with no uuid parameter")
            return
        }
        
        WorkoutSessionManagerStore.shared.updateWorkoutSessionEnd(end: end, uuid: uuid)
    }
    
    private func handleUpdateRestTimerMessage(message: [String : Any]) {
        // this message is only valid if the current workoutSession was started with the same UUID
        
        let end = message[PayloadKey.Arg.end] as? Date // nil is allowed
        let keepRunning = message[PayloadKey.Arg.keepRestTimerRunning] as? Bool // nil is allowed
        guard let uuidString = message[PayloadKey.Arg.uuid] as? String, let uuid = UUID(uuidString: uuidString) else {
            assertionFailure("update rest timer with no uuid parameter")
            return
        }
        
        WorkoutSessionManagerStore.shared.updateWorkoutSessionRestTimer(end: end, keepRunning: keepRunning, uuid: uuid)
    }
    
    private func handleUpdateSelectedSetMessage(message: [String : Any]) {
        // this message is only valid if the current workoutSession was started with the same UUID
        
        let text = message[PayloadKey.Arg.text] as? String // nil is allowed
        guard let uuidString = message[PayloadKey.Arg.uuid] as? String, let uuid = UUID(uuidString: uuidString) else {
            assertionFailure("update selected set with no uuid parameter")
            return
        }
        
        WorkoutSessionManagerStore.shared.updateWorkoutSessionSelectedSetText(text: text, uuid: uuid)
    }
    
    private func handleDiscardWorkoutSessionMessage(message: [String : Any]) {
        // this message is only valid if the current workoutSession was started with the same UUID
        
        guard let uuidString = message[PayloadKey.Arg.uuid] as? String, let uuid = UUID(uuidString: uuidString) else {
            assertionFailure("discard workout with no uuid parameter")
            return
        }
        
        WorkoutSessionManagerStore.shared.discardWorkoutSession(uuid: uuid)
    }
    
    private func handleIgnoredPreparedWorkoutSession() {
        WorkoutSessionManagerStore.shared.discardUnstartedWorkoutSession()
    }
}

extension PhoneConnectionManager {
    func handlePrepareWorkoutSession(_ workoutConfiguration: HKWorkoutConfiguration) {
        os_log("Ensuring we have a workout session that keeps the app alive")
        WorkoutSessionManagerStore.shared.ensurePreparedWorkoutSession(configuration: workoutConfiguration) { [weak self] result in
            switch result {
            case .success:
                self?.sendPreparedWorkoutSession()
                self?.scheduleDiscardUnstartedWorkoutSessionSubject.send()
            case .failure(let error):
                os_log("Could not prepare workout session: %@", error.localizedDescription)
            }
        }
    }
}

// MARK: - Sending
extension PhoneConnectionManager {
    /// wrapper to send either via message or transfer, depending on what's available
    private func sendUserInfo(userInfo: [String : Any]) {
        guard isActivated else {
            /// when the watch app is cold started via the phone, the session might not be activated yet, so try again in 1 second.
            /// this is a kind of unclean workaround but it works very well
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.sendUserInfo(userInfo: userInfo)
            }
            return
        }
        if isReachable {
            os_log("Messaging userInfo=%@", type: .debug, userInfo)
            session.sendMessage(userInfo, replyHandler: nil) { error in
                os_log("Messaging not possible, falling back to transfering", type: .debug)
                self.session.transferUserInfo(userInfo)
            }
        } else {
            os_log("Transfering userInfo=%@", type: .debug, userInfo)
            session.transferUserInfo(userInfo)
        }
    }
    
    func sendPreparedWorkoutSession() {
        os_log("Sending prepared message")
        sendUserInfo(userInfo: [PayloadKey.preparedWorkoutSession : true])
    }
}
