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
    var trainingExercise: TrainingExercise

    var body: some View {
        List {
            Section {
                TrainingExerciseSection(trainingExercise: trainingExercise)
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
                    TrainingExerciseSection(trainingExercise: trainingExercise)
                }
                .disabled(true)
            }
        }
        .listStyle(.grouped)
    }
}


private struct TrainingExerciseSection : View {
    @Environment(\.isEnabled) var isEnabled
    var trainingExercise: TrainingExercise
    
    private func trainingSets(for trainingExercise: TrainingExercise) -> [TrainingSet] {
        trainingExercise.trainingSets?.array as! [TrainingSet]
    }
    
    var body: some View {
        ForEach(trainingSets(for: trainingExercise).enumerated().map { ($0 + 1, $1) }.identified(by: \.1.objectID)) { (index, trainingSet) in
            HStack {
                Text(trainingSet.displayTitle)
                    .color(self.isEnabled ? .primary : .secondary)
                Spacer()
                Text(String(index))
                    .color(.secondary)
            }
        }
    }
}

#if DEBUG
struct TrainingExerciseDetailView_Previews : PreviewProvider {
    static var previews: some View {
        let trainingExercise = TrainingExercise(context: mockTrainingsDataStore.context)
        trainingExercise.training = Training(context: mockTrainingsDataStore.context)
        return TrainingExerciseDetailView(trainingExercise: mockTraining.trainingExercises!.firstObject as! TrainingExercise).environmentObject(mockTrainingsDataStore)
    }
}
#endif
