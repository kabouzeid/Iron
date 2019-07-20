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
    
    @State private var showingCancelSheet = false
    @State private var showingExercisePickerSheet = false
    
    private var trainingExercises: [TrainingExercise] {
        trainig.trainingExercises?.array as! [TrainingExercise]? ?? []
    }
    
    private func createDefaultTrainingSets(trainingExercise: TrainingExercise) -> NSOrderedSet {
        var numberOfSets = 3
        // try to guess the number of sets
        if let history = trainingExercise.history, history.count > 2 {
            // one month since last training and at least three trainings
            let cutoff = min(history[2].training!.start!, Calendar.current.date(byAdding: .month, value: -1, to: history.first!.training!.start!)!)
            let filteredAndSortedHistory = history
                .filter({$0.training!.start != nil && $0.training!.start! >= cutoff})
                .sorted(by: {($0.trainingSets?.count ?? 0) < ($1.trainingSets?.count ?? 0)})
            assert(filteredAndSortedHistory.count >= 3)
            let median = filteredAndSortedHistory[filteredAndSortedHistory.count / 2]
            numberOfSets = median.trainingSets?.count ?? numberOfSets
        }
        var trainingSets = [TrainingSet]()
        for _ in 0..<numberOfSets {
            let trainingSet = TrainingSet(context: trainingsDataStore.context)
            trainingSets.append(trainingSet)
        }
        return NSOrderedSet(array: trainingSets)
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
                            self.showingExercisePickerSheet = true
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
            .sheet(isPresented: $showingExercisePickerSheet) {
                ExerciseMultiSelectionView(exerciseMuscleGroups: EverkineticDataProvider.exercisesGrouped, selectionLabel: Text("Add")) { selection in
                    for exercise in selection {
                        let trainingExercise = TrainingExercise(context: self.trainingsDataStore.context)
                        self.trainig.addToTrainingExercises(trainingExercise)
                        trainingExercise.exerciseId = Int16(exercise.id)
                        trainingExercise.addToTrainingSets(self.createDefaultTrainingSets(trainingExercise: trainingExercise))
                    }
                    self.showingExercisePickerSheet = false
                }
            }
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
