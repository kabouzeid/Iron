//
//  ExerciseHistoryView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 06.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import WorkoutDataKit

struct ExerciseHistoryView : View {
    @FetchRequest(fetchRequest: WorkoutExercise.fetchRequest()) var history // will be overwritten in init()

    var exercise: Exercise
    
    init(exercise: Exercise) {
        self.exercise = exercise
        _history = FetchRequest(fetchRequest: WorkoutExercise.historyFetchRequest(of: exercise.uuid, until: nil))
    }
    
    private func workoutSets(for workoutExercise: WorkoutExercise) -> [WorkoutSet] {
        workoutExercise.workoutSets?.array as! [WorkoutSet]
    }
    
    private func indexedWorkoutSets(for workoutExercise: WorkoutExercise) -> [(Int, WorkoutSet)] {
        workoutSets(for: workoutExercise).enumerated().map { ($0 + 1, $1) }
    }
    
    var body: some View {
        List {
            ForEach(history) { workoutExercise in
                Section(header: WorkoutExerciseSectionHeader(workoutExercise: workoutExercise)) {
                    workoutExercise.comment.map {
                        Text($0.enquoted)
                            .lineLimit(1)
                            .font(Font.body.italic())
                            .foregroundColor(.secondary)
                    }
                    ForEach(self.indexedWorkoutSets(for: workoutExercise), id: \.1.id) { index, workoutSet in
                        WorkoutSetCell(workoutSet: workoutSet, index: index, colorMode: .activated)
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}

#if DEBUG
struct ExerciseHistoryView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseHistoryView(exercise: ExerciseStore.shared.exercises.first(where: { $0.everkineticId == 42 })!)
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
