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
    
    enum WeightUnit: String, CaseIterable, Hashable {
        case metric
        case imperial
        
        var title: String {
            switch self {
            case .metric:
                return "Metric (kg)"
            case .imperial:
                return "Imperial (lb)"
            }
        }
    }
    
    var weightUnit: WeightUnit {
        get {
            UserDefaults.standard.weightUnit
        }
        set {
            UserDefaults.standard.weightUnit = newValue
            didChange.send()
        }
    }
}

// TODO: put this in the SwiftUI view environment
var settingsStore = SettingsStore()
