//
//  WorkoutPlan.swift
//  WorkoutDataKit
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

public class WorkoutRoutineSet: NSManagedObject, Codable {
    public static let supportedTags = [WorkoutSetTag.dropSet]
    
    public class func create(context: NSManagedObjectContext) -> WorkoutRoutineSet {
        let workoutRoutineSet = WorkoutRoutineSet(context: context)
        workoutRoutineSet.uuid = UUID()
        return workoutRoutineSet
    }
    
    // MARK: Normalized properties
    
    public var minRepetitionsValue: Int16? {
        get {
            minRepetitions?.int16Value
        }
        set {
            minRepetitions = newValue as NSNumber?
        }
    }
    
    public var maxRepetitionsValue: Int16? {
        get {
            maxRepetitions?.int16Value
        }
        set {
            maxRepetitions = newValue as NSNumber?
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
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case uuid
        case minRepetitions
        case maxRepetitions
        case weight
        case rpe
        case tag
        case comment
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let contextKey = CodingUserInfoKey.managedObjectContextKey,
            let context = decoder.userInfo[contextKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "WorkoutRoutineSet", in: context)
            else {
            throw CodingUserInfoKey.DecodingError.managedObjectContextMissing
        }
        self.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decodeIfPresent(UUID.self, forKey: .uuid) ?? UUID() // make sure we always have an UUID
        minRepetitionsValue = try container.decodeIfPresent(Int16.self, forKey: .minRepetitions)
        maxRepetitionsValue = try container.decodeIfPresent(Int16.self, forKey: .maxRepetitions)
        tagValue = WorkoutSetTag(rawValue: try container.decodeIfPresent(String.self, forKey: .tag) ?? "")
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid ?? UUID(), forKey: .uuid)
        try container.encodeIfPresent(minRepetitionsValue, forKey: .minRepetitions)
        try container.encodeIfPresent(minRepetitionsValue, forKey: .maxRepetitions)
        try container.encodeIfPresent(tagValue?.rawValue, forKey: .tag)
        try container.encodeIfPresent(comment, forKey: .comment)
    }
}

// MARK: Display

extension WorkoutRoutineSet {
    public var displayTitle: String? {
        guard let repsMin = minRepetitionsValue, let repsMax = maxRepetitionsValue else { return nil }
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
        if (minRepetitions == nil && maxRepetitions != nil) {
            throw error(code: 1, message: "min repetitions is not set, but max repetitions is set.")
        }
        if (minRepetitions != nil && maxRepetitions == nil) {
            throw error(code: 1, message: "max repetitions is not set, but min repetitions is set.")
        }
    }
    
    private func error(code: Int, message: String) -> NSError {
        NSError(domain: "WORKOUT_ROUTINE_SET_ERROR_DOMAIN", code: code, userInfo: [NSLocalizedFailureReasonErrorKey: message, NSValidationObjectErrorKey: self])
    }
}
