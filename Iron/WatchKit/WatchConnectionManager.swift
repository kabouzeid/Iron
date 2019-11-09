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
    // 1. we need to monitor when a workout is started / finished / discarded
    // 2. we need to monitor the start time
    
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
    
    func prepareWatchWorkout(preparedHandler: @escaping PerpareHandler) {
        print(#function)
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
        sendUserInfo(userInfo: [PayloadKey.unprepareWorkoutSession : true])
        currentWatchWorkoutUuid = nil
    }
    
    func startWatchWorkout(start: Date, uuid: UUID) {
        print(#function)
        if currentWatchWorkoutUuid != nil {
            print("warning: overwriting currentWatchWorkoutUuid")
        }
        sendUserInfo(userInfo: [PayloadKey.startWorkoutSession : [PayloadKey.Arg.start : start, PayloadKey.Arg.uuid : uuid.uuidString]])
        currentWatchWorkoutUuid = uuid
    }
    
    func updateWatchWorkoutStart(start: Date, uuid: UUID) {
        print(#function)
        if currentWatchWorkoutUuid != uuid {
            print("warning: sending update watch workout start for different uuid")
        }
        sendUserInfo(userInfo: [PayloadKey.updateWorkoutSessionStart : [PayloadKey.Arg.start : start, PayloadKey.Arg.uuid : uuid.uuidString]])
    }
    
    func finishWatchWorkout(end: Date, uuid: UUID) {
        print(#function)
        if currentWatchWorkoutUuid != uuid {
            print("warning: sending finish watch workout for different uuid")
        }
        sendUserInfo(userInfo: [PayloadKey.endWorkoutSession : [PayloadKey.Arg.end : end, PayloadKey.Arg.uuid : uuid.uuidString]])
        currentWatchWorkoutUuid = nil
    }
    
    func discardWatchWorkout(uuid: UUID) {
        print(#function)
        if currentWatchWorkoutUuid != uuid {
            print("warning: sending discard watch workout for different uuid")
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
