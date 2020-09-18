//
//  ExerciseSingleSelectionView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct ExerciseSingleSelectionView: View {
    var exerciseGroups: [ExerciseGroup]
    var onSelection: (Exercise) -> Void
    
    var body: some View {
        List {
            ForEach(exerciseGroups) { exerciseGroup in
                Section(header: Text(exerciseGroup.title.capitalized)) {
                    ForEach(exerciseGroup.exercises, id: \.self) { exercise in
                        Button(exercise.title) {
                            self.onSelection(exercise)
                        }.foregroundColor(.primary)
                    }
                }
            }
        }
        .listStyleCompat_InsetGroupedListStyle()
    }
}

#if DEBUG
struct ExerciseSingleSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseSingleSelectionView(exerciseGroups: ExerciseStore.splitIntoMuscleGroups(exercises: ExerciseStore.shared.shownExercises)) { _ in }
    }
}
#endif
