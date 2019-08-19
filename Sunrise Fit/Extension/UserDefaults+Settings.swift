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

    var weightUnit: WeightUnit {
        set {
            self.set(newValue.rawValue, forKey: SettingsKeys.weightUnit.rawValue)
        }
        get {
            let weightUnit = WeightUnit(rawValue: self.string(forKey: SettingsKeys.weightUnit.rawValue) ?? "")
            if let weightUnit = weightUnit {
                return weightUnit
            } else {
                let fallback = Locale.current.usesMetricSystem ? WeightUnit.metric : WeightUnit.imperial
                self.weightUnit = fallback // safe the new weight unit
                return fallback
            }
        }
    }
}
