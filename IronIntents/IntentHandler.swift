//
//  IntentHandler.swift
//  IronIntents
//
//  Created by Karim Abou Zeid on 07.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Intents
import os.log

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        os_log("Handling intent=%@", log: .intents, type: .info, intent)
        
        if intent is ViewPersonalRecordsIntent {
            return ViewPersonalRecordsIntentHandler()
        } else if intent is ViewOneRepMaxIntent {
            return ViewOneRepMaxIntentHandler()
        } else if intent is INStartWorkoutIntent {
            return StartWorkoutIntentHandler()
        } else if intent is INCancelWorkoutIntent {
            return CancelWorkoutIntentHandler()
        } else if intent is INEndWorkoutIntent {
            return EndWorkoutIntentHandler()
        }
        
        preconditionFailure("Unhandled intent type: \(intent)")
    }
    
}
