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
    var didChange = PassthroughSubject<Void, Never>()

    var training: Training
    var startInput: Date {
        didSet {
            assert(startInput <= training.end!)
            training.start = startInput
            didChange.send()
        }
    }
    var endInput: Date {
        didSet {
            assert(endInput >= training.start!)
            training.end = endInput
            didChange.send()
        }
    }
    // we don't want to immediately write the title to core data
    var titleInput: String { didSet { didChange.send() } }
    // instead when the user is done typing we adjust and set the title here
    func adjustAndSaveTitleInput() {
        titleInput = titleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        training.title = titleInput.isEmpty ? nil : titleInput
    }

    init(training: Training) {
        self.training = training
        // set the default values
        startInput = training.start!
        endInput = training.end!
        titleInput = training.title ?? ""
    }
}

struct TrainingDetailView : View {
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
            .map { ($0 as! TrainingSet).displayTitle }
            .joined(separator: "\n")
    }
    
    var body: some View {
        List {
            Section {
                TrainingDetailBannerView(training: trainingViewModel.training)
                    .frame(height: 100)
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
                    TextField($trainingViewModel.titleInput, placeholder: Text("Title"), onEditingChanged: { isEditingTextField in
                        if !isEditingTextField {
                            self.trainingViewModel.adjustAndSaveTitleInput()
                        }
                    })
                }
                
                Section {
                    DatePicker($trainingViewModel.startInput, maximumDate: min(self.trainingViewModel.training.end!, Date())) {
                        Text("Start")
                    }

                    DatePicker($trainingViewModel.endInput, minimumDate: self.trainingViewModel.training.start!, maximumDate: Date()) {
                        Text("End")
                    }
                }
//            }
            
            
            Section {
                ForEach(trainingExercises.identified(by: \.objectID)) { trainingExercise in
                    // TODO: navigation button -> Set Editor
                    NavigationButton(destination: TrainingExerciseDetailView(trainingExercise: trainingExercise)) {
                        VStack(alignment: .leading) {
                            Text(trainingExercise.exercise?.title ?? "")
                                .font(.body)
                            Text(self.trainingExerciseText(trainingExercise: trainingExercise))
                                .font(.body)
                                .color(.secondary)
                                .lineLimit(nil)
                        }
                    }
                }
                .onDelete { offsets in
                        self.trainingViewModel.training.removeFromTrainingExercises(at: offsets as NSIndexSet)
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
        return TrainingDetailView(training: mockTraining).environmentObject(mockTrainingsDataStore)
    }
}
#endif
