//
//  StartWorkoutIntentHandler.swift
//  IronIntents
//
//  Created by Karim Abou Zeid on 27.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Intents

class StartWorkoutIntentHandler: NSObject, INStartWorkoutIntentHandling {
    func handle(intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void) {
        completion(.init(code: .handleInApp, userActivity: nil))
    }
}
