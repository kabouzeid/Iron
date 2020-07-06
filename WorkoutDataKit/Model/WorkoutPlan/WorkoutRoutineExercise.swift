//
//  WorkoutPlan.swift
//  WorkoutDataKit
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

public class WorkoutRoutineExercise: NSManagedObject, Codable {
    public class func create(context: NSManagedObjectContext) -> WorkoutRoutineExercise {
        let workoutRoutineExercise = WorkoutRoutineExercise(context: context)
        workoutRoutineExercise.uuid = UUID()
        return workoutRoutineExercise
    }
    
    public var subtitle: String? {
        guard let workoutRoutineSets = workoutRoutineSets?.compactMap({ $0 as? WorkoutRoutineSet }) else { return nil }
        
        if let firstSet = workoutRoutineSets.first {
            let minRepetitions = firstSet.minRepetitionsValue
            let maxRepetitions = firstSet.maxRepetitionsValue
            
            var sameReps = true
            for set in workoutRoutineSets {
                if minRepetitions != set.minRepetitionsValue || maxRepetitions != set.maxRepetitionsValue {
                    sameReps = false
                    break
                }
            }
            if sameReps {
                func reps() -> String? {
                    if let minRepetitions = minRepetitions {
                        if let maxRepetitions = maxRepetitions {
                            return "\(minRepetitions == maxRepetitions ? "\(maxRepetitions)" : "\(minRepetitions)–\(maxRepetitions)")"
                        } else {
                            return ">\(minRepetitions)"
                        }
                    } else if let maxRepetitions = maxRepetitions {
                        return "<\(maxRepetitions)"
                    } else {
                        return nil
                    }
                }
                if let reps = reps() {
                    return "\(workoutRoutineSets.count) sets of \(reps) reps"
                }
            }
        }
        
        return "\(workoutRoutineSets.count) sets"
    }
    
    public func exercise(in exercises: [Exercise]) -> Exercise? {
        ExerciseStore.find(in: exercises, with: exerciseUuid)
    }
    
    // MARK: - Codable
    private enum CodingKeys: String, CodingKey {
        case uuid
        case exerciseUuid
        case exerciseName
        case comment
        case sets
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let contextKey = CodingUserInfoKey.managedObjectContextKey,
            let context = decoder.userInfo[contextKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "WorkoutRoutineExercise", in: context)
            else {
            throw CodingUserInfoKey.DecodingError.managedObjectContextMissing
        }
        self.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decodeIfPresent(UUID.self, forKey: .uuid) ?? UUID() // make sure we always have an UUID
        exerciseUuid = try container.decodeIfPresent(UUID.self, forKey: .exerciseUuid)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        workoutRoutineSets = NSOrderedSet(array: try container.decodeIfPresent([WorkoutRoutineSet].self, forKey: .sets) ?? [])
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid ?? UUID(), forKey: .uuid)
        try container.encodeIfPresent(exerciseUuid, forKey: .exerciseUuid)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(workoutRoutineSets?.array.compactMap { $0 as? WorkoutRoutineSet }, forKey: .sets)
        
        if let exercisesKey = CodingUserInfoKey.exercisesKey,
            let exercises = encoder.userInfo[exercisesKey] as? [Exercise] {
            try container.encodeIfPresent(exercise(in: exercises)?.title, forKey: .exerciseName)
        }
    }
}
