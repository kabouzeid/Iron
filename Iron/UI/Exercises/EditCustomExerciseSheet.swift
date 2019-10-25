//
//  EditCustomExerciseSheet.swift
//  Iron
//
//  Created by Karim Abou Zeid on 23.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct EditCustomExerciseSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var exerciseStore: ExerciseStore
    @State private var exerciseValues: EditCustomExerciseView.ExerciseValues
    private let exercise: Exercise
    
    init(exercise: Exercise) {
        self.exercise = exercise
        let primaryMuscle = exercise.primaryMuscle.map { EditCustomExerciseView.ExerciseValues.ExerciseMuscle(type: .primary, muscle: $0) }
        let secondaryMuscle = exercise.secondaryMuscle.map { EditCustomExerciseView.ExerciseValues.ExerciseMuscle(type: .secondary, muscle: $0) }
        _exerciseValues = State(initialValue: .init(title: exercise.title, description: exercise.description ?? "", muscles: Set(primaryMuscle + secondaryMuscle), type: exercise.type))
    }
    
    private var canSave: Bool {
        let title = exerciseValues.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return false }
        guard !exerciseStore.exercises.contains(where: { $0.title == title && $0.uuid != exercise.uuid }) else { return false }
        // TODO: and at least one muscle
        return true
    }
    
    private var saveButton: some View {
        Button("Save") {
            let title = self.exerciseValues.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let description = self.exerciseValues.description.trimmingCharacters(in: .whitespacesAndNewlines)
            let primaryMuscle = self.exerciseValues.muscles
                .map { $0 }
                .filter { $0.type == .primary }
                .sorted { $0.shortDisplayTitle < $1.shortDisplayTitle }
                .map { $0.muscle }
            let secondaryMuscle = self.exerciseValues.muscles
                .map { $0 }
                .filter { $0.type == .secondary }
                .sorted { $0.shortDisplayTitle < $1.shortDisplayTitle }
                .map { $0.muscle }
            self.exerciseStore.updateCustomExercise(with: self.exercise.uuid, title: title, description: description.isEmpty ? nil : description, primaryMuscle: primaryMuscle, secondaryMuscle: secondaryMuscle, type: self.exerciseValues.type)
            self.presentationMode.wrappedValue.dismiss()
        }.disabled(!canSave)
    }
    
    var body: some View {
        NavigationView {
            EditCustomExerciseView(exerciseValues: $exerciseValues)
                .navigationBarTitle("Edit Exercise", displayMode: .inline)
                .navigationBarItems(
                    leading:
                    Button("Cancel") {
                        self.presentationMode.wrappedValue.dismiss()
                    },
                    trailing: saveButton
                )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
