//
//  TrainingSet.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
import Combine

class TrainingSet: NSManagedObject {
    func displayTitle(unit: WeightUnit) -> String {
        let numberFormatter = unit.numberFormatter
        numberFormatter.minimumFractionDigits = unit.defaultFractionDigits
        let weightInUnit = WeightUnit.convert(weight: weight, from: .metric, to: unit)
        return "\(numberFormatter.string(from: weightInUnit as NSNumber) ?? String(format: "%\(unit.maximumFractionDigits).f")) \(unit.abbrev) × \(repetitions)"
    }
    
    private var cancellable: AnyCancellable?

    static var MAX_REPETITIONS: Int16 = 9999
    static var MAX_WEIGHT: Double = 99999
}

extension TrainingSet {
    override func awakeFromFetch() {
        super.awakeFromFetch() // important
        initChangeObserver()
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert() // important
        initChangeObserver()
    }
    
    private func initChangeObserver() {
        cancellable = managedObjectContext?.publisher
            .filter { changed in
                changed.contains { managedObject in
                    if let training = managedObject as? Training {
                        return training.objectID == self.trainingExercise?.training?.objectID
                    }
                    if let trainingExercise = managedObject as? TrainingExercise {
                        return trainingExercise.objectID == self.trainingExercise?.objectID
                    }
                    return managedObject.objectID == self.objectID
                }
        }
        .sink { _ in self.objectWillChange.send() }
    }
}
