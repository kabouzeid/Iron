//
//  AddExercisesSheet.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 03.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct AddExercisesSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    let onAdd: (Set<Exercise>) -> Void
    
    @ObservedObject private var filter: ExerciseGroupFilter
    
    @State private var exerciseSelectorSelection: Set<Exercise> = Set()
    
    init(exercises: [Exercise], onAdd: @escaping (Set<Exercise>) -> Void) {
        self.filter = ExerciseGroupFilter(exercises: ExerciseStore.splitIntoMuscleGroups(exercises: exercises))
        self.onAdd = onAdd
    }
    
    private func resetAndDismiss() {
        self.presentationMode.wrappedValue.dismiss()
        self.exerciseSelectorSelection.removeAll()
        self.filter.filter = ""
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                SheetBar(title: "Add Exercises",
                    leading:
                    Button("Cancel") {
                        self.resetAndDismiss()
                    },
                    trailing:
                    Button("Add") {
                        self.onAdd(self.exerciseSelectorSelection)
                        self.resetAndDismiss()
                    }
                    .environment(\.isEnabled, !self.exerciseSelectorSelection.isEmpty)
                )
                TextField("Search", text: $filter.filter)
                    .textFieldStyle(SearchTextFieldStyle(text: $filter.filter))
                    .padding(.top)
            }.padding()
            
            ExerciseMultiSelectionView(exerciseMuscleGroups: filter.exercises, selection: self.$exerciseSelectorSelection)
        }
    }
}

struct AddExercisesSheet_Previews: PreviewProvider {
    static var previews: some View {
//        Color.clear.sheet(isPresented: .constant(true)) {
        AddExercisesSheet(exercises: ExerciseStore.shared.shownExercises, onAdd: { _ in })
//        }
    }
}
