//
//  ExerciseHistoryView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 06.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ExerciseHistoryView : View {
    var exercise: Exercise
    
    var history: [TrainingExercise] {
        TrainingExercise.fetchHistory(of: exercise.id, until: Date(), context: AppDelegate.instance.persistentContainer.viewContext) ?? []
    }
    
    private func trainingSets(for trainingExercise: TrainingExercise) -> [TrainingSet] {
        trainingExercise.trainingSets?.array as! [TrainingSet]
    }
    
    private func indexedTrainingSets(for trainingExercise: TrainingExercise) -> [(Int, TrainingSet)] {
        trainingSets(for: trainingExercise).enumerated().map { ($0 + 1, $1) }
    }
    
    var body: some View {
        List {
            ForEach(history.identified(by: \.objectID)) { trainingExercise in
                Section(header: Text(Training.dateFormatter.string(from: trainingExercise.training!.start!))) {
                    ForEach(self.indexedTrainingSets(for: trainingExercise).identified(by: \.1.objectID)) { index, trainingSet in
                        HStack {
                            Text(trainingSet.displayTitle)
                                .font(Font.body.monospacedDigit())
                                .color(.primary)
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
    }
}

#if DEBUG
struct ExerciseHistoryView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseHistoryView(exercise: EverkineticDataProvider.findExercise(id: 42)!)
    }
}
#endif
