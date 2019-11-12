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
    static let shared = SettingsStore()
    
    let objectWillChange = ObservableObjectPublisher()
    
    private var userDefaults: UserDefaults
    
    private init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    private convenience init() {
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
    
    var defaultRestTimeDumbbellBased: TimeInterval {
        get {
            userDefaults.defaultRestTimeDumbbellBased
        }
        set {
            self.objectWillChange.send()
            userDefaults.defaultRestTimeDumbbellBased = newValue
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
    
    var autoBackup: Bool {
        get {
            userDefaults.autoBackup
        }
        set {
            self.objectWillChange.send()
            userDefaults.autoBackup = newValue
        }
    }
    
    var watchCompanion: Bool {
        get {
            userDefaults.watchCompanion
        }
        set {
            self.objectWillChange.send()
            userDefaults.watchCompanion = newValue
        }
    }
}

#if DEBUG
extension SettingsStore {
    static let mockMetric: SettingsStore = {
        let store = SettingsStore(userDefaults: UserDefaults(suiteName: "mock_metric")!)
        store.weightUnit = .metric
        return store
    }()

    static let mockImperial: SettingsStore = {
        let store = SettingsStore(userDefaults: UserDefaults(suiteName: "mock_imperial")!)
        store.weightUnit = .imperial
        return store
    }()
}
#endif
