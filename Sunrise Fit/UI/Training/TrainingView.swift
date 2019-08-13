//
//  TrainingView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct TrainingView: View {
    @Environment(\.managedObjectContext) var managedObjectContext

    @ObservedObject var training: Training
    
    @State private var showingCancelSheet = false
    @State private var showingExerciseSelectorSheet = false
    @State private var showingTrainingsLogSheet = false
    @State private var showingFinishWorkoutSheet = false
    @State private var exerciseSelectorSelection: Set<Exercise> = Set()
    
    private var trainingExercises: [TrainingExercise] {
        training.trainingExercises?.array as? [TrainingExercise] ?? []
    }
    
    private func createDefaultTrainingSets(trainingExercise: TrainingExercise) -> NSOrderedSet {
        var numberOfSets = 3
        // try to guess the number of sets
        if let history = try? managedObjectContext.fetch(trainingExercise.historyFetchRequest), history.count > 2 {
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
            let trainingSet = TrainingSet(context: managedObjectContext)
            trainingSets.append(trainingSet)
        }
        return NSOrderedSet(array: trainingSets)
    }
    
    private func currentTrainingExerciseDetailView(trainingExercise: TrainingExercise) -> some View {
        VStack(spacing: 0) {
            TimerBannerView(training: training)
            TrainingExerciseDetailView(trainingExercise: trainingExercise)
                .layoutPriority(1)
                .environmentObject(settingsStore)
        }
    }

    private func trainingExerciseCell(trainingExercise: TrainingExercise) -> some View {
        let completedSets = trainingExercise.numberOfCompletedSets ?? 0
        let totalSets = trainingExercise.trainingSets?.count ?? 0
        let done = completedSets == totalSets
        
        return HStack {
            NavigationLink(destination:
                    currentTrainingExerciseDetailView(trainingExercise: trainingExercise)
                ) {
                VStack(alignment: .leading) {
                    Text(trainingExercise.exercise?.title ?? "Unknown Exercise (\(trainingExercise.exerciseId))")
                        .foregroundColor(done ? .secondary : .primary)
                    Text("\(completedSets) of \(totalSets)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .layoutPriority(1)
                if done {
                    Spacer()
                    Image(systemName: "checkmark")
                        .imageScale(.small)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                }
            }
        }
    }
    
    private var trainingsLogSheet: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Log")
                    .font(.headline)
                HStack {
                    Button("Close") {
                        self.showingTrainingsLogSheet = false
                    }
                    Spacer()
                    Button(action: {
                        // TODO: share
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .padding()
            Divider()
            TrainingsLog(training: self.training)
                .environmentObject(settingsStore) // TODO: remove this (not working as of beta5)
        }
    }
    
    private var finishWorkoutSheet: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Summary")
                    .font(.headline)
                HStack {
                    Button("Cancel") {
                        self.showingFinishWorkoutSheet = false
                    }
                    Spacer()
                    Button("Finish") {
                        self.managedObjectContext.safeSave() // just in case the precondition below fires
                        
                        self.training.deleteAndRemoveUncompletedSets()
                        self.training.isCurrentTraining = false
                        self.training.start = self.training.start ?? self.training.end ?? Date()
                        self.training.end = self.training.end ?? Date()
                        
                        precondition(self.training.start! <= self.training.end!)
                        self.managedObjectContext.safeSave()
                        
                        let feedbackGenerator = UINotificationFeedbackGenerator()
                        feedbackGenerator.prepare()
                        feedbackGenerator.notificationOccurred(.success)
                    }
                }
            }
            .padding()
            Divider()
            TrainingsLog(training: self.training)
                .environmentObject(settingsStore) // TODO: remove this (not working as of beta5)
        }
    }
    
    private var exerciseSelectorSheet: some View {
        VStack {
            HStack {
                Button("Cancel") {
                    self.showingExerciseSelectorSheet = false
                    self.exerciseSelectorSelection.removeAll()
                }
                Spacer()
                Button("Add") {
                    for exercise in self.exerciseSelectorSelection {
                        let trainingExercise = TrainingExercise(context: self.managedObjectContext)
                        self.training.addToTrainingExercises(trainingExercise)
                        trainingExercise.exerciseId = Int16(exercise.id)
                        precondition(self.training.isCurrentTraining == true)
                        trainingExercise.addToTrainingSets(self.createDefaultTrainingSets(trainingExercise: trainingExercise))
                    }
                    self.showingExerciseSelectorSheet = false
                    self.exerciseSelectorSelection.removeAll()
                    self.managedObjectContext.safeSave()
                }
            }.padding()
            ExerciseMultiSelectionView(exerciseMuscleGroups: EverkineticDataProvider.exercisesGrouped, selection: self.$exerciseSelectorSelection)
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            if (self.training.trainingExercises?.count ?? 0) == 0 && self.training.start == nil {
                // the training is empty, do not need confirm to cancel
                self.managedObjectContext.delete(self.training)
                self.managedObjectContext.safeSave()
            } else {
                self.showingCancelSheet = true
            }
        }
        .actionSheet(isPresented: $showingCancelSheet, content: {
            ActionSheet(title: Text("This cannot be undone."), message: nil, buttons: [
                .destructive(Text("Delete Workout"), action: {
                    self.managedObjectContext.delete(self.training)
                    self.managedObjectContext.safeSave()
                }),
                .cancel()
            ])
        })
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TimerBannerView(training: training)
                List {
                    Section {
                        // TODO: actually edit training title
                        TextField("Title", text: .constant(""), onEditingChanged: { _ in }, onCommit: {})
                        // TODO: actually edit training comment
                        TextField("Comment", text: .constant(""), onEditingChanged: { _ in }, onCommit: {})
//                        DatePicker("Start", selection: .constant(Date()), in: ...Date())
                    }
                    Section(header: Text("Exercises".uppercased())) {
                        ForEach(trainingExercises, id: \.objectID) { trainingExercise in
                            self.trainingExerciseCell(trainingExercise: trainingExercise)
                        }
                        .onDelete { offsets in
                            let trainingExercises = self.trainingExercises
                            for i in offsets {
                                let trainingExercise = trainingExercises[i]
                                self.managedObjectContext.delete(trainingExercise)
                                trainingExercise.training?.removeFromTrainingExercises(trainingExercise)
                            }
                        }
                        .onMove { source, destination in
                            var trainingExercises = self.trainingExercises
                            trainingExercises.move(fromOffsets: source, toOffset: destination)
                            self.training.trainingExercises = NSOrderedSet(array: trainingExercises)
                        }
                        
                        Button(action: {
                            self.showingExerciseSelectorSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Exercises")
                            }
                        }
                    }
                    Section {
                        Button(action: {
                            self.showingFinishWorkoutSheet = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Finish Workout")
                            }
                        }
                    }
                }
                .listStyle(GroupedListStyle())
            }
            .navigationBarTitle(Text(training.displayTitle), displayMode: .inline)
            .navigationBarItems(leading: cancelButton,
                trailing:
                HStack {
                    // TODO: Replace with 3-dot button and more options
                    Button(action: {
                        self.showingTrainingsLogSheet = true
                    }) {
                        Image(systemName: "doc.plaintext")
                    }
                    EditButton()
                }
            )
            .sheet(isPresented: $showingExerciseSelectorSheet) { self.exerciseSelectorSheet }
        }
        // TODO: move sheet modifier to more appropiate place (as of beta5 only one sheet modifier per view)
        .sheet(isPresented: $showingTrainingsLogSheet) { self.trainingsLogSheet } // currently overwritten by the sheet below (beta5)
        .sheet(isPresented: $showingFinishWorkoutSheet) { self.finishWorkoutSheet }
    }
}

private struct TimerBannerView: View {
    @EnvironmentObject var restTimerStore: RestTimerStore
    
    @ObservedObject var training: Training

    @ObservedObject private var refresher = Refresher()
    
    private let trainingTimerDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    private let restTimerDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    // TODO: open start/end time editor
                }) {
                    HStack {
                        Image(systemName: "clock")
                        Text(trainingTimerDurationFormatter.string(from: training.duration) ?? "")
                            .font(Font.body.monospacedDigit())
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // TODO: open big rest timer view
                }) {
                    HStack {
                        Image(systemName: "timer")
                        restTimerStore.restTimerEnd.map({
                            Text(restTimerDurationFormatter.string(from: Date(), to: $0) ?? "")
                                .font(Font.body.monospacedDigit())
                        })
                    }
                }
            }
            .padding()
            Divider()
        }
        .background(VisualEffectView(effect: UIBlurEffect(style: .systemMaterial)))
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            self.refresher.refresh()
        }
    }
}

#if DEBUG
struct TrainingView_Previews: PreviewProvider {
    static var previews: some View {
        if UserDefaults.standard.restTimerEnd == nil {
            UserDefaults.standard.restTimerEnd = Date().addingTimeInterval(90)
        }
        return TrainingView(training: mockCurrentTraining)
            .environment(\.managedObjectContext, mockManagedObjectContext)
            .environmentObject(restTimerStore)
            .environmentObject(settingsStore)
    }
}
#endif
