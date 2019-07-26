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
        let numberFormatter = unit.numberFormatter
        numberFormatter.minimumFractionDigits = unit.defaultFractionDigits
        let weightInUnit = WeightUnit.convert(weight: weight, from: .metric, to: unit)
        return "\(numberFormatter.string(from: weightInUnit as NSNumber) ?? String(format: "%\(unit.maximumFractionDigits).f")) \(unit.abbrev) × \(repetitions)"
    }
    
    static var MAX_REPETITIONS: Int16 = 9999
    static var MAX_WEIGHT: Double = 99999
}
