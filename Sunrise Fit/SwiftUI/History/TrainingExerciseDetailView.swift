//
//  TrainingExerciseDetailView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 23.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct TrainingExerciseDetailView : View {
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    let trainingExercise: TrainingExercise
    
    private func trainingSets(for trainingExercise: TrainingExercise) -> [TrainingSet] {
        trainingExercise.trainingSets?.array as! [TrainingSet]
    }
    
    private func indexedTrainingSets(for trainingExercise: TrainingExercise) -> [(Int, TrainingSet)] {
        trainingSets(for: trainingExercise).enumerated().map { ($0 + 1, $1) }
    }

    var body: some View {
        List {
            Section {
                TrainingExerciseDetailBannerView(trainingExercise: trainingExercise)
                    .frame(height: 100)
                    .listRowBackground(trainingExercise.muscleGroupColor)
                    .environment(\.colorScheme, .dark) // TODO: check whether accent color is actuall dark
            }

            Section {
                ForEach(indexedTrainingSets(for: trainingExercise).identified(by: \.1.objectID)) { (index, trainingSet) in
                    HStack {
                        Text(trainingSet.displayTitle)
                            .color(.primary)
                        Spacer()
                        Text("\(index)")
                            .color(.secondary)
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
                                .color(.secondary)
                            Spacer()
                            Text("\(index)")
                                .color(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .navigationBarTitle(Text(trainingExercise.exercise?.title ?? ""), displayMode: .inline)
        .navigationBarItems(trailing: EditButton())
    }
}


//private struct TrainingExerciseSection : View {
//    @Environment(\.isEnabled) var isEnabled
//    var trainingExercise: TrainingExercise
//
//
//
//    var body: some View {
//        ForEach(trainingSets(for: trainingExercise).enumerated().map { ($0 + 1, $1) }.identified(by: \.1.objectID)) { (index, trainingSet) in
//            HStack {
//                Text(trainingSet.displayTitle)
//                    .color(self.isEnabled ? .primary : .secondary)
//                Spacer()
//                Text(String(index))
//                    .color(.secondary)
//            }
//        }
//    }
//}

#if DEBUG
struct TrainingExerciseDetailView_Previews : PreviewProvider {
    static var previews: some View {
        let trainingExercise = TrainingExercise(context: mockTrainingsDataStore.context)
        trainingExercise.training = Training(context: mockTrainingsDataStore.context)
        return TrainingExerciseDetailView(trainingExercise: mockTrainingExercise).environmentObject(mockTrainingsDataStore)
    }
}
#endif
