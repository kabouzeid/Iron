//
//  ExerciseHistoryView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 06.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData

struct ExerciseHistoryView : View {
    @FetchRequest(fetchRequest: TrainingExercise.fetchRequest()) var history // will be overwritten in init()

    var exercise: Exercise
    
    init(exercise: Exercise) {
        self.exercise = exercise
        _history = FetchRequest(fetchRequest: TrainingExercise.historyFetchRequest(of: exercise.id, until: nil))
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
                Section(header: Text(Training.dateFormatter.string(from: trainingExercise.training?.start, fallback: "Unknown date"))) {
                    ForEach(self.indexedTrainingSets(for: trainingExercise), id: \.1.objectID) { index, trainingSet in
                        TrainingSetCell(trainingSet: trainingSet, index: index, colorMode: .activated)
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}

#if DEBUG
struct ExerciseHistoryView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseHistoryView(exercise: ExerciseStore.shared.find(with: 42)!)
            .environmentObject(SettingsStore.mockMetric)
            .environment(\.managedObjectContext, mockManagedObjectContext)
    }
}
#endif
