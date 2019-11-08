//
//  PayloadKey.swift
//  Iron
//
//  Created by Karim Abou Zeid on 04.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

enum PayloadKey {
    // phone --> watch
    // calls healthStore.startWatchApp()
    
    // phone <-- watch
    // Args: []
    static let preparedWorkoutSession = "preparedWorkoutSession" // sent to confirm that healthStore.startWatchApp() resulted in a prepare
    
    // phone --> watch
    // Args: [start: Date, uuid: UUID]
    static let startWorkoutSession = "startWorkoutSession"
    
    // phone --> watch
    // Args: [start: Date, uuid: UUID]
    static let updateWorkoutSessionStart = "updateWorkoutSessionStart"
    
    // phone --> watch
    // Args: [end: Date, uuid: UUID]
    static let endWorkoutSession = "endWorkoutSession"
    
    // phone --> watch
    // Args: [uuid: UUID]
    static let discardWorkoutSession = "discardWorkoutSession"
    
    enum Arg {
        static let start = "start"
        static let end = "end"
        static let uuid = "uuid"
    }
}
