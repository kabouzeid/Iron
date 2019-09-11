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
    @ObservedObject var training: Training

//    @Environment(\.editMode) var editMode
    @State private var showingExerciseSelectorSheet = false

    private var trainingStart: Binding<Date> {
        Binding(
            get: {
                self.training.safeStart
            },
            set: { newValue in
                precondition(self.training.end == nil || newValue <= self.training.end!)
                self.training.start = newValue
            }
        )
    }
    
    private var trainingEnd: Binding<Date> {
        Binding(
            get: {
                self.training.safeEnd
            },
            set: { newValue in
                precondition(self.training.start == nil || newValue >= self.training.start!)
                self.training.end = newValue
            }
        )
    }
    
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
    
    var body: some View {
        List {
            Section {
                TrainingDetailBannerView(training: training)
                    .listRowBackground(training.muscleGroupColor)
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
                    DatePicker(selection: trainingStart, in: ...min(self.training.safeEnd, Date())) {
                        Text("Start")
                    }
                    
                    DatePicker(selection: trainingEnd, in: self.training.safeStart...Date()) {
                        Text("End")
                    }
                }
//            }

            Section {
                ForEach(trainingExercises, id: \.objectID) { trainingExercise in
                    NavigationLink(destination: TrainingExerciseDetailView(trainingExercise: trainingExercise)
                        .environmentObject(self.settingsStore)) {
                        VStack(alignment: .leading) {
                            Text(trainingExercise.exercise?.title ?? "")
                                .font(.body)
                            ForEach(self.trainingSets(trainingExercise: trainingExercise), id: \.objectID) { trainingSet in
                                Text(trainingSet.displayTitle(unit: self.settingsStore.weightUnit))
                                    .font(Font.body.monospacedDigit())
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                            }
                        }
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
        .navigationBarTitle(Text(training.displayTitle), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack {
                Button(action: {
                    guard let logText = self.training.logText(weightUnit: self.settingsStore.weightUnit) else { return }
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
            AddExercisesSheet(onAdd: { selection in
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
            .environmentObject(mockSettingsStoreMetric)
            .environment(\.managedObjectContext, mockManagedObjectContext)
    }
}
#endif
