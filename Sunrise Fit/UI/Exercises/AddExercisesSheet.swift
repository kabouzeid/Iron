//
//  AddExercisesSheet.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 03.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct AddExercisesSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    let onAdd: (Set<Exercise>) -> Void
    
    @State private var filter = ""
    @State private var exerciseSelectorSelection: Set<Exercise> = Set()
    
    private var exercises: [[Exercise]] {
        Exercises.filterExercises(exercises: Exercises.exercisesGrouped, using: filter)
    }
    
    private func resetAndDismiss() {
        self.presentationMode.wrappedValue.dismiss()
        self.exerciseSelectorSelection.removeAll()
        self.filter = ""
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                HStack {
                    Button("Cancel") {
                        self.resetAndDismiss()
                    }
                    Spacer()
                    Button("Add") {
                        self.onAdd(self.exerciseSelectorSelection)
                        self.resetAndDismiss()
                    }
                    .environment(\.isEnabled, !self.exerciseSelectorSelection.isEmpty)
                }
                TextField("Search", text: $filter)
                    .textFieldStyle(SearchTextFieldStyle(text: $filter))
            }
            .padding()
            ExerciseMultiSelectionView(exerciseMuscleGroups: exercises, selection: self.$exerciseSelectorSelection)
        }
    }
}

struct AddExercisesSheet_Previews: PreviewProvider {
    static var previews: some View {
//        Color.clear.sheet(isPresented: .constant(true)) {
            AddExercisesSheet(onAdd: { _ in })
//        }
    }
}
