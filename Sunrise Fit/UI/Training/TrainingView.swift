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
    
    @ObservedObject private var trainingCommentInput = ValueHolder<String?>(initial: nil)
    private var trainingComment: Binding<String> {
        Binding(
            get: {
                self.trainingCommentInput.value ?? self.training.comment ?? ""
        },
            set: { newValue in
                self.trainingCommentInput.value = newValue
        }
        )
    }
    private func adjustAndSaveTrainingCommentInput() {
        guard let newValue = trainingCommentInput.value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        trainingCommentInput.value = newValue
        training.comment = newValue.isEmpty ? nil : newValue
    }
    
    @ObservedObject private var trainingTitleInput = ValueHolder<String?>(initial: nil)
    private var trainingTitle: Binding<String> {
        Binding(
            get: {
                self.trainingTitleInput.value ?? self.training.title ?? ""
        },
            set: { newValue in
                self.trainingTitleInput.value = newValue
        }
        )
    }
    private func adjustAndSaveTrainingTitleInput() {
        guard let newValue = trainingTitleInput.value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        trainingTitleInput.value = newValue
        training.title = newValue.isEmpty ? nil : newValue
    }
    
    private func createDefaultTrainingSets(trainingExercise: TrainingExercise) -> NSOrderedSet {
        var numberOfSets = 3
        // try to guess the number of sets
        if let history = try? managedObjectContext.fetch(trainingExercise.historyFetchRequest), history.count >= 3 {
            // one month since last training and at least three trainings
            if let firstHistoryStart = history[0].training?.start, let thirdHistoryStart = history[2].training?.start {
                let cutoff = min(thirdHistoryStart, Calendar.current.date(byAdding: .month, value: -1, to: firstHistoryStart)!)
                let filteredAndSortedHistory = history
                    .filter {
                        guard let start = $0.training?.start else { return false }
                        return start >= cutoff
                    }
                    .sorted {
                        ($0.trainingSets?.count ?? 0) < ($1.trainingSets?.count ?? 0)
                    }
                
                assert(filteredAndSortedHistory.count >= 3)
                let median = filteredAndSortedHistory[filteredAndSortedHistory.count / 2]
                numberOfSets = median.trainingSets?.count ?? numberOfSets
            }
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
            Divider()
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
                        self.training.start = self.training.safeStart // should already be set, but just to be safe
                        self.training.end = self.training.safeEnd
                        
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
        VStack(spacing: 0) {
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
                .environment(\.isEnabled, !self.exerciseSelectorSelection.isEmpty)
            }.padding()
            ExerciseMultiSelectionView(exerciseMuscleGroups: EverkineticDataProvider.exercisesGrouped, selection: self.$exerciseSelectorSelection)
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            if (self.training.trainingExercises?.count ?? 0) == 0 {
                // the training is empty, do not need confirm to cancel
                self.managedObjectContext.delete(self.training)
                self.managedObjectContext.safeSave()
            } else {
                self.showingCancelSheet = true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TimerBannerView(training: training)
                Divider()
                List {
                    Section {
                        // TODO: add clear button
                        TextField("Title", text: trainingTitle, onEditingChanged: { isEditingTextField in
                            if !isEditingTextField {
                                self.adjustAndSaveTrainingTitleInput()
                            }
                        })
                        TextField("Comment", text: trainingComment, onEditingChanged: { isEditingTextField in
                            if !isEditingTextField {
                                self.adjustAndSaveTrainingCommentInput()
                            }
                        })
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
                    .sheet(isPresented: $showingTrainingsLogSheet) { self.trainingsLogSheet }
                    EditButton()
                }
            )
            .sheet(isPresented: $showingExerciseSelectorSheet) { self.exerciseSelectorSheet }
        }
        .sheet(isPresented: $showingFinishWorkoutSheet) { self.finishWorkoutSheet }
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
}



#if DEBUG
struct TrainingView_Previews: PreviewProvider {
    static var previews: some View {
        if restTimerStore.restTimerRemainingTime == nil {
            restTimerStore.restTimerStart = Date()
            restTimerStore.restTimerDuration = 10
        }
        return TrainingView(training: mockCurrentTraining)
            .environment(\.managedObjectContext, mockManagedObjectContext)
            .environmentObject(restTimerStore)
            .environmentObject(settingsStore)
    }
}
#endif
