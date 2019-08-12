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
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.editMode) var editMode
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var restTimerStore: RestTimerStore
    
    @ObservedObject var trainingExercise: TrainingExercise
    @ObservedObject var observableFetchRequest = ObservableFetchRequest<TrainingExercise>()

    @State private var selectedTrainingSet: TrainingSet? = nil
    
    private func fetchTrainingExerciseHistory() {
        observableFetchRequest.fetch(fetchRequest: trainingExercise.historyFetchRequest, managedObjectContext: managedObjectContext)
    }
    
    private var trainingExerciseHistory: [TrainingExercise] {
        observableFetchRequest.fetchedResults
    }

    private func trainingSets(for trainingExercise: TrainingExercise) -> [TrainingSet] {
        trainingExercise.trainingSets?.array as? [TrainingSet] ?? []
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
    
    private func select(set: TrainingSet?) {
        managedObjectContext.safeSave()
        withAnimation {
            if let set = set, !set.isCompleted && set.repetitions == 0 && set.weight == 0 { // treat as uninitialized
                initRepsAndWeight(for: set)
            }
            selectedTrainingSet = set
        }
    }
    
    private func initRepsAndWeight(for set: TrainingSet) {
        let index = trainingExercise.trainingSets!.index(of: set)
        let previousSet: TrainingSet?
        if index > 0 { // not the first set
            previousSet = trainingExercise.trainingSets![index - 1] as? TrainingSet
        } else { // first set
            previousSet = trainingExerciseHistory.first?.trainingSets?.firstObject as? TrainingSet
        }
        if let previousSet = previousSet {
            set.repetitions = previousSet.repetitions
            set.weight = previousSet.weight
        } else {
            // TODO: let the user configure default repetitions and weight
            set.repetitions = 5
            if trainingExercise.exercise?.isBarbellBased ?? false {
                let weightUnit = self.settingsStore.weightUnit
                set.weight = WeightUnit.convert(weight: weightUnit.barbellWeight, from: weightUnit, to: .metric)
            }
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
    
    private var banner: some View {
        TrainingExerciseDetailBannerView(trainingExercise: trainingExercise)
            .listRowBackground(trainingExercise.muscleGroupColor)
            .environment(\.colorScheme, .dark) // TODO: check whether accent color is actuall dark
    }
    
    private var currentTrainingSets: some View {
        ForEach(indexedTrainingSets(for: trainingExercise), id: \.1.objectID) { (index, trainingSet) in
            HStack {
                //                            Text((trainingSet as TrainingSet).isCompleted || (trainingSet as TrainingSet) == self.firstUncompletedSet ? (trainingSet as TrainingSet).displayTitle(unit: settingsStore.weightUnit) : "Set \(index)")
                Text(self.shouldShowTitle(for: trainingSet) ? trainingSet.displayTitle(unit: self.settingsStore.weightUnit) : "Set \(index)")
                    .font(Font.body.monospacedDigit())
                    .foregroundColor(self.shouldHighlightRow(for: trainingSet) ? .primary : .secondary)
                Spacer()
                Text("\(index)")
                    .font(Font.body.monospacedDigit())
                    .foregroundColor(.secondary)
            }
                // TODO: use selection feature of List when it is released
                .listRowBackground(self.selectedTrainingSet == (trainingSet as TrainingSet) && self.editMode?.value != .active ? Color(UIColor.systemGray4) : nil) // TODO: trainingSet cast shouldn't be necessary
                .onTapGesture { // TODO: currently tap on Spacer() is not recognized
                    guard self.editMode?.value != .active else { return }
                    if self.selectedTrainingSet == trainingSet {
                        self.select(set: nil)
                    } else if trainingSet.isCompleted || trainingSet == self.firstUncompletedSet {
                        self.select(set: trainingSet)
                    }
            }
        }
        .onDelete { offsets in
            for i in offsets.sorted().reversed() {
                guard let trainingSet = self.trainingExercise.trainingSets?[i] as? TrainingSet else { return }
                self.managedObjectContext.delete(trainingSet)
            }
            if self.selectedTrainingSet != nil && !(self.trainingExercise.trainingSets?.contains(self.selectedTrainingSet!) ?? false) {
                self.select(set: self.firstUncompletedSet)
            }
        }
        // TODO: move is yet too buggy
        //                        .onMove { source, destination in
        //                            guard source.first != destination || source.count > 1 else { return }
        //                            // make sure the destination is completed
        //                            guard (self.trainingExercise.trainingSets![destination] as! TrainingSet).isCompleted else { return }
        //                            // make sure all sources are completed
        //                            guard source.reduce(true, { (allCompleted, index) in
        //                                allCompleted && (self.trainingExercise.trainingSets![index] as! TrainingSet).isCompleted
        //                            }) else { return }
        //
        //                            // TODO: replace with swift 5.1 move() function when available
        //                            guard let index = source.first else { return }
        //                            guard let trainingSet = self.trainingExercise.trainingSets?[index] as? TrainingSet else { return }
        //                            self.trainingExercise.removeFromTrainingSets(at: index)
        //                            self.trainingExercise.insertIntoTrainingSets(trainingSet, at: destination)
        //                        }
    }
    
    private var addSetButton: some View {
        Button(action: {
            let trainingSet = TrainingSet(context: self.trainingExercise.managedObjectContext!)
            self.trainingExercise.addToTrainingSets(trainingSet)
            self.select(set: self.firstUncompletedSet)
            if !self.isCurrentTraining {
                // don't allow uncompleted sets if not in current training
                trainingSet.isCompleted = true
            }
        }) {
            HStack {
                Image(systemName: "plus")
                Text("Add Set")
            }
        }
    }
    
    private var historyTrainingSets: some View {
        ForEach(trainingExerciseHistory, id: \.objectID) { trainingExercise in
            Section(header: Text(Training.dateFormatter.string(from: trainingExercise.training!.start!))) {
                ForEach(self.indexedTrainingSets(for: trainingExercise), id: \.1.objectID) { (index, trainingSet) in
                    HStack {
                        Text(trainingSet.displayTitle(unit: self.settingsStore.weightUnit))
                            .font(Font.body.monospacedDigit())
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(index)")
                            .font(Font.body.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var trainingSetEditor: some View {
        VStack(spacing: 0) {
            Divider()
            TrainingSetEditor(trainingSet: self.selectedTrainingSet!, weightUnit: self.settingsStore.weightUnit, onDone: {
                guard let set = self.selectedTrainingSet else { return }
                
                if !set.isCompleted {
                    // these preconditions should never ever happen, but just to be sure
                    precondition(set.weight >= 0, "Tried to complete set with negative weight.")
                    precondition(set.repetitions >= 0, "Tried to complete set with negative repetitions.")
                    set.isCompleted = true
                    let training = set.trainingExercise!.training!
                    training.start = training.start ?? Date()
                    self.moveTrainingExerciseBehindLastBegun()
                    
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.prepare()
                    feedbackGenerator.notificationOccurred(.success)
                }
                self.select(set: self.firstUncompletedSet) // also saves the context
                
                if self.isCurrentTraining {
                    // start rest timer
                    // TODO: customizable rest timer time
                    self.restTimerStore.restTimerEnd = Date().addingTimeInterval(90)
                }
            })
                // TODO: currently the gesture doesn't work very well when a background is set (must be SwiftUI bug)
                .background(VisualEffectView(effect: UIBlurEffect(style: .systemMaterial)))
        }
        .transition(AnyTransition.move(edge: .bottom))
    }

    var body: some View {
        fetchTrainingExerciseHistory() // TODO: should be in onAppear, but as of beta5 this crashes
        return VStack(spacing: 0) {
            List {
                Section {
                    banner
                }
                
                Section {
                    currentTrainingSets
                    addSetButton
                }
                
                historyTrainingSets
            }
            .listStyle(GroupedListStyle())
            
            if selectedTrainingSet != nil &&
                (self.trainingExercise.trainingSets?.contains(self.selectedTrainingSet!) ?? false) &&
                editMode?.value != .active {
                trainingSetEditor
            } // TODO: else if trainingExercise is finished, show next exercise / finish training button
        }
        .navigationBarTitle(Text(trainingExercise.exercise?.title ?? ""), displayMode: .inline)
        .navigationBarItems(trailing: HStack{
            NavigationLink(destination: ExerciseDetailView(exercise: trainingExercise.exercise ?? Exercise.empty)
                .environmentObject(self.settingsStore)) {
                    Image(systemName: "info.circle")
            }
            EditButton()
        })
        .onAppear {
            self.select(set: self.firstUncompletedSet)
        }
    }
}

#if DEBUG
struct TrainingExerciseDetailView_Previews : PreviewProvider {
    static var previews: some View {
        NavigationView {
        TrainingExerciseDetailView(trainingExercise: mockTrainingExercise)
            .environmentObject(mockSettingsStoreMetric)
            .environment(\.managedObjectContext, mockManagedObjectContext)
        }
    }
}
#endif
