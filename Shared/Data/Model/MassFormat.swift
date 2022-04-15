//
//  MassFormat.swift
//  Iron
//
//  Created by Karim Abou Zeid on 11.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

enum MassFormat: String, CaseIterable, Hashable {
    case metric, imperial
    
    var title: String {
        switch self {
        case .metric:
            return "Metric (kg)"
        case .imperial:
            return "Imperial (lb)"
        }
    }
    
    var unit: UnitMass {
        switch self {
        case .metric:
            return .kilograms
        case .imperial:
            return .pounds
        }
    }
}

extension MassFormat {
    func format(kg: Double) -> String {
        Measurement(value: kg, unit: UnitMass.kilograms)
            .converted(to: self.unit)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0...2))))
    }
}

extension MassFormat {
    var barbellIncrement: Measurement<UnitMass> {
        switch self {
        case .metric:
            return Measurement(value: 2.5, unit: UnitMass.kilograms)
        case .imperial:
            return Measurement(value: 5, unit: UnitMass.pounds)
        }
    }
    
    var barbellWeight: Measurement<UnitMass> {
        switch self {
        case .metric:
            return Measurement(value: 20, unit: UnitMass.kilograms)
        case .imperial:
            return Measurement(value: 45, unit: UnitMass.pounds)
        }
    }
}
