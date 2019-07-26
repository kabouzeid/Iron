//
//  WeightUnit.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 16.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

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
    
    var abbrev: String {
        switch self {
        case .metric:
            return "kg"
        case .imperial:
            return "lb"
        }
    }
    
    var ratioToKg: Double {
        switch self {
        case .metric:
            return 1
        case .imperial:
            return 0.45359237
        }
    }
    
    static func convert(weight: Double, from: WeightUnit, to: WeightUnit) -> Double {
        weight * (from.ratioToKg / to.ratioToKg)
    }
}

extension WeightUnit {
    var barbellIncrement: Double {
        switch self {
        case .metric:
            return 2.5 // 2x 1.25 kg
        case .imperial:
            return 5 // 2x 2.5 lb
        }
    }
    
    var barbellWeight: Double {
        switch self {
        case .metric:
            return 20
        case .imperial:
            return 45
        }
    }
    
    var defaultFractionDigits: Int {
        switch self {
        case .metric:
            return 1
        case .imperial:
            return 0
        }
    }
}
