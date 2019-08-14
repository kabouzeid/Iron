//
//  UserDefaults+RestTimer.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 12.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum RestTimerKeys: String {
        case restTimerStart
        case restTimerDuration
    }
    
    var restTimerStart: Date? {
        set {
            self.set(newValue, forKey: RestTimerKeys.restTimerStart.rawValue)
        }
        get {
            guard let date = self.object(forKey: RestTimerKeys.restTimerStart.rawValue) as? Date else { return nil }
            guard date <= Date() else { return nil } // sanity check
            return date
        }
    }
    
    var restTimerDuration: TimeInterval? {
        set {
            self.set(newValue, forKey: RestTimerKeys.restTimerDuration.rawValue)
        }
        get {
            guard let duration = self.object(forKey: RestTimerKeys.restTimerDuration.rawValue) as? TimeInterval else { return nil }
            guard duration > 0 else { return nil } // sanity check
            return duration
        }
    }
}
