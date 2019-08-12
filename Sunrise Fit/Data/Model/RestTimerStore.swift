//
//  RestTimerStore.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 12.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Combine

final class RestTimerStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    private var userDefaults: UserDefaults
    
    fileprivate init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    fileprivate convenience init() {
        self.init(userDefaults: UserDefaults.standard)
    }
    
    var restTimerEnd: Date? {
        get {
            userDefaults.restTimerEnd
        }
        set {
            self.objectWillChange.send()
            userDefaults.restTimerEnd = newValue
        }
    }
}

let restTimerStore = RestTimerStore() // singleton
