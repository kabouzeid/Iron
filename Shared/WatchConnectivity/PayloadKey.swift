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
    // Args: true
    static let preparedWorkoutSession = "preparedWorkoutSession" // sent to confirm that healthStore.startWatchApp() resulted in a prepare
    
    // phone --> watch
    // Args: true
    static let unprepareWorkoutSession = "unprepareWorkoutSession" // send if the prepare message came to late, i.e. after the workout was already canceled / finished
    
    // phone --> watch
    // Args: [start: Date, uuid: UUID]
    static let startWorkoutSession = "startWorkoutSession"
    
    // phone --> watch
    // Args: [start: Date, uuid: UUID]
    static let updateWorkoutSessionStart = "updateWorkoutSessionStart"
    
    // phone --> watch
    // Args: [(optional) end: Date, uuid: UUID]
    static let updateWorkoutSessionEnd = "updateWorkoutSessionEnd"
    
    // phone --> watch
    // Args: [end: Date, uuid: UUID]
    static let updateWorkoutSessionRestTimerEnd = "updateWorkoutSessionRestTimerEnd"
    
    // phone --> watch
    // Args: [text: String, uuid: UUID] // TODO: replace with [reps: Int, weight: Double, uuid: UUID]
    static let updateWorkoutSessionSelectedSet = "updateWorkoutSessionSelectedSet"
    
    // phone --> watch
    // Args: [start: Date, end: Date, uuid: UUID]
    static let endWorkoutSession = "endWorkoutSession"
    
    // phone --> watch
    // Args: [uuid: UUID]
    static let discardWorkoutSession = "discardWorkoutSession"
    
    enum Arg {
        static let start = "start"
        static let end = "end"
        static let text = "text"
        static let uuid = "uuid"
    }
}
