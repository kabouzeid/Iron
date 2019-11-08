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
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print(#function + " \(userInfo)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print(#function + " \(message)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print(#function + " \(message)")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print(#function + " \(session.isReachable)")
    }
}
