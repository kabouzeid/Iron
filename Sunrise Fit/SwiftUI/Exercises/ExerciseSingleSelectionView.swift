//
//  ExerciseSingleSelectionView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ExerciseSingleSelectionView: View {
    var exerciseMuscleGroups: [[Exercise]]
    var onSelection: (Exercise?) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Button("Cancel") {
                self.onSelection(nil)
            }.padding()
            List {
                ForEach(exerciseMuscleGroups, id: \.first?.muscleGroup) { exercises in
                    Section(header: Text(exercises.first?.muscleGroup.capitalized ?? "")) {
                        ForEach(exercises, id: \.self) { exercise in
                            Button(exercise.title) {
                                self.onSelection(exercise)
                            }
                        }
                    }
                }
            }
        }
    }
}

#if DEBUG
struct ExerciseSingleSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseSingleSelectionView(exerciseMuscleGroups: EverkineticDataProvider.exercisesGrouped) { _ in }
    }
}
#endif
