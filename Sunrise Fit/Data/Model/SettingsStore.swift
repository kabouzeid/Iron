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

class SettingsStore: BindableObject {
    var didChange = PassthroughSubject<Void, Never>()
    
    private var userDefaults: UserDefaults
    
    fileprivate init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    convenience init() {
        self.init(userDefaults: UserDefaults.standard)
    }

    var weightUnit: WeightUnit {
        get {
            userDefaults.weightUnit
        }
        set {
            userDefaults.weightUnit = newValue
            didChange.send()
        }
    }
}

let settingsStore = SettingsStore()

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
