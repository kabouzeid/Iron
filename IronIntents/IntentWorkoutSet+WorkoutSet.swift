//
//  IntentWorkoutSet+WorkoutSet.swift
//  IronIntents
//
//  Created by Karim Abou Zeid on 12.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit

extension IntentWorkoutSet {
    convenience init(workoutSet: WorkoutSet, weightUnit: WeightUnit) {
        let weight = IntentWeight(measurement: Measurement(value: Double(workoutSet.weightValue), unit: UnitMass.kilograms), weightUnit: weightUnit)
        self.init(identifier: workoutSet.objectID.uriRepresentation().absoluteString, display: workoutSet.displayTitle(weightUnit: weightUnit), pronunciationHint: "\(weight.value!) times \(workoutSet.repetitionsValue)")
        self.weight = weight
        self.repetitions = workoutSet.repetitionsValue as NSNumber
    }
}
