//
//  CustomExercisesView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 17.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData

struct CustomExercisesView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    let exercises: [Exercise]
    
    @State private var showCreateCustomExerciseSheet = false
    
    @State private var offsetsToDelete: IndexSet?
    
    var body: some View {
        List {
            ForEach(exercises, id: \.id) { exercise in
                NavigationLink(exercise.title, destination: ExerciseDetailView(exercise: exercise)
                    .environmentObject(self.settingsStore))
            }
            .onDelete { offsets in
                self.offsetsToDelete = offsets
            }
            Button(action: {
                self.showCreateCustomExerciseSheet = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Exercise")
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarItems(trailing: EditButton())
        .sheet(isPresented: $showCreateCustomExerciseSheet) {
            CreateCustomExerciseSheet()
                .environmentObject(self.exerciseStore)
        }
        .actionSheet(item: $offsetsToDelete) { offsets in
            // TODO: in future only show this warning when there are in fact sets that will be deleted
            ActionSheet(title: Text("This cannot be undone."), message: Text("Warning: Any set belonging to this exercise will be deleted too."), buttons: [
                .destructive(Text("Delete"), action: {
                    for i in offsets {
                        let id = self.exercises[i].id
                        self.deleteTrainingExercises(with: id)
                        self.exerciseStore.deleteCustomExercise(with: id)
                    }
                    self.managedObjectContext.safeSave()
                }),
                .cancel()
            ])
        }
    }
    
    private func deleteTrainingExercises(with id: Int) {
        let request: NSFetchRequest<TrainingExercise> = TrainingExercise.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(TrainingExercise.exerciseId)) == %@", NSNumber(value: id))
        guard let trainingExercises = try? managedObjectContext.fetch(request) else { return }
        trainingExercises.forEach { managedObjectContext.delete($0) }
    }
}

private struct CreateCustomExerciseSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var exerciseStore: ExerciseStore
    @State private var exerciseValues = EditCustomExerciseView.ExerciseValues(title: "", description: "", muscles: Set(), barbellBased: false)
    
    private var canSave: Bool {
        // TODO: and at least one muscle
        !exerciseValues.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
            self.exerciseStore.createCustomExercise(title: title, description: description.isEmpty ? nil : description, primaryMuscle: primaryMuscle, secondaryMuscle: secondaryMuscle, barbellBased: self.exerciseValues.barbellBased)
            self.presentationMode.wrappedValue.dismiss()
            
            // haptic feedback
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.notificationOccurred(.success)
        }.disabled(!canSave)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SheetBar(title: "Create Exercise",
                leading:
                Button("Close") {
                    self.presentationMode.wrappedValue.dismiss()
                },
                trailing: saveButton).padding()
            Divider()
            EditCustomExerciseView(exerciseValues: $exerciseValues)
        }
    }
}

struct CustomExercisesView_Previews: PreviewProvider {
    static var previews: some View {
        CustomExercisesView(exercises: [Exercise(id: 0, title: "My Custom Exercise", alias: [], description: nil, primaryMuscle: [], secondaryMuscle: [], equipment: [], steps: [], tips: [], references: [], pdfPaths: [])])
            .environmentObject(appSettingsStore)
            .environmentObject(appExerciseStore)
    }
}
