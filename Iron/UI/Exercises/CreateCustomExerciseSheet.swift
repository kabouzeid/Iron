//
//  CreateCustomExerciseSheet.swift
//  Iron
//
//  Created by Karim Abou Zeid on 23.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct CreateCustomExerciseSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var exerciseStore: ExerciseStore
    @State private var exerciseValues = EditCustomExerciseView.ExerciseValues(title: "", description: "", muscles: Set(), type: .other)
    
    private var canSave: Bool {
        let title = exerciseValues.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return false }
        guard !exerciseStore.exercises.contains(where: { $0.title == title }) else { return false }
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
            self.exerciseStore.createCustomExercise(title: title, description: description.isEmpty ? nil : description, primaryMuscle: primaryMuscle, secondaryMuscle: secondaryMuscle, type: self.exerciseValues.type)
            self.presentationMode.wrappedValue.dismiss()
            
            // haptic feedback
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.notificationOccurred(.success)
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
