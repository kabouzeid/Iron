//
//  Workout+Start.swift
//  Iron
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit

extension Workout {
    func start(alsoStartOnWatch: Bool) {
        prepareForStart()
        start = Date()
        managedObjectContext?.safeSave()
        
        if alsoStartOnWatch {
            WatchConnectionManager.shared.tryStartWatchWorkout(workout: self)
        }
        
        NotificationManager.shared.requestAuthorization()
    }
}
