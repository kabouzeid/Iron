//
//  WatchConnectionManager.swift
//  Iron
//
//  Created by Karim Abou Zeid on 02.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WatchConnectivity
import CoreData
import Combine
import HealthKit
import WorkoutDataKit
import os.log

class WatchConnectionManager: NSObject {
    static let shared = WatchConnectionManager()
    
    private let session = WCSession.default
    
    func activateSession() {
        guard WCSession.isSupported() else {
            os_log("WatchConnectivity is not supported on this device", log: .watch, type: .info)
            return
        }
        session.delegate = self
        session.activate()
    }
    
    var isReachable: Bool {
        session.isReachable
    }
    
    var isActivated: Bool {
        session.activationState == .activated
    }
    
    typealias PerpareHandler = (() -> Void)
    private var preparedHandler: PerpareHandler?
    
    let selectedSetChangePublisher = PassthroughSubject<(WorkoutSet?, UUID), Never>()
    var selectedSetChangePublisherCancellable: Cancellable?
    var selectedSetCancellable: Cancellable?
}

extension WatchConnectionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        OSLog.watch.trace()
        os_log("isActivated=%@", log: .watch, type: .debug, String(describing: activationState == .activated)) // printing activationState directly doesn't work
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        OSLog.watch.trace()
        // nothing todo
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        OSLog.watch.trace()
        // connect to the new Apple Watch
        activateSession()
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        OSLog.watch.trace()
        os_log("Received applicationContext=%@", log: .watch, type: .debug, applicationContext)
        
        receive(message: applicationContext)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        OSLog.watch.trace()
        os_log("Received userInfo=%@", log: .watch, type: .debug, userInfo)
        
        receive(message: userInfo)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        OSLog.watch.trace()
        os_log("Received message=%@", log: .watch, type: .debug, message)
        
        receive(message: message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        OSLog.watch.trace()
        os_log("Received message=%@", log: .watch, type: .debug, message)
        
        receive(message: message)
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        OSLog.watch.trace()
        os_log("session.isReachable=%@", log: .watch, type: .debug, String(describing: session.isReachable))
    }
}

extension WatchConnectionManager {
    private func receive(message: [String : Any]) {
        if let prepared = message[PayloadKey.preparedWorkoutSession] as? Bool, prepared {
            handlePreparedMessage()
        }
    }
    
    private func handlePreparedMessage() {
        OSLog.watch.trace()
        
        self.preparedHandler?()
        self.preparedHandler = nil
    }
}

extension WatchConnectionManager {
    /// wrapper to send either via message or transfer, depending on what's available
    private func sendUserInfo(userInfo: [String : Any]) {
        os_log("Sending userInfo=%@", log: .watch, type: .debug, userInfo)
        
        assert(isActivated)
        if isReachable {
            session.sendMessage(userInfo, replyHandler: nil) { error in
                self.session.transferUserInfo(userInfo)
            }
        } else {
            session.transferUserInfo(userInfo)
        }
    }
    
    func prepareWatchWorkout(preparedHandler: @escaping PerpareHandler) {
        os_log("Preparing watch app", log: .watch, type: .default)
        
        guard isActivated else {
            // makes no sense to prepare the workout if we can't send messages
            os_log("Session is not activated, skip preparing watch app", log: .watch, type: .info)
            return
        }
        self.preparedHandler = preparedHandler // set here, because the prepare message is received even before startWatchApp() completion fires
        HealthManager.shared.healthStore.startWatchApp(with: HealthManager.shared.workoutConfiguration) { success, error in
            guard success else {
                os_log("Could not start watch app: %@", log: .watch, type: .fault, error?.localizedDescription ?? "nil")
                return
            }
            os_log("Successfully started watch app", log: .watch, type: .info)
        }
    }
    
    func unprepareWatchWorkout() {
        os_log("Unpreparing watch app", log: .watch, type: .default)
        
        guard isActivated else {
            os_log("Session is not activated, skip unpreparing watch app", log: .watch, type: .info)
            return
        }
        sendUserInfo(userInfo: [PayloadKey.unprepareWorkoutSession : true])
        currentWatchWorkoutUuid = nil
    }
    
    func startWatchWorkout(start: Date, uuid: UUID) {
        os_log("Starting watch workout", log: .watch, type: .default)
        
        guard isActivated else {
            os_log("Session is not activated, skip starting watch workout", log: .watch, type: .info)
            return
        }
        if currentWatchWorkoutUuid != nil {
            os_log("Overwriting currentWatchWorkoutUuid", log: .watch, type: .error)
        }
        sendUserInfo(userInfo: [PayloadKey.startWorkoutSession : [PayloadKey.Arg.start : start, PayloadKey.Arg.uuid : uuid.uuidString]])
        currentWatchWorkoutUuid = uuid
    }
    
    func updateWatchWorkoutStart(start: Date, uuid: UUID) {
        os_log("Updating watch workout start date", log: .watch, type: .default)
        
        guard isActivated else {
            os_log("Session is not activated, skip updating watch workout start date", log: .watch, type: .info)
            return
        }
        if currentWatchWorkoutUuid != uuid {
            os_log("Sending update watch workout start date for different uuid", log: .watch, type: .error)
        }
        sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionStart : [PayloadKey.Arg.start : start, PayloadKey.Arg.uuid : uuid.uuidString]])
    }
    
    func updateWatchWorkoutEnd(end: Date?, uuid: UUID) {
        os_log("Updating watch workout end date", log: .watch, type: .default)
        
        guard isActivated else {
            os_log("Session is not activated, skip updating watch workout end date", log: .watch, type: .info)
            return
        }
        if currentWatchWorkoutUuid != uuid {
            os_log("Sending update watch workout end date for different uuid", log: .watch, type: .error)
        }
        if let end = end {
            sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionEnd : [PayloadKey.Arg.end : end, PayloadKey.Arg.uuid : uuid.uuidString]])
        } else {
            sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionEnd : [PayloadKey.Arg.uuid : uuid.uuidString]])
        }
    }
    
    func updateWatchWorkoutRestTimerEnd(end: Date?, uuid: UUID) {
        os_log("Updating watch workout rest timer end", log: .watch, type: .default)
        
        guard isActivated else {
            os_log("Session is not activated, skip updating watch workout rest timer end", log: .watch, type: .info)
            return
        }
        if currentWatchWorkoutUuid != uuid {
            os_log("Sending update watch workout rest timer end for different uuid", log: .watch, type: .error)
        }
        if let end = end {
            sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionRestTimerEnd : [PayloadKey.Arg.end : end, PayloadKey.Arg.uuid : uuid.uuidString]])
        } else {
            sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionRestTimerEnd : [PayloadKey.Arg.uuid : uuid.uuidString]])
        }
    }
    
    func updateWatchWorkoutSelectedSet(text: String?, uuid: UUID) {
        os_log("Updating watch workout selected set", log: .watch, type: .default)
        
        guard isActivated else {
            os_log("Session is not activated, skip updating watch workout selected set", log: .watch, type: .info)
            return
        }
        if currentWatchWorkoutUuid != uuid {
            os_log("Sending update watch workout selected set for different uuid", log: .watch, type: .error)
        }
        if let text = text {
            sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionSelectedSet : [PayloadKey.Arg.text : text, PayloadKey.Arg.uuid : uuid.uuidString]])
        } else {
            sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionSelectedSet : [PayloadKey.Arg.uuid : uuid.uuidString]])
        }
    }
    
    func finishWatchWorkout(start: Date, end: Date, title: String?, uuid: UUID) {
        os_log("Finishing watch workout", log: .watch, type: .default)
        
        guard isActivated else {
            os_log("Session is not activated, skip finishing watch workout", log: .watch, type: .info)
            return
        }
        if currentWatchWorkoutUuid != uuid {
             os_log("Sending finish watch workout for different uuid", log: .watch, type: .error)
        }
        if let title = title {
            sendUserInfo(userInfo: [PayloadKey.endWorkoutSession : [PayloadKey.Arg.start : start, PayloadKey.Arg.end : end, PayloadKey.Arg.title: title, PayloadKey.Arg.uuid : uuid.uuidString]])
        } else {
            sendUserInfo(userInfo: [PayloadKey.endWorkoutSession : [PayloadKey.Arg.start : start, PayloadKey.Arg.end : end, PayloadKey.Arg.uuid : uuid.uuidString]])
        }
        currentWatchWorkoutUuid = nil
    }
    
    func discardWatchWorkout(uuid: UUID) {
        os_log("Discarding watch workout", log: .watch, type: .default)
        
        guard isActivated else {
            os_log("Session is not activated, skip discarding watch workout", log: .watch, type: .info)
            return
        }
        if currentWatchWorkoutUuid != uuid {
            os_log("Sending discard watch workout for different uuid", log: .watch, type: .error)
        }
        sendUserInfo(userInfo: [PayloadKey.discardWorkoutSession : [PayloadKey.Arg.uuid : uuid.uuidString]])
        currentWatchWorkoutUuid = nil
    }
    
    var currentWatchWorkoutUuid: UUID? {
        get {
            UserDefaults.standard.watchWorkoutUuid
        }
        set {
            UserDefaults.standard.watchWorkoutUuid = newValue
        }
    }
}

extension WatchConnectionManager {
    func tryStartWatchWorkout(workout: Workout) {
        os_log("Trying to start watch workout", log: .watch, type: .default)
        
        prepareWatchWorkout {
            os_log("Prepared watch workout", log: .watch, type: .info)
            
            guard workout.isCurrentWorkout else {
                self.unprepareWatchWorkout()
                return
            }
            guard let start = workout.start else {
                os_log("Start not set on workout", log: .watch, type: .error)
                self.unprepareWatchWorkout()
                assertionFailure("start should always be set at this point")
                return
            }
            guard let uuid = workout.uuid else {
                os_log("UUID not set on workout", log: .watch, type: .error)
                self.unprepareWatchWorkout()
                assertionFailure("uuid is a required property")
                return
            }
            self.startWatchWorkout(start: start, uuid: uuid)
        }
    }
    
    // TODO: add convenience functions for the other watch workout related actions
}

extension WatchConnectionManager {
    func updateAndObserveWatchWorkoutSelectedSet(workoutSet: WorkoutSet?, uuid: UUID) {
        if selectedSetChangePublisherCancellable == nil {
            selectedSetChangePublisherCancellable = selectedSetChangePublisher
                .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .drop { self.currentWatchWorkoutUuid != $0.1 }
                .map { ($0.0?.displayTitle(weightUnit: SettingsStore.shared.weightUnit), $0.1) }
                .removeDuplicates { $0.0 == $1.0 }
                .sink { self.updateWatchWorkoutSelectedSet(text: $0.0, uuid: $0.1) }
        }
        
        selectedSetChangePublisher.send((workoutSet, uuid))
        selectedSetCancellable = workoutSet?.objectWillChange
            .map { _ in (workoutSet, uuid) }
            .subscribe(selectedSetChangePublisher)
    }
}
