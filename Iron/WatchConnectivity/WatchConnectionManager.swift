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

/// The following behaviour was tested on watchOS 6.2 and iOS 13.4:
/// When the watch app is not reachable, data often won't arrive until the app is opened. Sometimes the data arrives, but then the watch only answers when the watch app is opened.

/// - BUG:
///     When using the intents extension, and the app is completely closed and then launched by Siri in the background, the app restarts *every* time before receiving a message from the watch. Because of that, when the prepared message arrives, the app is restarted and the preparedHandler is nil.
///     I think this is a bug, because when the app was already in background before that, this doesn't happen.
///     Tested on iOS 13.4, watchOS 6.2, Xcode 11.

class WatchConnectionManager: NSObject {
    static let shared = WatchConnectionManager()
    
    private let session = WCSession.default
    
    func activateSession() {
        guard WCSession.isSupported() else {
            os_log("WatchConnectivity is not supported on this device", log: .watch, type: .error)
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
    
    typealias PrepareHandler = (() -> Void)
    private var preparedHandler: PrepareHandler?
    
    typealias StartWatchCompanionErrorHandler = ((Error) -> Void)
    
    let selectedSetChangePublisher = PassthroughSubject<(WorkoutSet?, UUID), Never>()
    var selectedSetChangePublisherCancellable: Cancellable?
    var selectedSetCancellable: Cancellable?
}

extension WatchConnectionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        os_log("Session activation completed isActivated=%@ error=%@", log: .watch, type: .info, String(describing: activationState == .activated), error?.localizedDescription ?? "nil") // printing activationState directly doesn't work
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        os_log("Session did become inactive", log: .watch, type: .debug)
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        os_log("Session was deactivated", log: .watch, type: .debug)
        // connect to the new Apple Watch
        os_log("Reactivating session", log: .watch, type: .debug)
        activateSession()
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        os_log("Received applicationContext=%@", log: .watch, type: .debug, applicationContext)
        
        receive(message: applicationContext)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        os_log("Received userInfo=%@", log: .watch, type: .debug, userInfo)
        
        receive(message: userInfo)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        os_log("Received message=%@", log: .watch, type: .debug, message)
        
        receive(message: message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        os_log("Received message=%@", log: .watch, type: .debug, message)
        
        receive(message: message)
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        os_log("Session reachability did change isReachable=%@", log: .watch, type: .debug, String(describing: session.isReachable))
    }
}

extension WatchConnectionManager {
    private func receive(message: [String : Any]) {
        if let prepared = message[PayloadKey.preparedWorkoutSession] as? Bool, prepared {
            handlePreparedWorkoutSessionMessage()
        }
    }
    
    private func handlePreparedWorkoutSessionMessage() {
        os_log("Handling prepared workout session message", log: .watch)
        
        guard let preparedHandler = self.preparedHandler else {
            // if we receive this message and no one is listening for this, tell the watch to unprepare
            os_log("No prepare handler is set", log: .watch, type: .error)
            ignorePreparedWatchWorkout()
            return
        }
        
        preparedHandler()
        self.preparedHandler = nil
    }
}

extension WatchConnectionManager {
    /// wrapper to send either via message or transfer, depending on what's available
    private func sendUserInfo(userInfo: [String : Any]) {
        assert(isActivated)
        if isReachable {
            os_log("Messaging userInfo=%@", log: .watch, type: .debug, userInfo)
            session.sendMessage(userInfo, replyHandler: nil) { error in
                os_log("Messaging not possible, falling back to transfering", log: .watch, type: .fault)
                self.session.transferUserInfo(userInfo)
            }
        } else {
            os_log("Transfering userInfo=%@", log: .watch, type: .debug, userInfo)
            session.transferUserInfo(userInfo)
        }
    }
    
    
    /// - NOTE: If in the prepare handler a workout session isn't started, a ignorePreparedWorkoutSession should be send
    func prepareWatchWorkout(startWatchCompanionErrorHandler: StartWatchCompanionErrorHandler? = nil, preparedHandler: @escaping PrepareHandler) {
        os_log("Preparing watch app", log: .watch, type: .default)
        guard isActivated else {
            // makes no sense to prepare the workout if we can't send messages
            os_log("Session is not activated, skip preparing watch app", log: .watch, type: .info)
            return
        }
        self.preparedHandler = preparedHandler // set here, because the prepare message can be received even before startWatchApp() completion fires
        os_log("Using HKHealthStore to open watch app", log: .watch, type: .default)
        HealthManager.shared.healthStore.startWatchApp(with: HealthManager.shared.workoutConfiguration) { success, error in
            guard success else {
                // This happens when app is in background (e.g. when started from an intent)
                os_log("HKHealthStore could not open watch app: %@", log: .watch, type: .fault, error?.localizedDescription ?? "nil")
                startWatchCompanionErrorHandler?(error ?? GenericError(description: "Opening the watch app was unsuccessful"))
                return
            }
            os_log("Successfully opened watch app", log: .watch, type: .info)
        }
    }
    
    /// Tells the watch that it should not expect an answer to its prepared message
    func ignorePreparedWatchWorkout() {
        os_log("Notifying watch app that prepared message was ignored", log: .watch, type: .default)
        
        guard isActivated else {
            os_log("Session is not activated, skip notifying watch app", log: .watch, type: .info)
            return
        }
        sendUserInfo(userInfo: [PayloadKey.ignoredPreparedWorkoutSession : true])
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
    
    func updateWatchWorkoutRestTimer(end: Date?, keepRunning: Bool?, uuid: UUID) {
        os_log("Updating watch workout rest timer end", log: .watch, type: .default)
        
        guard isActivated else {
            os_log("Session is not activated, skip updating watch workout rest timer end", log: .watch, type: .info)
            return
        }
        if currentWatchWorkoutUuid != uuid {
            os_log("Sending update watch workout rest timer end for different uuid", log: .watch, type: .error)
        }
        
        var args: [String : Any] = [PayloadKey.Arg.uuid : uuid.uuidString]
        if let end = end {
            args[PayloadKey.Arg.end] = end
        }
        if let keepRunning = keepRunning {
            args[PayloadKey.Arg.keepRestTimerRunning] = keepRunning
        }
        
        sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionRestTimer : args])
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
    func prepareAndStartWatchWorkout(workout: Workout, startWatchCompanionErrorHandler: StartWatchCompanionErrorHandler? = nil) {
        prepareWatchWorkout(startWatchCompanionErrorHandler: startWatchCompanionErrorHandler) {
            self.startWatchWorkout(workout: workout)
        }
    }
    
    private func startWatchWorkout(workout: Workout) {
        guard let context = workout.managedObjectContext else {
            os_log("Workout context is nil", log: .watch, type: .error)
            self.ignorePreparedWatchWorkout()
            return
        }
        
        context.perform {
            guard workout.isCurrentWorkout else {
                os_log("Workout is no longer current workout", log: .watch, type: .error)
                self.ignorePreparedWatchWorkout()
                return
            }
            guard let start = workout.start else {
                os_log("Start not set on workout", log: .watch, type: .error)
                self.ignorePreparedWatchWorkout()
                assertionFailure("start should always be set at this point")
                return
            }
            guard let uuid = workout.uuid else {
                os_log("UUID not set on workout", log: .watch, type: .error)
                self.ignorePreparedWatchWorkout()
                assertionFailure("uuid is a required property")
                return
            }
            self.startWatchWorkout(start: start, uuid: uuid)
        }
    }
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
