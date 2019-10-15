//
//  ExerciseMultiSelectionView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ExerciseMultiSelectionView: View {
    var exerciseMuscleGroups: [[Exercise]]
    @Binding var selection: Set<Exercise>
    
    var body: some View {
        List(selection: $selection) {
            ForEach(exerciseMuscleGroups, id: \.first?.muscleGroup) { exercises in
                Section(header: Text(exercises.first?.muscleGroup.capitalized ?? "")) {
                    ForEach(exercises, id: \.self) { exercise in
                        Text(exercise.title)
                    }
                }
            }
        }
        .environment(\.editMode, .constant(.active))
    }
}

#if DEBUG
struct ExerciseMultiSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseMultiSelectionView(exerciseMuscleGroups: ExerciseStore.splitIntoMuscleGroups(exercises: ExerciseStore.shared.shownExercises), selection: .constant(Set()))
    }
}
#endif
