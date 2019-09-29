//
//  TrainingDetailView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct TrainingDetailView : View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    @ObservedObject var training: Training

//    @Environment(\.editMode) var editMode
    @State private var showingExerciseSelectorSheet = false

    @ObservedObject private var trainingCommentInput = ValueHolder<String?>(initial: nil)
    private var trainingComment: Binding<String> {
        Binding(
            get: {
                self.trainingCommentInput.value ?? self.training.comment ?? ""
        },
            set: { newValue in
                self.trainingCommentInput.value = newValue
        }
        )
    }
    private func adjustAndSaveTrainingCommentInput() {
        guard let newValue = trainingCommentInput.value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        trainingCommentInput.value = newValue
        training.comment = newValue.isEmpty ? nil : newValue
    }
    
    @ObservedObject private var trainingTitleInput = ValueHolder<String?>(initial: nil)
    private var trainingTitle: Binding<String> {
        Binding(
            get: {
                self.trainingTitleInput.value ?? self.training.title ?? ""
            },
            set: { newValue in
                self.trainingTitleInput.value = newValue
            }
        )
    }
    private func adjustAndSaveTrainingTitleInput() {
        guard let newValue = trainingTitleInput.value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        trainingTitleInput.value = newValue
        training.title = newValue.isEmpty ? nil : newValue
    }

    private var trainingExercises: [TrainingExercise] {
        training.trainingExercises?.array as? [TrainingExercise] ?? []
    }
    
    private func trainingSets(trainingExercise: TrainingExercise) -> [TrainingSet] {
        trainingExercise.trainingSets?.array as? [TrainingSet] ?? []
    }
    
    private func trainingExerciseView(trainingExercise: TrainingExercise) -> some View {
        VStack(alignment: .leading) {
            Text(trainingExercise.exercise(in: self.exerciseStore.exercises)?.title ?? "")
                .font(.body)
            trainingExercise.comment.map {
                Text($0.enquoted)
                    .lineLimit(1)
                    .font(Font.caption.italic())
                    .foregroundColor(.secondary)
            }
            ForEach(self.trainingSets(trainingExercise: trainingExercise), id: \.objectID) { trainingSet in
                Text(trainingSet.logTitle(unit: self.settingsStore.weightUnit))
                    .font(Font.body.monospacedDigit())
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                TrainingDetailBannerView(training: training)
                    .listRowBackground(training.muscleGroupColor(in: self.exerciseStore.exercises))
                    .environment(\.colorScheme, .dark) // TODO: check whether accent color is actually dark
            }
            
            // editMode still doesn't work in 13.1 beta2
//            if editMode?.wrappedValue == .active {
                Section {
                    // TODO: add clear button
                    TextField("Title", text: trainingTitle, onEditingChanged: { isEditingTextField in
                        if !isEditingTextField {
                            self.adjustAndSaveTrainingTitleInput()
                        }
                    })
                    TextField("Comment", text: trainingComment, onEditingChanged: { isEditingTextField in
                        if !isEditingTextField {
                            self.adjustAndSaveTrainingCommentInput()
                        }
                    })
                }
                
                Section {
                    DatePicker(selection: $training.safeStart, in: ...min(training.safeEnd, Date())) {
                        Text("Start")
                    }
                    
                    DatePicker(selection: $training.safeEnd, in: training.safeStart...Date()) {
                        Text("End")
                    }
                }
//            }

            Section {
                ForEach(trainingExercises, id: \.objectID) { trainingExercise in
                    NavigationLink(destination: TrainingExerciseDetailView(trainingExercise: trainingExercise).environmentObject(self.settingsStore)) {
                        self.trainingExerciseView(trainingExercise: trainingExercise)
                    }
                }
                .onDelete { offsets in
                    let trainingExercises = self.trainingExercises
                    for i in offsets {
                        let trainingExercise = trainingExercises[i]
                        self.managedObjectContext.delete(trainingExercise)
                        trainingExercise.training?.removeFromTrainingExercises(trainingExercise)
                    }
                    self.managedObjectContext.safeSave()
                }
                .onMove { source, destination in
                    guard var trainingExercises = self.training.trainingExercises?.array as? [TrainingExercise] else { return }
                    trainingExercises.move(fromOffsets: source, toOffset: destination)
                    self.training.trainingExercises = NSOrderedSet(array: trainingExercises)
                    self.managedObjectContext.safeSave()
                }
                
                Button(action: {
                    self.showingExerciseSelectorSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Exercises")
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text(training.displayTitle(in: exerciseStore.exercises)), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack(spacing: NAVIGATION_BAR_SPACING) {
                Button(action: {
                    guard let logText = self.training.logText(in: self.exerciseStore.exercises, weightUnit: self.settingsStore.weightUnit) else { return }
                    let ac = UIActivityViewController(activityItems: [logText], applicationActivities: nil)
                    // TODO: replace this hack with a proper way to retreive the rootViewController
                    guard let rootVC = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else { return }
                    rootVC.present(ac, animated: true)
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                EditButton()
            }
        )
        .sheet(isPresented: $showingExerciseSelectorSheet) {
            AddExercisesSheet(exercises: self.exerciseStore.exercises, onAdd: { selection in
                for exercise in selection {
                    let trainingExercise = TrainingExercise(context: self.managedObjectContext)
                    self.training.addToTrainingExercises(trainingExercise)
                    trainingExercise.exerciseId = Int16(exercise.id)
                }
                self.managedObjectContext.safeSave()
            })
        }
    }
}

#if DEBUG
struct TrainingDetailView_Previews : PreviewProvider {
    static var previews: some View {
        return TrainingDetailView(training: mockTraining)
            .environmentObject(SettingsStore.mockMetric)
            .environmentObject(ExerciseStore.shared)
            .environment(\.managedObjectContext, mockManagedObjectContext)
    }
}
#endif
