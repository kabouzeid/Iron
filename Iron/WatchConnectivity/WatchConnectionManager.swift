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

class WatchConnectionManager: NSObject {
    static let shared = WatchConnectionManager()
    
    private let session = WCSession.default
    
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
    
    typealias PerpareHandler = (() -> Void)
    private var preparedHandler: PerpareHandler?
    
    let selectedSetChangePublisher = PassthroughSubject<(WorkoutSet?, UUID), Never>()
    var selectedSetChangePublisherCancellable: Cancellable?
    var selectedSetCancellable: Cancellable?
}

extension WatchConnectionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print(#function + " \(activationState)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print(#function)
        // nothing todo
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print(#function)
        // connect to the new Apple Watch
        activateSession()
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print(#function + " \(applicationContext)")
        
        receive(message: applicationContext)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
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
    }
}

extension WatchConnectionManager {
    private func receive(message: [String : Any]) {
        if let prepared = message[PayloadKey.preparedWorkoutSession] as? Bool, prepared {
            handlePreparedMessage()
        }
    }
    
    private func handlePreparedMessage() {
        print(#function)
        
        self.preparedHandler?()
        self.preparedHandler = nil
    }
}

extension WatchConnectionManager {
    /// wrapper to send either via message or transfer, depending on what's available
    private func sendUserInfo(userInfo: [String : Any]) {
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
        print(#function)
        guard isActivated else { return } // makes no sense to prepare the workout when we can't send messages
        self.preparedHandler = preparedHandler // set here, because the prepare message is received even before startWatchApp() completion fires
        HealthManager.shared.healthStore.startWatchApp(with: HealthManager.shared.workoutConfiguration) { success, error in
            guard success else {
                print("could not start watch app: \(error?.localizedDescription ?? "nil")")
                return
            }
            print("startWatchApp successful")
        }
    }
    
    func unprepareWatchWorkout() {
        print(#function)
        guard isActivated else { return }
        sendUserInfo(userInfo: [PayloadKey.unprepareWorkoutSession : true])
        currentWatchWorkoutUuid = nil
    }
    
    func startWatchWorkout(start: Date, uuid: UUID) {
        print(#function)
        guard isActivated else { return }
        #if DEBUG
        if currentWatchWorkoutUuid != nil {
            print("warning: overwriting currentWatchWorkoutUuid")
        }
        #endif
        sendUserInfo(userInfo: [PayloadKey.startWorkoutSession : [PayloadKey.Arg.start : start, PayloadKey.Arg.uuid : uuid.uuidString]])
        currentWatchWorkoutUuid = uuid
    }
    
    func updateWatchWorkoutStart(start: Date, uuid: UUID) {
        print(#function)
        guard isActivated else { return }
        #if DEBUG
        if currentWatchWorkoutUuid != uuid {
            print("warning: sending update watch workout start for different uuid")
        }
        #endif
        sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionStart : [PayloadKey.Arg.start : start, PayloadKey.Arg.uuid : uuid.uuidString]])
    }
    
    func updateWatchWorkoutEnd(end: Date?, uuid: UUID) {
        print(#function)
        guard isActivated else { return }
        #if DEBUG
        if currentWatchWorkoutUuid != uuid {
            print("warning: sending update watch workout end for different uuid")
        }
        #endif
        if let end = end {
            sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionEnd : [PayloadKey.Arg.end : end, PayloadKey.Arg.uuid : uuid.uuidString]])
        } else {
            sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionEnd : [PayloadKey.Arg.uuid : uuid.uuidString]])
        }
    }
    
    func updateWatchWorkoutRestTimerEnd(end: Date?, uuid: UUID) {
        print(#function)
        guard isActivated else { return }
        #if DEBUG
        if currentWatchWorkoutUuid != uuid {
            print("warning: sending update rest timer end for different uuid")
        }
        #endif
        if let end = end {
            sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionRestTimerEnd : [PayloadKey.Arg.end : end, PayloadKey.Arg.uuid : uuid.uuidString]])
        } else {
            sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionRestTimerEnd : [PayloadKey.Arg.uuid : uuid.uuidString]])
        }
    }
    
    func updateWatchWorkoutSelectedSet(text: String?, uuid: UUID) {
        print(#function)
        guard isActivated else { return }
        #if DEBUG
        if currentWatchWorkoutUuid != uuid {
            print("warning: sending update selected set for different uuid")
        }
        #endif
        if let text = text {
            sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionSelectedSet : [PayloadKey.Arg.text : text, PayloadKey.Arg.uuid : uuid.uuidString]])
        } else {
            sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionSelectedSet : [PayloadKey.Arg.uuid : uuid.uuidString]])
        }
    }
    
    func finishWatchWorkout(start: Date, end: Date, uuid: UUID) {
        print(#function)
        guard isActivated else { return }
        #if DEBUG
        if currentWatchWorkoutUuid != uuid {
            print("warning: sending finish watch workout for different uuid")
        }
        #endif
        sendUserInfo(userInfo: [PayloadKey.endWorkoutSession : [PayloadKey.Arg.start : start, PayloadKey.Arg.end : end, PayloadKey.Arg.uuid : uuid.uuidString]])
        currentWatchWorkoutUuid = nil
    }
    
    func discardWatchWorkout(uuid: UUID) {
        print(#function)
        guard isActivated else { return }
        #if DEBUG
        if currentWatchWorkoutUuid != uuid {
            print("warning: sending discard watch workout for different uuid")
        }
        #endif
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
        prepareWatchWorkout {
            guard workout.isCurrentWorkout else {
                self.unprepareWatchWorkout()
                return
            }
            guard let start = workout.start else {
                self.unprepareWatchWorkout()
                assertionFailure("start should always be set at this point")
                return
            }
            guard let uuid = workout.uuid else {
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
