//
//  ExerciseHistoryView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 06.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ExerciseHistoryView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    
    var exercise: Exercise
    
    var history: [TrainingExercise] {
        TrainingExercise.fetchHistory(of: exercise.id, until: Date(), context: trainingsDataStore.context) ?? []
    }
    
    private func trainingSets(for trainingExercise: TrainingExercise) -> [TrainingSet] {
        trainingExercise.trainingSets?.array as! [TrainingSet]
    }
    
    private func indexedTrainingSets(for trainingExercise: TrainingExercise) -> [(Int, TrainingSet)] {
        trainingSets(for: trainingExercise).enumerated().map { ($0 + 1, $1) }
    }
    
    var body: some View {
        List {
            ForEach(history, id: \.objectID) { trainingExercise in
                Section(header: Text(Training.dateFormatter.string(from: trainingExercise.training!.start!))) {
                    ForEach(self.indexedTrainingSets(for: trainingExercise), id: \.1.objectID) { index, trainingSet in
                        HStack {
                            Text(trainingSet.displayTitle(unit: self.settingsStore.weightUnit))
                                .font(Font.body.monospacedDigit())
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(index)")
                                .font(Font.body.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
    }
}

#if DEBUG
struct ExerciseHistoryView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseHistoryView(exercise: EverkineticDataProvider.findExercise(id: 42)!)
            .environmentObject(mockTrainingsDataStore)
            .environmentObject(mockSettingsStoreMetric)
    }
}
#endif
