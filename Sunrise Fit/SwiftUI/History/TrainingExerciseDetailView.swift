//
//  TrainingExerciseDetailView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 23.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData

struct TrainingExerciseDetailView : View {
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    let trainingExercise: TrainingExercise
    
    private func trainingSets(for trainingExercise: TrainingExercise) -> [TrainingSet] {
        trainingExercise.trainingSets?.array as! [TrainingSet]
    }
    
    private func indexedTrainingSets(for trainingExercise: TrainingExercise) -> [(Int, TrainingSet)] {
        trainingSets(for: trainingExercise).enumerated().map { ($0 + 1, $1) }
    }
    
    @State private var showTrainingSetEditor = true
    @State private var selectedTrainingSet: TrainingSet? = nil

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    TrainingExerciseDetailBannerView(trainingExercise: trainingExercise)
                        .listRowBackground(trainingExercise.muscleGroupColor)
                        .environment(\.colorScheme, .dark) // TODO: check whether accent color is actuall dark
                }
                
                Section {
                    ForEach(indexedTrainingSets(for: trainingExercise).identified(by: \.1.objectID)) { (index, trainingSet) in
                        HStack {
                            Text(trainingSet.displayTitle)
                                .font(Font.body.monospacedDigit())
                                .color(.primary) // TODO: better make cell appear selected (grey cell bg)
                            Spacer()
                            Text("\(index)")
                                .font(Font.body.monospacedDigit())
                                .color(.secondary)
                        }
                            // TODO: use selection feature of List when it is released
                            .listRowBackground(self.selectedTrainingSet?.objectID == (trainingSet as TrainingSet).objectID ? UIColor.systemGray4.swiftUIColor : nil) // TODO: trainingSet cast shouldn't be necessary
                            .tapAction { // TODO: currently tap on Spacer() is not recognized
                                withAnimation {
                                    self.selectedTrainingSet = trainingSet
                                }
                            }
                    }
                        .onDelete { offsets in
                            //                    self.trainingViewModel.training.removeFromTrainingExercises(at: offsets as NSIndexSet)
                            self.trainingExercise.removeFromTrainingSets(at: offsets as NSIndexSet)
                        }
                        .onMove { source, destination in
                            // TODO: replace with swift 5.1 move() function when available
                            guard let index = source.first else { return }
                            guard let trainingSet = self.trainingExercise.trainingSets?[index] as? TrainingSet else { return }
                            self.trainingExercise.removeFromTrainingSets(at: index)
                            self.trainingExercise.insertIntoTrainingSets(trainingSet, at: destination)
                        }
                    Button(action: {
                        // TODO: add set
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Set")
                        }
                    }
                }
                
                ForEach((trainingExercise.history ?? []).identified(by: \.objectID)) { trainingExercise in
                    Section {
                        ForEach(self.indexedTrainingSets(for: trainingExercise).identified(by: \.1.objectID)) { (index, trainingSet) in
                            HStack {
                                Text(trainingSet.displayTitle)
                                    .font(Font.body.monospacedDigit())
                                    .color(.secondary)
                                Spacer()
                                Text("\(index)")
                                    .font(Font.body.monospacedDigit())
                                    .color(.secondary)
                            }
                        }
                    }
                }
            }
                .listStyle(.grouped)
            if selectedTrainingSet != nil {
                VStack(spacing: 0) {
                    Divider()
                    TrainingSetEditor(trainingSet: self.selectedTrainingSet!, onComment: {
                        // TODO
                    }, onComplete: {
                        // TODO
                    })
                        // TODO: currently the gesture doesn't work when a background is set
//                        .background(VisualEffectView(effect: UIBlurEffect(style: .systemMaterial)))
                }
                    .transition(AnyTransition.move(edge: .bottom))
            }
        }
            .navigationBarTitle(Text(trainingExercise.exercise?.title ?? ""), displayMode: .inline)
            .navigationBarItems(trailing: EditButton())
    }
}

#if DEBUG
struct TrainingExerciseDetailView_Previews : PreviewProvider {
    static var previews: some View {
        return TrainingExerciseDetailView(trainingExercise: mockTrainingExercise).environmentObject(mockTrainingsDataStore)
    }
}
#endif
