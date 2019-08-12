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
        case restTimerEnd
    }
    
    var restTimerEnd: Date? {
        set {
            self.set(newValue, forKey: RestTimerKeys.restTimerEnd.rawValue)
        }
        get {
            guard let date = self.object(forKey: RestTimerKeys.restTimerEnd.rawValue) as? Date else { return nil }
            return date > Date() ? date : nil // do not return an expired value
        }
    }
}
