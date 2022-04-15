//
//  WorkoutExercise+.swift
//  IronData
//
//  Created by Karim Abou Zeid on 14.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import GRDB

extension WorkoutExercise {
    public func previousWorkoutExercisesFilter(workoutExerciseAlias: TableAlias, workoutAlias: TableAlias, workout: Workout) -> SQLSpecificExpressible {
        workoutExerciseAlias[WorkoutExercise.Columns.exerciseId == exerciseId] &&
        workoutAlias[Workout.Columns.start < workout.start] ||
        (workoutAlias[Workout.Columns.start == workout.start] && workoutExerciseAlias[WorkoutExercise.Columns.order < order])
    }
}
