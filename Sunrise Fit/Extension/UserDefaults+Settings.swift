//
//  UserDefaults+Settings.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 11.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum SettingsKeys: String {
        case weightUnit
    }

    var weightUnit: SettingsStore.WeightUnit {
        set {
            self.set(newValue.rawValue, forKey: SettingsKeys.weightUnit.rawValue)
        }
        get {
            SettingsStore.WeightUnit(rawValue: self.string(forKey: SettingsKeys.weightUnit.rawValue) ?? "") ?? .metric
        }
    }
}
