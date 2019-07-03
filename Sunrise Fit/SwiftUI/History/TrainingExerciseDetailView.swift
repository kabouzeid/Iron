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
    @Environment(\.editMode) var editMode
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    let trainingExercise: TrainingExercise
    
    @State private var selectedTrainingSet: TrainingSet? = nil
    
    private func trainingSets(for trainingExercise: TrainingExercise) -> [TrainingSet] {
        trainingExercise.trainingSets?.array as! [TrainingSet]
    }
    
    private func indexedTrainingSets(for trainingExercise: TrainingExercise) -> [(Int, TrainingSet)] {
        trainingSets(for: trainingExercise).enumerated().map { ($0 + 1, $1) }
    }
    
    private var isCurrentTraining: Bool {
        trainingExercise.training?.isCurrentTraining ?? false
    }

    private var firstUncompletedSet: TrainingSet? {
        trainingExercise.trainingSets?.first(where: { !($0 as! TrainingSet).isCompleted }) as? TrainingSet
    }
    
    private func selectAndInit(set: TrainingSet?) {
        if set?.repetitions == 0 { // uninitialized
            initRepsAndWeight(for: set!)
        }
        selectedTrainingSet = set
    }
    
    private func initRepsAndWeight(for set: TrainingSet) {
        let index = trainingExercise.trainingSets!.index(of: set)
        let previousSet: TrainingSet?
        if index > 0 { // not the first set
            previousSet = trainingExercise.trainingSets![index - 1] as? TrainingSet
        } else { // first set
            previousSet = (trainingExercise.history ?? []).first?.trainingSets?.firstObject as? TrainingSet
        }
        if let previousSet = previousSet {
            set.repetitions = previousSet.repetitions
            set.weight = previousSet.weight
        } else {
            set.repetitions = 1
        }
    }
    
    private func moveTrainingExerciseBehindLastBegun() {
        assert(isCurrentTraining)
        let training = trainingExercise.training!
        training.removeFromTrainingExercises(trainingExercise) // remove before doing the other stuff!
        if let firstUntouched = training.trainingExercises?.array.last(
            where: { (($0 as! TrainingExercise).numberOfCompletedSets ?? 0) == 0 }) as? TrainingExercise {
            let index = training.trainingExercises!.index(of: firstUntouched)
            assert(index != NSNotFound)
            training.insertIntoTrainingExercises(trainingExercise, at: index)
        } else {
            training.addToTrainingExercises(trainingExercise) // append at the end
        }
    }
    
    private func shouldShowTitle(for set: TrainingSet) -> Bool {
        set.isCompleted || set == self.firstUncompletedSet
    }
    
    private func shouldHighlightRow(for set: TrainingSet) -> Bool {
        !self.isCurrentTraining || set == self.firstUncompletedSet
    }

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
//                            Text((trainingSet as TrainingSet).isCompleted || (trainingSet as TrainingSet) == self.firstUncompletedSet ? (trainingSet as TrainingSet).displayTitle : "Set \(index)")
                            Text(self.shouldShowTitle(for: trainingSet) ? trainingSet.displayTitle : "Set \(index)")
                                .font(Font.body.monospacedDigit())
                                .color(self.shouldHighlightRow(for: trainingSet) ? .primary : .secondary)
                            Spacer()
                            Text("\(index)")
                                .font(Font.body.monospacedDigit())
                                .color(.secondary)
                        }
                            // TODO: use selection feature of List when it is released
                            .listRowBackground(self.selectedTrainingSet == (trainingSet as TrainingSet) && self.editMode?.value != .active ? UIColor.systemGray4.swiftUIColor : nil) // TODO: trainingSet cast shouldn't be necessary
                            .tapAction { // TODO: currently tap on Spacer() is not recognized
                                withAnimation {
                                    if self.selectedTrainingSet == trainingSet {
                                        self.selectAndInit(set: nil)
                                    } else if trainingSet.isCompleted || trainingSet == self.firstUncompletedSet {
                                        self.selectAndInit(set: trainingSet)
                                    }
                                }
                            }
                    }
                        .onDelete { offsets in
                            //                    self.trainingViewModel.training.removeFromTrainingExercises(at: offsets as NSIndexSet)
                            self.trainingExercise.removeFromTrainingSets(at: offsets as NSIndexSet)
                            if self.selectedTrainingSet != nil && !(self.trainingExercise.trainingSets?.contains(self.selectedTrainingSet!) ?? false) {
                                self.selectAndInit(set: self.firstUncompletedSet)
                            }
                        }
                        .onMove { source, destination in
                            // TODO: replace with swift 5.1 move() function when available
                            guard let index = source.first else { return }
                            guard let trainingSet = self.trainingExercise.trainingSets?[index] as? TrainingSet else { return }
                            self.trainingExercise.removeFromTrainingSets(at: index)
                            self.trainingExercise.insertIntoTrainingSets(trainingSet, at: destination)
                        }
                    Button(action: {
                        let trainingSet = TrainingSet(context: self.trainingExercise.managedObjectContext!)
                        self.trainingExercise.addToTrainingSets(trainingSet)
                        self.selectAndInit(set: self.firstUncompletedSet)
                        if !self.isCurrentTraining {
                            // don't allow uncompleted sets if not in current training
                            precondition(trainingSet.repetitions > 0, "Tried to complete set with 0 repetitions.")
                            trainingSet.isCompleted = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Set")
                        }
                    }
                }
                
                ForEach((trainingExercise.history ?? []).identified(by: \.objectID)) { trainingExercise in
                    Section(header: Text(Training.dateFormatter.string(from: trainingExercise.training!.start!))) {
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
            if selectedTrainingSet != nil && (self.trainingExercise.trainingSets?.contains(self.selectedTrainingSet!) ?? false) && editMode?.value != .active {
                VStack(spacing: 0) {
                    Divider()
                    TrainingSetEditor(trainingSet: self.selectedTrainingSet!, onComment: {
                        // TODO
                    }, onComplete: {
                        guard let set = self.selectedTrainingSet else { return }
                            
                        if !set.isCompleted {
                            precondition(set.repetitions > 0, "Tried to complete set with 0 repetitions.")
                            set.isCompleted = true
                            let training = set.trainingExercise!.training!
                            training.start = training.start ?? Date()
                            self.moveTrainingExerciseBehindLastBegun()
                            // we don't want to lose any sets the user has done when something crashes
                            // TODO: save the context here
                            let feedbackGenerator = UINotificationFeedbackGenerator()
                            feedbackGenerator.prepare()
                            feedbackGenerator.notificationOccurred(.success)
                        }
                        self.selectAndInit(set: self.firstUncompletedSet)
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
