//
//  TrainingSet.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

class TrainingSet: NSManagedObject {
    func displayTitle(unit: WeightUnit) -> String {
        "\(TrainingSet.weightStringFor(weightInKg: weight, unit: unit)) × \(repetitions)"
    }
    
    static func weightStringFor(weightInKg: Double, unit: WeightUnit) -> String {
        let weightInUnit = WeightUnit.convert(weight: weightInKg, from: .metric, to: unit)
        return "\(weightNumberFormatter.string(from: weightInUnit as NSNumber) ?? String(weightInUnit)) \(unit.abbrev)"
    }
    
    static var weightNumberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 1
        return formatter
    }
    
    static var MAX_REPETITIONS: Int16 = 9999
    static var MAX_WEIGHT: Double = 99999
}
