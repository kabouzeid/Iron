//
//  CancelWorkoutIntentHandler.swift
//  IronIntents
//
//  Created by Karim Abou Zeid on 28.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Intents

class CancelWorkoutIntentHandler: NSObject, INCancelWorkoutIntentHandling {
    func handle(intent: INCancelWorkoutIntent, completion: @escaping (INCancelWorkoutIntentResponse) -> Void) {
        completion(.init(code: .handleInApp, userActivity: nil))
    }
}
