//
//  WorkoutSet.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
import Combine

extension WorkoutSet {
    public var id: NSManagedObjectID { self.objectID }
}

public class WorkoutSet: NSManagedObject, Codable {
    public static var MAX_REPETITIONS: Int16 = 9999
    public static var MAX_WEIGHT: Double = 99999
    
    public class func create(context: NSManagedObjectContext) -> WorkoutSet {
        let workoutSet = WorkoutSet(context: context)
        workoutSet.uuid = UUID()
        return workoutSet
    }
    
    // MARK: Normalized properties
    
    public var weightValue: Double {
        get {
            weight?.doubleValue ?? 0
        }
        set {
            weight = newValue as NSNumber
        }
    }
    
    public var repetitionsValue: Int16 {
        get {
            repetitions?.int16Value ?? 0
        }
        set {
            repetitions = newValue as NSNumber
        }
    }
    
    public var minTargetRepetitionsValue: Int16? {
        get {
            minTargetRepetitions?.int16Value
        }
        set {
            minTargetRepetitions = newValue as NSNumber?
        }
    }
    
    public var maxTargetRepetitionsValue: Int16? {
        get {
            maxTargetRepetitions?.int16Value
        }
        set {
            maxTargetRepetitions = newValue as NSNumber?
        }
    }
    
    public var tagValue: WorkoutSetTag? {
        get {
            WorkoutSetTag(rawValue: tag ?? "")
        }
        set {
            tag = newValue?.rawValue
        }
    }
    
    public var rpeValue: Double? {
        get {
            RPE.allowedValues.contains(rpe) ? rpe : nil
        }
        set {
            let newValue = newValue ?? 0
            rpe = RPE.allowedValues.contains(newValue) ? newValue : 0
        }
    }
    
    // MARK: Derived properties
    
    public func estimatedOneRepMax(maxReps: Int) -> Double? {
        guard repetitionsValue > 0 && repetitionsValue <= maxReps else { return nil }
        assert(repetitionsValue < 37) // formula doesn't work for 37+ reps
        return weightValue * (36 / (37 - Double(repetitionsValue))) // Brzycki 1RM formula
    }

    public var isPersonalRecord: Bool? {
        guard let weight = weight else { return nil }
        guard let repetitions = repetitions else { return nil }
        guard let start = workoutExercise?.workout?.start else { return nil }
        guard let exerciseUuid = workoutExercise?.exerciseUuid else { return nil }

        let previousSetsRequest: NSFetchRequest<WorkoutSet> = WorkoutSet.fetchRequest()
        let previousSetsPredicate = NSPredicate(format:
            "\(#keyPath(WorkoutSet.workoutExercise.exerciseUuid)) == %@ AND \(#keyPath(WorkoutSet.isCompleted)) == %@ AND \(#keyPath(WorkoutSet.workoutExercise.workout.start)) < %@",
            exerciseUuid as CVarArg, true as NSNumber, start as NSDate
        )
        previousSetsRequest.predicate = previousSetsPredicate
        guard let numberOfPreviousSets = try? managedObjectContext?.count(for: previousSetsRequest) else { return nil }
        if numberOfPreviousSets == 0 { return false } // if there was no set for this exercise in a prior workout, we consider no set as a PR

        let betterOrEqualPreviousSetsRequest: NSFetchRequest<WorkoutSet> = WorkoutSet.fetchRequest()
        betterOrEqualPreviousSetsRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:
            [
                previousSetsPredicate,
                NSPredicate(format: "\(#keyPath(WorkoutSet.weight)) >= %@ AND \(#keyPath(WorkoutSet.repetitions)) >= %@", weight, repetitions)
            ]
        )
        guard let numberOfBetterOrEqualPreviousSets = try? managedObjectContext?.count(for: betterOrEqualPreviousSetsRequest) else { return nil }
        if numberOfBetterOrEqualPreviousSets > 0 { return false } // there are better sets
        
        guard let index = workoutExercise?.workoutSets?.index(of: self), index != NSNotFound else { return nil }
        guard let numberOfBetterOrEqualPreviousSetsInCurrentWorkout = (workoutExercise?.workoutSets?.array[0..<index]
            .compactMap { $0 as? WorkoutSet }
            .filter { $0.weightValue >= weightValue && $0.repetitionsValue >= repetitionsValue }
            .count)
            else { return nil }
        return numberOfBetterOrEqualPreviousSetsInCurrentWorkout == 0
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case uuid
        case repetitions
        case minTargetRepetitions
        case maxTargetRepetitions
        case weight
        case rpe
        case tag
        case comment
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let contextKey = CodingUserInfoKey.managedObjectContextKey,
            let context = decoder.userInfo[contextKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "WorkoutSet", in: context)
            else {
            throw CodingUserInfoKey.DecodingError.managedObjectContextMissing
        }
        self.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decodeIfPresent(UUID.self, forKey: .uuid) ?? UUID() // make sure we always have an UUID
        repetitionsValue = try container.decode(Int16.self, forKey: .repetitions)
        weightValue = try container.decode(Double.self, forKey: .weight)
        rpeValue = try container.decodeIfPresent(Double.self, forKey: .rpe)
        tagValue = WorkoutSetTag(rawValue: try container.decodeIfPresent(String.self, forKey: .tag) ?? "")
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        minTargetRepetitionsValue = try container.decodeIfPresent(Int16.self, forKey: .minTargetRepetitions)
        maxTargetRepetitionsValue = try container.decodeIfPresent(Int16.self, forKey: .maxTargetRepetitions)
        isCompleted = true
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid ?? UUID(), forKey: .uuid)
        try container.encode(repetitionsValue, forKey: .repetitions)
        try container.encode(weightValue, forKey: .weight)
        try container.encodeIfPresent(rpeValue, forKey: .rpe)
        try container.encodeIfPresent(tagValue?.rawValue, forKey: .tag)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(minTargetRepetitionsValue, forKey: .minTargetRepetitions)
        try container.encodeIfPresent(maxTargetRepetitionsValue, forKey: .maxTargetRepetitions)
    }
}

// MARK: Display

extension WorkoutSet {
    public func displayTitle(unit: UnitMass, formatter: MeasurementFormatter) -> String {
//        let numberFormatter = unit.numberFormatter
//        numberFormatter.minimumFractionDigits = unit.defaultFractionDigits
//        let weightInUnit = WeightUnit.convert(weight: weight, from: .metric, to: unit)
//        return "\(numberFormatter.string(from: weightInUnit as NSNumber) ?? String(format: "%\(unit.maximumFractionDigits).f")) \(unit.abbrev) × \(repetitions)"
        return formatter.string(from: Measurement(value: weightValue, unit: UnitMass.kilograms).converted(to: unit)) + " × \(repetitionsValue)"
    }
    
    public func logTitle(unit: UnitMass, formatter: MeasurementFormatter) -> String {
        let title = displayTitle(unit: unit, formatter: formatter)
        guard let tag = tagValue?.title.capitalized, !tag.isEmpty else { return title }
        return title + " (\(tag))"
    }
}

// MARK: Validation

extension WorkoutSet {
    override public func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateConsistency()
    }
    
    override public func validateForInsert() throws {
        try super.validateForInsert()
        try validateConsistency()
    }
    
    func validateConsistency() throws {
        if !isCompleted, let workout = workoutExercise?.workout, !workout.isCurrentWorkout {
            throw error(code: 1, message: "The set is not completed eventhough its workout is not the current workout.")
        }
    }
    
    private func error(code: Int, message: String) -> NSError {
        NSError(domain: "WORKOUT_SET_ERROR_DOMAIN", code: code, userInfo: [NSLocalizedFailureReasonErrorKey: message, NSValidationObjectErrorKey: self])
    }
}
