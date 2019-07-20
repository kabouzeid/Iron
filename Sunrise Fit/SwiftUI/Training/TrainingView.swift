//
//  TrainingView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct TrainingView: View {
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    
    var trainig: Training
    
    @State var showingCancelSheet = false
    
    private var trainingExercises: [TrainingExercise] {
        trainig.trainingExercises?.array as! [TrainingExercise]? ?? []
    }
    
    private func trainingExerciseCell(trainingExercise: TrainingExercise) -> some View {
        let completedSets = trainingExercise.numberOfCompletedSets!
        let totalSets = trainingExercise.trainingSets!.count
        let done = completedSets == totalSets
        
        return HStack {
            VStack(alignment: .leading) {
                Text(trainingExercise.exercise?.title ?? "Unknown Exercise (\(trainingExercise.exerciseId))")
                    .foregroundColor(done ? .secondary : .primary)
                Text("\(completedSets) of \(totalSets)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if done {
                Spacer()
                Image(systemName: "checkmark")
                    .imageScale(.small)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Rectangle().frame(height: 48).foregroundColor(.accentColor) // Placeholder for timer
                List {
                    Section {
                        ForEach(trainingExercises, id: \.objectID) { trainingExercise in
                            self.trainingExerciseCell(trainingExercise: trainingExercise)
                        }
                        .onDelete { offsets in
                            self.trainig.removeFromTrainingExercises(at: offsets as NSIndexSet)
                        }
                        .onMove { source, destination in
                            var trainingExercises = self.trainingExercises
                            trainingExercises.move(fromOffsets: source, toOffset: destination)
                            self.trainig.trainingExercises = NSOrderedSet(array: trainingExercises)
                        }
                        
                        Button(action: {
                            self.trainig.addToTrainingExercises(TrainingExercise(context: self.trainingsDataStore.context))
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Exercise")
                            }
                        }
                    }
                }
                .listStyle(.grouped)
            }
            .navigationBarTitle(Text(trainig.displayTitle), displayMode: .inline)
            .navigationBarItems(
                leading:
                Button("Cancel") {
                    self.showingCancelSheet = true
                }
                .actionSheet(isPresented: $showingCancelSheet, content: {
                    ActionSheet(title: Text("This cannot be undone."), message: nil, buttons: [
                        .destructive(Text("Delete Training"), onTrigger: {
                            self.trainingsDataStore.context.delete(self.trainig)
                        }),
                        .cancel()
                    ])
                })
                ,
                trailing:
                EditButton()
            )
        }
    }
}

#if DEBUG
struct TrainingView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingView(trainig: mockTraining)
            .environmentObject(mockTrainingsDataStore)
    }
}
#endif
