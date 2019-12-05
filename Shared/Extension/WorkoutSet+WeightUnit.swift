//
//  WorkoutSet+WeightUnit.swift
//  Iron
//
//  Created by Karim Abou Zeid on 05.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit

extension WorkoutSet {
    func displayTitle(weightUnit: WeightUnit) -> String {
        displayTitle(unit: weightUnit.unit, formatter: weightUnit.formatter)
    }
    
    func logTitle(weightUnit: WeightUnit) -> String {
        logTitle(unit: weightUnit.unit, formatter: weightUnit.formatter)
    }
}
