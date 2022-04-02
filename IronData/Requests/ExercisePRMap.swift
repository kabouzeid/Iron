//
//  WorkoutSetPRs.swift
//  IronData
//
//  Created by Karim Abou Zeid on 27.03.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import GRDB

@available(*, deprecated)
public enum ExercisePRMap {
    public typealias Map = [Exercise.ID.Wrapped : WorkoutSet]
    
    private struct WorkoutSetInfo: Decodable, FetchableRecord {
        var workoutSet: WorkoutSet
        var workoutExerciseInfo: WorkoutExerciseInfo
        
        struct WorkoutExerciseInfo: Decodable {
            var exercise: Exercise
            var workoutExercise: WorkoutExercise
        }
    }
    
    public static func fetch(_ db: Database) throws -> Map {
        let workoutAlias = TableAlias()
        let workoutExerciseAlias = TableAlias()
        let workoutSetAlias = TableAlias()
        
        let workoutSetInfo = try WorkoutSet.aliased(workoutSetAlias)
            .filter(WorkoutSet.Columns.isCompleted == true)
            .including(required: WorkoutSet.workoutExercise.aliased(workoutExerciseAlias)
                .forKey("workoutExerciseInfo")
                .including(required: WorkoutExercise.exercise)
                .joining(required: WorkoutExercise.workout.aliased(workoutAlias))
            )
            .order([
                workoutAlias[Workout.Columns.start],
                workoutExerciseAlias[WorkoutExercise.Columns.order],
                workoutSetAlias[WorkoutSet.Columns.order]
            ])
            .asRequest(of: WorkoutSetInfo.self)
            .fetchAll(db)
        
        var map: Map = [:]
        
        for workoutSetInfo in workoutSetInfo {
            let exerciseID = workoutSetInfo.workoutExerciseInfo.exercise.id!
            let workoutSet = workoutSetInfo.workoutSet
            
            guard let repetitions = workoutSet.repetitions, let weight = workoutSet.weight else { continue }
            
            guard let bestSet = map[exerciseID] else {
                map[exerciseID] = workoutSet
                continue
            }
            
            if repetitions > bestSet.repetitions! && weight > bestSet.weight! {
                map[exerciseID] = workoutSet
            }
        }
        
        return map
    }
}
