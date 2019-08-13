//
//  TrainingDetailView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Combine

private class TrainingViewModel: ObservableObject {
    let objectWillChange = PassthroughSubject<Void, Never>()
    private var cancellable: AnyCancellable?
    var training: Training
    
    var startInput: Date {
        set {
            precondition(training.end == nil || newValue <= training.end!)
            training.start = newValue
        }
        get {
            training.safeStart
        }
    }
    var endInput: Date {
        set {
            precondition(training.start == nil || newValue >= training.start!)
            training.end = newValue
        }
        get {
            training.safeEnd
        }
    }
    // we don't want to immediately write the title to core data
    var titleInput: String { willSet { self.objectWillChange.send() } }
    // instead when the user is done typing we adjust and set the title here
    func adjustAndSaveTitleInput() {
        titleInput = titleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        training.title = titleInput.isEmpty ? nil : titleInput
    }

    init(training: Training) {
        self.training = training
        titleInput = training.title ?? ""
        cancellable = training.objectWillChange.subscribe(objectWillChange)
    }
}

struct TrainingDetailView : View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var settingsStore: SettingsStore
    @ObservedObject private var trainingViewModel: TrainingViewModel

//    @Environment(\.editMode) var editMode
    @State private var showingExerciseSelectorSheet = false
    @State private var exerciseSelectorSelection: Set<Exercise> = Set()
    
    init(training: Training) {
        trainingViewModel = TrainingViewModel(training: training)
    }
    
    private var trainingExercises: [TrainingExercise] {
        trainingViewModel.training.trainingExercises?.array as? [TrainingExercise] ?? []
    }
    
    private func trainingExerciseText(trainingExercise: TrainingExercise) -> String {
        trainingExercise.trainingSets!
            .map { ($0 as! TrainingSet).displayTitle(unit: settingsStore.weightUnit) }
            .joined(separator: "\n")
    }
    
    var body: some View {
        List {
            Section {
                TrainingDetailBannerView(training: trainingViewModel.training)
                    .listRowBackground(trainingViewModel.training.muscleGroupColor)
                    .environment(\.colorScheme, .dark) // TODO: check whether accent color is actually dark
            }
            
            // editMode makes problems in beta5
//            if editMode?.value == .active {
                Section {
                    // TODO: add clear button
                    TextField("Title", text: $trainingViewModel.titleInput, onEditingChanged: { isEditingTextField in
                        if !isEditingTextField {
                            self.trainingViewModel.adjustAndSaveTitleInput()
                        }
                    })
                }
                
                Section {
                    DatePicker(selection: $trainingViewModel.startInput, in: ...min(self.trainingViewModel.training.safeEnd, Date())) {
                        Text("Start")
                    }

                    DatePicker(selection: $trainingViewModel.endInput, in: self.trainingViewModel.training.safeStart...Date()) {
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
                            Text(self.trainingExerciseText(trainingExercise: trainingExercise))
                                .font(Font.body.monospacedDigit())
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
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
                    guard var trainingExercises = self.trainingViewModel.training.trainingExercises?.array as? [TrainingExercise] else { return }
                    trainingExercises.move(fromOffsets: source, toOffset: destination)
                    self.trainingViewModel.training.trainingExercises = NSOrderedSet(array: trainingExercises)
                    self.managedObjectContext.safeSave()
                }
                
                Button(action: {
                    // TODO: add exercise
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
        .navigationBarTitle(Text(trainingViewModel.training.displayTitle), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack {
                Button(action: {
                    // TODO: share training
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                EditButton()
            }
        )
        .sheet(isPresented: $showingExerciseSelectorSheet) {
            VStack {
                HStack {
                    Button("Cancel") {
                        self.showingExerciseSelectorSheet = false
                        self.exerciseSelectorSelection.removeAll()
                    }
                    Spacer()
                    Button("Add") {
                        for exercise in self.exerciseSelectorSelection {
                            let trainingExercise = TrainingExercise(context: self.managedObjectContext)
                            self.trainingViewModel.training.addToTrainingExercises(trainingExercise)
                            trainingExercise.exerciseId = Int16(exercise.id)
                        }
                        self.showingExerciseSelectorSheet = false
                        self.exerciseSelectorSelection.removeAll()
                    }
                }.padding()
                ExerciseMultiSelectionView(exerciseMuscleGroups: EverkineticDataProvider.exercisesGrouped, selection: self.$exerciseSelectorSelection)
            }
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
