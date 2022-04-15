//
//  WorkoutSet+.swift
//  IronData
//
//  Created by Karim Abou Zeid on 28.03.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import GRDB

extension WorkoutSet {
    public func isPersonalRecord(_ db: Database, info: (workoutExercise: WorkoutExercise, workout: Workout)) throws -> Bool {
        guard let weight = weight, let repetitions = repetitions else { return false }
        
        let workoutAlias = TableAlias()
        let workoutExerciseAlias = TableAlias()
        let workoutSetAlias = TableAlias()
        
        let numberOfBetterSets: Int = try WorkoutSet.aliased(workoutSetAlias)
            .joining(required: WorkoutSet.workoutExercise.aliased(workoutExerciseAlias)
                .joining(required: WorkoutExercise.workout.aliased(workoutAlias))
            )
            .filter(
                previousWorkoutSetsFilter(
                    workoutSetAlias: workoutSetAlias,
                    workoutExerciseAlias: workoutExerciseAlias,
                    workoutAlias: workoutAlias,
                    info: info
                ) &&
                workoutSetAlias[WorkoutSet.Columns.isCompleted == true] &&
                workoutSetAlias[WorkoutSet.Columns.repetitions] >= repetitions &&
                workoutSetAlias[WorkoutSet.Columns.weight] >= weight
            )
            .fetchCount(db)
        return numberOfBetterSets == 0
    }
    
    public func previousWorkoutSetsFilter(workoutSetAlias: TableAlias, workoutExerciseAlias: TableAlias, workoutAlias: TableAlias, info: (workoutExercise: WorkoutExercise, workout: Workout)) -> SQLSpecificExpressible {
        info.workoutExercise.previousWorkoutExercisesFilter(workoutExerciseAlias: workoutExerciseAlias, workoutAlias: workoutAlias, workout: info.workout) ||
        (
            workoutAlias[Workout.Columns.start == info.workout.start] &&
            workoutExerciseAlias[WorkoutExercise.Columns.order == info.workoutExercise.order] &&
            workoutSetAlias[WorkoutSet.Columns.order < order]
        )
    }
    
    public func weightAndRepetitionsFromPreviousSet(_ db: Database, info: (previousWorkoutSets: [WorkoutSet], workoutExercise: WorkoutExercise, workout: Workout)) throws -> (weight: Double?, repetitions: Int?)? {
        struct WorkoutExerciseInfo: Decodable, FetchableRecord {
            public var workoutExercise: WorkoutExercise
            public var workoutSets: [WorkoutSet]
        }
        
        let workoutExerciseAlias = TableAlias()
        let workoutAlias = TableAlias()
        
        let workoutExerciseInfos = try WorkoutExercise.aliased(workoutExerciseAlias)
            .joining(required: WorkoutExercise.workout.aliased(workoutAlias))
            .including(all: WorkoutExercise.workoutSets)
            .asRequest(of: WorkoutExerciseInfo.self)
            .filter(info.workoutExercise.previousWorkoutExercisesFilter(
                workoutExerciseAlias: workoutExerciseAlias,
                workoutAlias: workoutAlias,
                workout: info.workout
            ))
            .order(workoutAlias[Workout.Columns.start.desc], WorkoutExercise.Columns.order.desc)
            .fetchAll(db)
        
        let workoutExerciseInfo = workoutExerciseInfos.first { workoutExerciseInfo in
            guard info.previousWorkoutSets.count < workoutExerciseInfo.workoutSets.count else { return false }
            for i in 0..<info.previousWorkoutSets.count {
                if info.previousWorkoutSets[i].weight != workoutExerciseInfo.workoutSets[i].weight ||
                    info.previousWorkoutSets[i].repetitions != workoutExerciseInfo.workoutSets[i].repetitions {
                    return false
                }
            }
            return true
        }
        
        guard let workoutExerciseInfo = workoutExerciseInfo else { return nil }
        let workoutSet = workoutExerciseInfo.workoutSets[info.previousWorkoutSets.count]
        return (weight: workoutSet.weight, repetitions: workoutSet.repetitions)
    }
}
