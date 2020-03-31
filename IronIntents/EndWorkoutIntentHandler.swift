//
//  EndWorkoutIntentHandler.swift
//  IronIntents
//
//  Created by Karim Abou Zeid on 28.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Intents

class EndWorkoutIntentHandler: NSObject, INEndWorkoutIntentHandling {
    func handle(intent: INEndWorkoutIntent, completion: @escaping (INEndWorkoutIntentResponse) -> Void) {
        completion(.init(code: .handleInApp, userActivity: nil))
    }
}
