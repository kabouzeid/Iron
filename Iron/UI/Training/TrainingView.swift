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
    @EnvironmentObject var restTimerStore: RestTimerStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    @EnvironmentObject var settingsStore: SettingsStore
    
    @ObservedObject var training: Training
    
    @State private var showingCancelActionSheet = false
    @State private var activeSheet: SheetType?
    
    private enum SheetType: Identifiable {
        case log
        case exerciseSelector
        case finish
        
        var id: Self { self }
    }
    
    private func sheetView(type: SheetType) -> AnyView {
        switch type {
        case .log:
            return self.trainingsLogSheet.typeErased
        case .exerciseSelector:
            return AddExercisesSheet(exercises: exerciseStore.exercises, onAdd: { selection in
                for exercise in selection {
                    let trainingExercise = TrainingExercise(context: self.managedObjectContext)
                    self.training.addToTrainingExercises(trainingExercise)
                    trainingExercise.exerciseId = Int16(exercise.id)
                    precondition(self.training.isCurrentTraining == true)
                    trainingExercise.addToTrainingSets(self.createDefaultTrainingSets(trainingExercise: trainingExercise))
                }
                self.managedObjectContext.safeSave()
                }).typeErased
        case .finish:
            return self.finishWorkoutSheet.typeErased
        }
    }
    
    private func cancelRestTimer() {
        self.restTimerStore.restTimerStart = nil
        self.restTimerStore.restTimerDuration = nil
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
        let text: String?
        if let totalSets = trainingExercise.trainingSets?.count, totalSets > 0, let completedSets = trainingExercise.numberOfCompletedSets{
            text = "\(completedSets) of \(totalSets)"
        } else {
            text = nil
        }
        let isCompleted = trainingExercise.isCompleted ?? false
        
        return HStack {
            NavigationLink(destination:
                    currentTrainingExerciseDetailView(trainingExercise: trainingExercise)
                ) {
                VStack(alignment: .leading) {
                    Text(trainingExercise.exercise(in: exerciseStore.exercises)?.title ?? "Unknown Exercise (\(trainingExercise.exerciseId))")
                        .foregroundColor(isCompleted ? .secondary : .primary)
                    text.map {
                        Text($0)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .layoutPriority(1)
                if isCompleted {
                    Spacer()
                    Image(systemName: "checkmark")
                        .imageScale(.small)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                }
            }
        }
    }
    
    private var closeSheetButton: some View {
        Button("Close") {
            self.activeSheet = nil
        }
    }
    
    private var trainingsLogSheet: some View {
        VStack(spacing: 0) {
            SheetBar(title: "Log", leading: closeSheetButton,
                trailing:
                Button(action: {
                    // TODO: share
                    // UIActivityViewController doesn't work in sheets as of 13.1 beta3
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            ).padding()
            Divider()
            TrainingsLog(training: self.training)
                .environmentObject(settingsStore)
                .environmentObject(exerciseStore)
        }
    }
    
    private func finishWorkout() {
        self.managedObjectContext.safeSave() // just in case the precondition below fires
        
        // save the training
        self.training.prepareForFinish()
        self.training.isCurrentTraining = false
        self.managedObjectContext.safeSave()
        
        self.cancelRestTimer()
        
        // haptic feedback
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(.success)
    }
    
    private var finishWorkoutSheet: some View {
        VStack(spacing: 0) {
            SheetBar(title: "Summary", leading: closeSheetButton,
                trailing:
                Button("Finish") {
                    self.finishWorkout()
                }
            ).padding()
            Divider()
            TrainingsLog(training: self.training)
                .environmentObject(settingsStore)
                .environmentObject(exerciseStore)
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            if (self.training.trainingExercises?.count ?? 0) == 0 {
                // the training is empty, do not need confirm to cancel
                self.managedObjectContext.delete(self.training)
                self.managedObjectContext.safeSave()
                self.cancelRestTimer()
            } else {
                self.showingCancelActionSheet = true
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
                            self.activeSheet = .exerciseSelector
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Exercises")
                            }
                        }
                    }
                    Section {
                        Button(action: {
                            self.activeSheet = .finish
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
            .navigationBarTitle(Text(training.displayTitle(in: exerciseStore.exercises)), displayMode: .inline)
            .navigationBarItems(leading: cancelButton,
                trailing:
                HStack(spacing: NAVIGATION_BAR_SPACING) {
                    // TODO: Replace with 3-dot button and more options
                    Button(action: {
                        self.activeSheet = .log
                    }) {
                        Image(systemName: "doc.plaintext")
                    }
                    EditButton()
                }
            )
        }
        .sheet(item: $activeSheet) { type in
            self.sheetView(type: type)
        }
        .actionSheet(isPresented: $showingCancelActionSheet, content: {
            ActionSheet(title: Text("This cannot be undone."), message: nil, buttons: [
                .destructive(Text("Delete Workout"), action: {
                    self.managedObjectContext.delete(self.training)
                    self.managedObjectContext.safeSave()
                    self.cancelRestTimer()
                }),
                .cancel()
            ])
        })
    }
}

#if DEBUG
struct TrainingView_Previews: PreviewProvider {
    static var previews: some View {
        if appRestTimerStore.restTimerRemainingTime == nil {
            appRestTimerStore.restTimerStart = Date()
            appRestTimerStore.restTimerDuration = 10
        }
        return TrainingView(training: mockCurrentTraining)
            .environment(\.managedObjectContext, mockManagedObjectContext)
            .environmentObject(appRestTimerStore)
            .environmentObject(appSettingsStore)
            .environmentObject(appExerciseStore)
    }
}
#endif
