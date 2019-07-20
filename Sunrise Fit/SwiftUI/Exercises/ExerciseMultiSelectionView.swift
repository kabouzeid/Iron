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
    var selectionLabel: Text
    var onSelection: ([Exercise]) -> Void
    
    @State private var selection: Set<Exercise> = Set()
    
    var body: some View {
        VStack {
            HStack {
                Button("Cancel") {
                    self.select(selection: [])
                }
                Spacer()
                Button(action: {
                    self.select(selection: Array(self.selection))
                }) {
                    selectionLabel
                }
            }.padding()
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
    
    private func select(selection: [Exercise]) {
        onSelection(selection)
        self.selection = Set() // reset selection
    }
}

#if DEBUG
struct ExerciseMultiSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseMultiSelectionView(exerciseMuscleGroups: EverkineticDataProvider.exercisesGrouped, selectionLabel: Text("Select")) { _ in }
    }
}
#endif
