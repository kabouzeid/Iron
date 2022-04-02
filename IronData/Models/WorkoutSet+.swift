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
        let workoutAlias = TableAlias()
        let workoutExerciseAlias = TableAlias()
        let workoutSetAlias = TableAlias()
        
        let numberOfBetterSets: Int = try WorkoutSet.aliased(workoutSetAlias)
            .joining(required: WorkoutSet.workoutExercise.aliased(workoutExerciseAlias)
                .joining(required: WorkoutExercise.workout.aliased(workoutAlias))
            )
            .filter(
                workoutExerciseAlias[WorkoutExercise.Columns.exerciseId == info.workoutExercise.exerciseId] &&
                (
                    // better
                    workoutSetAlias[WorkoutSet.Columns.repetitions] > self.repetitions! &&
                    workoutSetAlias[WorkoutSet.Columns.weight] > self.weight!
                ) ||
                (
                    // equal but earlier
                    (
                        // equal
                        workoutSetAlias[WorkoutSet.Columns.repetitions] == self.repetitions! &&
                        workoutSetAlias[WorkoutSet.Columns.weight] == self.weight!
                    ) &&
                    (
                        // earlier workout
                        workoutAlias[Workout.Columns.start] < info.workout.start ||
                        (
                            // same workout but earlier exercise
                            workoutAlias[Workout.Columns.start] == info.workout.start &&
                            (
                                workoutExerciseAlias[WorkoutExercise.Columns.order] < info.workoutExercise.order ||
                                (
                                    // same exercise but earlier set
                                    workoutExerciseAlias[WorkoutExercise.Columns.order] == info.workoutExercise.order &&
                                    workoutSetAlias[WorkoutSet.Columns.order] < self.order
                                )
                            )
                        )
                    )
                )
            )
            .fetchCount(db)
        return numberOfBetterSets == 0
    }
}
