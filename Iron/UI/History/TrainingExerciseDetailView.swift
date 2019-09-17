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
    
    @FetchRequest(fetchRequest: TrainingExercise.fetchRequest()) var trainingExerciseHistory // will be overwritten in init()
    @ObservedObject var trainingExercise: TrainingExercise

    @State private var selectedTrainingSet: TrainingSet? = nil
    
    init(trainingExercise: TrainingExercise) {
        self.trainingExercise = trainingExercise
        _trainingExerciseHistory = FetchRequest(fetchRequest: trainingExercise.historyFetchRequest)
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
        guard let training = trainingExercise.training else { return }
        
        training.removeFromTrainingExercises(trainingExercise) // remove before doing the other stuff!
        
        let lastBegun = training.trainingExercises?
            .compactMap { $0 as? TrainingExercise }
            .last { $0.numberOfCompletedSets ?? 0 > 0 }
        
        if let lastBegun = lastBegun, let index = training.trainingExercises?.index(of: lastBegun), index != NSNotFound {
            training.insertIntoTrainingExercises(trainingExercise, at: index + 1) // insert after last begun exercise
        } else {
            training.insertIntoTrainingExercises(trainingExercise, at: 0) // no training exercise begun
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
            .environment(\.colorScheme, .dark) // TODO: check whether accent color is actually dark
    }
    
    private func rpe(rpe: Double) -> some View {
        VStack {
            Group {
                Text(String(format: "%.1f", rpe))
                Text("RPE")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private var currentTrainingSets: some View {
        ForEach(indexedTrainingSets(for: trainingExercise), id: \.1.objectID) { (index, trainingSet) in
            TrainingSetCell(trainingSet: trainingSet, index: index, colorMode: self.shouldHighlightRow(for: trainingSet) ? .activated : .deactivated, textMode: self.shouldShowTitle(for: trainingSet) ? .weightAndReps : .placeholder)
                .listRowBackground(self.selectedTrainingSet == trainingSet && self.editMode?.wrappedValue != .active ? Color(UIColor.systemGray4) : nil)
                .background(Color.fakeClear) // hack that allows tap gesture to work (13.1 beta2)
                .onTapGesture {
                    guard self.editMode?.wrappedValue != .active else { return }
                    if self.selectedTrainingSet?.hasChanges ?? false {
                        self.managedObjectContext.safeSave()
                    }
                    if self.selectedTrainingSet == trainingSet {
                        self.select(set: nil)
                    } else if trainingSet.isCompleted || trainingSet == self.firstUncompletedSet {
                        self.select(set: trainingSet)
                    }
                }
        }
        .onDelete { offsets in
            var deletedSelectedSet = false
            let trainingSets = self.trainingSets(for: self.trainingExercise)
            for i in offsets {
                let trainingSet = trainingSets[i]
                self.managedObjectContext.delete(trainingSet)
                trainingSet.trainingExercise?.removeFromTrainingSets(trainingSet)
                
                if trainingSet == self.selectedTrainingSet {
                    deletedSelectedSet = true
                }
            }
            if deletedSelectedSet {
                self.select(set: self.firstUncompletedSet)
            }
            self.managedObjectContext.safeSave()
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
            self.managedObjectContext.safeSave()
        }) {
            HStack {
                Image(systemName: "plus")
                Text("Add Set")
            }
        }
    }
    
    private var historyTrainingSets: some View {
        ForEach(trainingExerciseHistory, id: \.objectID) { trainingExercise in
            Section(header: Text(Training.dateFormatter.string(from: trainingExercise.training?.start, fallback: "Unknown date"))) {
                ForEach(self.indexedTrainingSets(for: trainingExercise), id: \.1.objectID) { (index, trainingSet) in
                    TrainingSetCell(trainingSet: trainingSet, index: index, colorMode: .disabled)
                }
            }
        }
    }
    
    private var restTimerDuration: TimeInterval {
        // TODO: allow customizable default rest timer for each exercise
        if trainingExercise.exercise?.isBarbellBased ?? false {
            return settingsStore.defaultRestTimeBarbellBased
        } else {
            return settingsStore.defaultRestTime
        }
    }
    
    private var trainingSetEditor: some View {
        VStack(spacing: 0) {
            Divider()
            TrainingSetEditor(trainingSet: self.selectedTrainingSet!, onDone: {
                guard let set = self.selectedTrainingSet else { return }
                
                if !set.isCompleted {
                     assert(self.isCurrentTraining)
                    // these preconditions should never ever happen, but just to be sure
                    precondition(set.weight >= 0)
                    precondition(set.repetitions >= 0)
                    set.isCompleted = true
                    let training = set.trainingExercise!.training!
                    training.start = training.start ?? Date()
                    self.moveTrainingExerciseBehindLastBegun()
                    
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.prepare()
                    feedbackGenerator.notificationOccurred(.success)
                    
                    self.restTimerStore.restTimerDuration = self.restTimerDuration
                    self.restTimerStore.restTimerStart = Date() // start the rest timer
                }
                self.select(set: self.firstUncompletedSet)
                
                self.managedObjectContext.safeSave()
            })
            .background(VisualEffectView(effect: UIBlurEffect(style: .systemMaterial)))
        }
        .transition(AnyTransition.move(edge: .bottom))
    }

    var body: some View {
        VStack(spacing: 0) {
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
                editMode?.wrappedValue != .active {
                trainingSetEditor
            } // TODO: else if trainingExercise is finished, show next exercise / finish training button
        }
        .navigationBarTitle(Text(trainingExercise.exercise?.title ?? ""), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack(spacing: NAVIGATION_BAR_SPACING) {
                trainingExercise.exercise.map {
                    NavigationLink(destination: ExerciseDetailView(exercise: $0)
                        .environmentObject(self.settingsStore)) {
                            Image(systemName: "info.circle")
                    }
                }
                EditButton()
            }
        )
        .onAppear {
            self.select(set: self.firstUncompletedSet)
//            self.fetchTrainingExerciseHistory()
        }
        .onDisappear {
            self.managedObjectContext.safeSave()
        }
    }
}

#if DEBUG
struct TrainingExerciseDetailView_Previews : PreviewProvider {
    static var previews: some View {
        NavigationView {
        TrainingExerciseDetailView(trainingExercise: mockTrainingExercise)
            .environmentObject(mockSettingsStoreMetric)
            .environmentObject(restTimerStore)
            .environment(\.managedObjectContext, mockManagedObjectContext)
        }
    }
}
#endif
