//
//  TrainingDetailView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Combine

private class TrainingViewModel: BindableObject {
    var willChange = PassthroughSubject<Void, Never>()

    var training: Training
    var startInput: Date {
        set {
            precondition(newValue <= training.end!)
            training.start = newValue
        }
        get {
            training.start!
        }
    }
    var endInput: Date {
        set {
            precondition(newValue >= training.start!)
            training.end = newValue
        }
        get {
            training.end!
        }
    }
    // we don't want to immediately write the title to core data
    var titleInput: String { willSet { willChange.send() } }
    // instead when the user is done typing we adjust and set the title here
    func adjustAndSaveTitleInput() {
        titleInput = titleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        training.title = titleInput.isEmpty ? nil : titleInput
    }

    init(training: Training) {
        self.training = training
        titleInput = training.title ?? ""
    }
}

struct TrainingDetailView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    @ObjectBinding private var trainingViewModel: TrainingViewModel
    
//    @Environment(\.editMode) var editMode
    
    init(training: Training) {
        trainingViewModel = TrainingViewModel(training: training)
    }
    
    private var trainingExercises: [TrainingExercise] {
        trainingViewModel.training.trainingExercises?.array as! [TrainingExercise]
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
                    .environment(\.colorScheme, .dark) // TODO: check whether accent color is actuall dark
            }
            
            // editMode makes problems in beta2
//            if editMode?.value == .active {
                Section {
                    // onCommit() does not seem to be called in beta2
//                    TextField($trainingTitle, placeholder: Text("Title")) {
//                        print("set \(self.trainingTitle) as title")
//                    }
                    // TODO: add clear button
                    TextField("Title", text: $trainingViewModel.titleInput, onEditingChanged: { isEditingTextField in
                        if !isEditingTextField {
                            self.trainingViewModel.adjustAndSaveTitleInput()
                        }
                    })
                }
                
                Section {
                    DatePicker(selection: $trainingViewModel.startInput, in: ...min(self.trainingViewModel.training.end!, Date())) {
                        Text("Start")
                    }

                    DatePicker(selection: $trainingViewModel.endInput, in: self.trainingViewModel.training.start!...Date()) {
                        Text("End")
                    }
                }
//            }
            
            
            Section {
                ForEach(trainingExercises, id: \.objectID) { trainingExercise in
                    // TODO: navigation button -> Set Editor
                    NavigationLink(destination: TrainingExerciseDetailView(trainingExercise: trainingExercise)
                        .environmentObject(self.trainingsDataStore)
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
                    self.trainingViewModel.training.removeFromTrainingExercises(at: offsets as NSIndexSet)
                }
                .onMove { source, destination in
                    guard var trainingExercises = self.trainingViewModel.training.trainingExercises?.array as! [TrainingExercise]? else { return }
                    trainingExercises.move(fromOffsets: source, toOffset: destination)
                    self.trainingViewModel.training.trainingExercises = NSOrderedSet(array: trainingExercises)
                }
                
                Button(action: {
                    // TODO: add exercise
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Exercise")
                    }
                }
            }
        }
        .listStyle(.grouped)
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
    }
}

#if DEBUG
struct TrainingDetailView_Previews : PreviewProvider {
    static var previews: some View {
        return TrainingDetailView(training: mockTraining)
            .environmentObject(mockTrainingsDataStore)
            .environmentObject(mockSettingsStoreMetric)
    }
}
#endif
