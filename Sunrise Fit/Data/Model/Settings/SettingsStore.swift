//
//  SettingsStore.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 16.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class SettingsStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    private var userDefaults: UserDefaults
    
    fileprivate init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    fileprivate convenience init() {
        self.init(userDefaults: UserDefaults.standard)
    }

    var weightUnit: WeightUnit {
        get {
            userDefaults.weightUnit
        }
        set {
            self.objectWillChange.send()
            userDefaults.weightUnit = newValue
        }
    }
    
    var defaultRestTime: TimeInterval {
        get {
            userDefaults.defaultRestTime
        }
        set {
            self.objectWillChange.send()
            userDefaults.defaultRestTime = newValue
        }
    }
    
    var defaultRestTimeBarbellBased: TimeInterval {
        get {
            userDefaults.defaultRestTimeBarbellBased
        }
        set {
            self.objectWillChange.send()
            userDefaults.defaultRestTimeBarbellBased = newValue
        }
    }
    
    var maxRepetitionsOneRepMax: Int {
        get {
            userDefaults.maxRepetitionsOneRepMax
        }
        set {
            self.objectWillChange.send()
            userDefaults.maxRepetitionsOneRepMax = newValue
        }
    }
}

let settingsStore = SettingsStore() // singleton

#if DEBUG
let mockSettingsStoreMetric: SettingsStore = {
    let store = SettingsStore(userDefaults: UserDefaults(suiteName: "mock_metric")!)
    store.weightUnit = .metric
    return store
}()

let mockSettingsStoreImperial: SettingsStore = {
    let store = SettingsStore(userDefaults: UserDefaults(suiteName: "mock_imperial")!)
    store.weightUnit = .imperial
    return store
}()
#endif
