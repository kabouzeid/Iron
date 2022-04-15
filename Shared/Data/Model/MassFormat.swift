//
//  MassFormat.swift
//  Iron
//
//  Created by Karim Abou Zeid on 11.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

enum MassFormat: String, CaseIterable, Hashable {
    case auto, metric, imperial
    
    var title: String {
        switch self {
        case .auto:
            return "Automatic"
        case .metric:
            return "Metric (kg)"
        case .imperial:
            return "Imperial (lb)"
        }
    }
    
    var unit: UnitMass {
        switch self {
        case .auto:
            return Locale.current.usesMetricSystem ? .kilograms : .pounds
        case .metric:
            return .kilograms
        case .imperial:
            return .pounds
        }
    }
}

extension MassFormat {
    var minimumFractionDigits: Int { 0 }
    var maximumFractionDigits: Int { 3 }
    var defaultFractionDigits: Int {
        if self.unit == .kilograms {
            return 1
        }
        else {
            return 0
        }
    }
}

extension MassFormat {
    func format(kg: Double) -> String {
        Measurement(value: kg, unit: UnitMass.kilograms)
            .converted(to: self.unit)
            .formatted()
    }
}

extension MassFormat {
    var barbellIncrement: Measurement<UnitMass> {
        if self.unit == .kilograms {
            return Measurement(value: 2.5, unit: UnitMass.kilograms)
        } else {
            return Measurement(value: 5, unit: UnitMass.pounds)
        }
    }
    
    var barbellWeight: Measurement<UnitMass> {
        if self.unit == .kilograms {
            return Measurement(value: 20, unit: UnitMass.kilograms)
        } else {
            return Measurement(value: 45, unit: UnitMass.pounds)
        }
    }
}
