//
//  WorkoutPlan.swift
//  WorkoutDataKit
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

public class WorkoutPlan: NSManagedObject, Codable {
    public class func create(context: NSManagedObjectContext) -> WorkoutPlan {
        let workoutPlan = WorkoutPlan(context: context)
        workoutPlan.uuid = UUID()
        return workoutPlan
    }
    
    public var displayTitle: String {
        title ?? "Workout Plan"
    }
    
    public func duplicate(context: NSManagedObjectContext) -> WorkoutPlan {
        let workoutPlanCopy = WorkoutPlan.create(context: context)
        workoutPlanCopy.title = self.title
        workoutPlanCopy.workoutRoutines = NSOrderedSet(array:
            self.workoutRoutines?
                .compactMap { $0 as? WorkoutRoutine }
                .map { workoutRoutine in
                    let workoutRoutineCopy = WorkoutRoutine.create(context: context)
                    workoutRoutineCopy.title = workoutRoutine.title
                    workoutRoutineCopy.comment = workoutRoutine.comment
                    workoutRoutineCopy.workoutRoutineExercises = NSOrderedSet(array:
                        workoutRoutine.workoutRoutineExercises?
                            .compactMap { $0 as? WorkoutRoutineExercise }
                            .map { workoutRoutineExercise in
                                let workoutRoutineExerciseCopy = WorkoutRoutineExercise.create(context: context)
                                workoutRoutineExerciseCopy.exerciseUuid = workoutRoutineExercise.exerciseUuid
                                workoutRoutineExerciseCopy.comment = workoutRoutineExercise.comment
                                workoutRoutineExerciseCopy.workoutRoutineSets = NSOrderedSet(array:
                                    workoutRoutineExercise.workoutRoutineSets?
                                        .compactMap { $0 as? WorkoutRoutineSet }
                                        .map { workoutRoutineSet in
                                            let workoutRoutineSetCopy  = WorkoutRoutineSet.create(context: context)
                                            workoutRoutineSetCopy.repetitionsMax = workoutRoutineSet.repetitionsMax
                                            workoutRoutineSetCopy.repetitionsMin = workoutRoutineSet.repetitionsMin
                                            workoutRoutineSetCopy.tagValue = workoutRoutineSet.tagValue
                                            workoutRoutineSetCopy.comment = workoutRoutineSet.comment
                                            return workoutRoutineSetCopy
                                        }
                                ?? [])
                                return workoutRoutineExerciseCopy
                            }
                    ?? [])
                    return workoutRoutineCopy
                }
        ?? [])
        return workoutPlanCopy
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case uuid
        case title
        case routines
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let contextKey = CodingUserInfoKey.managedObjectContextKey,
            let context = decoder.userInfo[contextKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "WorkoutPlan", in: context)
            else {
            throw CodingUserInfoKey.DecodingError.managedObjectContextMissing
        }
        self.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decodeIfPresent(UUID.self, forKey: .uuid) ?? UUID() // make sure we always have an UUID
        title = try container.decodeIfPresent(String.self, forKey: .title)
        workoutRoutines = NSOrderedSet(array: try container.decodeIfPresent([WorkoutRoutine].self, forKey: .routines) ?? [])
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid ?? UUID(), forKey: .uuid)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(workoutRoutines?.array.compactMap { $0 as? WorkoutRoutine }, forKey: .routines)
    }
}
