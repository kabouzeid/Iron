//
//  WorkoutPlan.swift
//  WorkoutDataKit
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

public class WorkoutRoutineSet: NSManagedObject {
    public static let supportedTags = [WorkoutSetTag.dropSet]
    
    public class func create(context: NSManagedObjectContext) -> WorkoutRoutineSet {
        let workoutRoutineSet = WorkoutRoutineSet(context: context)
        workoutRoutineSet.uuid = UUID()
        return workoutRoutineSet
    }
    
    // MARK: Normalized properties
    
    public var repetitionsMinValue: Int16? {
        get {
            repetitionsMin?.int16Value
        }
        set {
            repetitionsMin = newValue as NSNumber?
        }
    }
    
    public var repetitionsMaxValue: Int16? {
        get {
            repetitionsMax?.int16Value
        }
        set {
            repetitionsMax = newValue as NSNumber?
        }
    }
    
    public var tagValue: WorkoutSetTag? {
        get {
            guard let tag = WorkoutSetTag(rawValue: self.tag ?? "") else { return nil }
            guard Self.supportedTags.contains(tag) else { return nil }
            return tag
        }
        set {
            if let tag = newValue, !Self.supportedTags.contains(tag) { return }
            tag = newValue?.rawValue
        }
    }
}

// MARK: Display

extension WorkoutRoutineSet {
    public var displayTitle: String? {
        guard let repsMin = repetitionsMinValue, let repsMax = repetitionsMaxValue else { return nil }
        return "\(repsMin == repsMax ? "\(repsMax)" : "\(repsMin)-\(repsMax)") reps"
    }
}

// MARK: Validation

extension WorkoutRoutineSet {
    override public func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateConsistency()
    }
    
    override public func validateForInsert() throws {
        try super.validateForInsert()
        try validateConsistency()
    }
    
    func validateConsistency() throws {
        if (repetitionsMin == nil && repetitionsMax != nil) {
            throw error(code: 1, message: "min repetitions is not set, but max repetitions is set.")
        }
        if (repetitionsMin != nil && repetitionsMax == nil) {
            throw error(code: 1, message: "max repetitions is not set, but min repetitions is set.")
        }
    }
    
    private func error(code: Int, message: String) -> NSError {
        NSError(domain: "WORKOUT_ROUTINE_SET_ERROR_DOMAIN", code: code, userInfo: [NSLocalizedFailureReasonErrorKey: message, NSValidationObjectErrorKey: self])
    }
}
