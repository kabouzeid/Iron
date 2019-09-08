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
    
    // use this instead of tag
    var displayTag: TrainingSetTag? {
        get {
            TrainingSetTag(rawValue: tag ?? "")
        }
        set {
            tag = newValue?.rawValue
        }
    }
    
    // use this instead of rpe
    var displayRpe: Double? {
        get {
            RPE.allowedValues.contains(rpe) ? rpe : nil
        }
        set {
            let newValue = newValue ?? 0
            rpe = RPE.allowedValues.contains(newValue) ? newValue : 0
        }
    }
    
    var isPersonalRecord: Bool? {
        guard let start = trainingExercise?.training?.start else { return nil }
        guard let exerciseId = trainingExercise?.exerciseId else { return nil }

        let previousSetsRequest: NSFetchRequest<TrainingSet> = TrainingSet.fetchRequest()
        let previousSetsPredicate = NSPredicate(format:
            "\(#keyPath(TrainingSet.trainingExercise.exerciseId)) == %@ AND \(#keyPath(TrainingSet.isCompleted)) == %@ AND \(#keyPath(TrainingSet.trainingExercise.training.start)) < %@",
            exerciseId as NSNumber, true as NSNumber, start as NSDate
        )
        previousSetsRequest.predicate = previousSetsPredicate
        guard let numberOfPreviousSets = try? managedObjectContext?.count(for: previousSetsRequest) else { return nil }
        if numberOfPreviousSets == 0 { return false } // if there was no set for this exercise in a prior training, we consider no set as a PR

        let betterOrEqualPreviousSetsRequest: NSFetchRequest<TrainingSet> = TrainingSet.fetchRequest()
        betterOrEqualPreviousSetsRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:
            [
                previousSetsPredicate,
                NSPredicate(format:
                    "\(#keyPath(TrainingSet.weight)) >= %@ AND \(#keyPath(TrainingSet.repetitions)) >= %@",
                    weight as NSNumber, repetitions as NSNumber
                )
            ]
        )
        guard let numberOfBetterOrEqualPreviousSets = try? managedObjectContext?.count(for: betterOrEqualPreviousSetsRequest) else { return nil }
        if numberOfBetterOrEqualPreviousSets > 0 { return false } // there are better sets
        
        guard let index = trainingExercise?.trainingSets?.index(of: self), index != NSNotFound else { return nil }
        guard let numberOfBetterOrEqualPreviousSetsInCurrentTraining = (trainingExercise?.trainingSets?.array[0..<index]
            .compactMap { $0 as? TrainingSet }
            .filter { $0.isCompleted && $0.weight >= weight && $0.repetitions >= repetitions } // check isCompleted only to be sure, but it should never be false here
            .count)
            else { return nil }
        return numberOfBetterOrEqualPreviousSetsInCurrentTraining == 0
    }
    
    private var cancellable: AnyCancellable?

    static var MAX_REPETITIONS: Int16 = 9999
    static var MAX_WEIGHT: Double = 99999
}

extension TrainingSet {
    override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateConsistency()
    }
    
    override func validateForInsert() throws {
        try super.validateForInsert()
        try validateConsistency()
    }
    
    func validateConsistency() throws {
        if !isCompleted, let training = trainingExercise?.training, !training.isCurrentTraining {
            throw error(code: 1, message: "uncompleted set in training that is not current training")
        }
    }
    
    private func error(code: Int, message: String) -> NSError {
        NSError(domain: "TRAINING_SET_ERROR_DOMAIN", code: code, userInfo: [NSLocalizedFailureReasonErrorKey: message, NSValidationObjectErrorKey: self])
    }
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
        .receive(on: DispatchQueue.main)
        .sink { _ in self.objectWillChange.send() }
    }
}

extension TrainingSet: Encodable {
    private enum CodingKeys: String, CodingKey {
        case repetitions
        case weight
        case rpe
        case tag
        case comment
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(repetitions, forKey: .repetitions)
        try container.encode(weight, forKey: .weight)
        try container.encodeIfPresent(displayRpe, forKey: .rpe)
        try container.encodeIfPresent(tag, forKey: .tag)
        try container.encodeIfPresent(comment, forKey: .comment)
    }
}
