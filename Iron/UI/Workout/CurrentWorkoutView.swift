//
//  CurrentWorkoutView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import StoreKit
import AVKit
import HealthKit
import WorkoutDataKit
import os.log

struct CurrentWorkoutView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var restTimerStore: RestTimerStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    @EnvironmentObject var settingsStore: SettingsStore
    
    @ObservedObject var workout: Workout
    
    @State private var showingCancelActionSheet = false
    @State private var activeSheet: SheetType?
    
    private enum SheetType: Identifiable {
        case exerciseSelector
        case finish
        
        var id: Self { self }
    }
    
    private func sheetView(type: SheetType) -> AnyView {
        switch type {
        case .exerciseSelector:
            return AddExercisesSheet(
                exercises: exerciseStore.shownExercises,
                recentExercises: AddExercisesSheet.loadRecentExercises(context: managedObjectContext, exercises: exerciseStore.shownExercises),
                onAdd: { selection in
                    for exercise in selection {
                        let workoutExercise = WorkoutExercise.create(context: self.managedObjectContext)
                        self.workout.addToWorkoutExercises(workoutExercise)
                        workoutExercise.exerciseUuid = exercise.uuid
                        precondition(self.workout.isCurrentWorkout == true)
                        workoutExercise.addToWorkoutSets(self.createDefaultWorkoutSets(workoutExercise: workoutExercise))
                    }
                    self.managedObjectContext.saveOrCrash()
                }
            ).typeErased
        case .finish:
            return self.finishWorkoutSheet.typeErased
        }
    }
    
    private func createDefaultWorkoutSets(workoutExercise: WorkoutExercise) -> NSOrderedSet {
        var numberOfSets = 3
        // try to guess the number of sets
        if let history = try? managedObjectContext.fetch(workoutExercise.historyFetchRequest), history.count >= 3 {
            // one month since last workout and at least three workouts
            if let firstHistoryStart = history[0].workout?.start, let thirdHistoryStart = history[2].workout?.start {
                let cutoff = min(thirdHistoryStart, Calendar.current.date(byAdding: .month, value: -1, to: firstHistoryStart)!)
                let filteredAndSortedHistory = history
                    .filter {
                        guard let start = $0.workout?.start else { return false }
                        return start >= cutoff
                }
                .sorted {
                    ($0.workoutSets?.count ?? 0) < ($1.workoutSets?.count ?? 0)
                }
                
                assert(filteredAndSortedHistory.count >= 3)
                let median = filteredAndSortedHistory[filteredAndSortedHistory.count / 2]
                numberOfSets = median.workoutSets?.count ?? numberOfSets
            }
        }
        var workoutSets = [WorkoutSet]()
        for _ in 0..<numberOfSets {
            let workoutSet = WorkoutSet.create(context: managedObjectContext)
            workoutSets.append(workoutSet)
        }
        return NSOrderedSet(array: workoutSets)
    }

    private var workoutExercises: [WorkoutExercise] {
        workout.workoutExercises?.array as? [WorkoutExercise] ?? []
    }
    
    @State private var workoutCommentInput: String? = nil
    private var workoutComment: Binding<String> {
        Binding(
            get: {
                self.workoutCommentInput ?? self.workout.comment ?? ""
        },
            set: { newValue in
                self.workoutCommentInput = newValue
        }
        )
    }
    private func adjustAndSaveWorkoutCommentInput() {
        guard let newValue = workoutCommentInput?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutCommentInput = newValue
        workout.comment = newValue.isEmpty ? nil : newValue
        self.managedObjectContext.saveOrCrash()

    }
    
    @State private var workoutTitleInput: String? = nil
    private var workoutTitle: Binding<String> {
        Binding(
            get: {
                self.workoutTitleInput ?? self.workout.title ?? ""
            },
            set: { newValue in
                self.workoutTitleInput = newValue
            }
        )
    }
    private func adjustAndSaveWorkoutTitleInput() {
        guard let newValue = workoutTitleInput?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutTitleInput = newValue
        workout.title = newValue.isEmpty ? nil : newValue
    }
    
    private func currentWorkoutExerciseDetailView(workoutExercise: WorkoutExercise) -> some View {
        VStack(spacing: 0) {
            // on the iPad we have two columns at once so we already have a TimerBannerView
            if UIDevice.current.userInterfaceIdiom != .pad {
                if #available(iOS 15.0, *) {
                    Divider()
                }
                TimerBannerView(workout: workout)
                Divider()
            }
            WorkoutExerciseDetailView(workoutExercise: workoutExercise)
                .layoutPriority(1)
                .environmentObject(settingsStore)
        }
    }

    private func workoutExerciseCell(workoutExercise: WorkoutExercise) -> some View {
        let text: String?
        if let totalSets = workoutExercise.workoutSets?.count, totalSets > 0, let completedSets = workoutExercise.numberOfCompletedSets{
            text = "\(completedSets) / \(totalSets)"
        } else {
            text = nil
        }
        let isCompleted = workoutExercise.isCompleted ?? false
        
        return HStack {
            NavigationLink(destination:
                    currentWorkoutExerciseDetailView(workoutExercise: workoutExercise)
                ) {
                VStack(alignment: .leading) {
                    Text(workoutExercise.exercise(in: exerciseStore.exercises)?.title ?? "Unknown Exercise")
                        .foregroundColor(isCompleted ? .secondary : .primary)
                    text.map {
                        Text($0)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .layoutPriority(1) // without this the text is suddenly displayed multiline (because of the spacer below)
                if isCompleted {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private var closeSheetButton: some View {
        Button("Close") {
            self.activeSheet = nil
        }
    }
    
    private func finishWorkout() {
        workout.finishOrCrash()
        
        // haptic feedback
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(.success)
        AudioServicesPlaySystemSound(1103) // Tink sound
        
        UserDefaults.standard.finishedWorkoutsCount += 1
        if UserDefaults.standard.finishedWorkoutsCount == 6 {
            // ask for review after the user finishes his third workout
            SKStoreReviewController.requestReview()
        }
    }
    
    @State private var finishWorkoutSheetActivityItems: [Any]?
    private var finishWorkoutSheet: some View {
        NavigationView {
            WorkoutLog(workout: self.workout)
                .navigationBarTitle("Summary", displayMode: .inline)
                .navigationBarItems(
                    leading: closeSheetButton,
                    trailing:
                    HStack(spacing: NAVIGATION_BAR_SPACING) {
                        Button(action: {
                            guard let logText = self.workout.logText(in: self.exerciseStore.exercises, weightUnit: self.settingsStore.weightUnit) else { return }
                            self.finishWorkoutSheetActivityItems = [logText]
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        
                        Button("Finish") {
                            self.finishWorkout()
                        }
                    }
                )
                .overlay(ActivitySheet(activityItems: $finishWorkoutSheetActivityItems))
                .environmentObject(settingsStore)
                .environmentObject(exerciseStore)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func cancelWorkout() {
        workout.cancelOrCrash()
        
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(.success)
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            if (self.workout.workoutExercises?.count ?? 0) == 0 {
                // the workout is empty, do not need confirm to cancel
                self.cancelWorkout()
            } else {
                guard UIDevice.current.userInterfaceIdiom != .pad else { // TODO: actionSheet not supported on iPad yet (13.2)
                    self.cancelWorkout()
                    return
                }
                self.showingCancelActionSheet = true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if #available(iOS 15.0, *) {
                    Divider()
                }
                TimerBannerView(workout: workout)
                Divider()
                List {
                    Section {
                        // TODO: add clear button
                        TextField("Title", text: workoutTitle, onEditingChanged: { isEditingTextField in
                            if !isEditingTextField {
                                self.adjustAndSaveWorkoutTitleInput()
                            }
                        })
                        TextField("Comment", text: workoutComment, onEditingChanged: { isEditingTextField in
                            if !isEditingTextField {
                                self.adjustAndSaveWorkoutCommentInput()
                            }
                        })
                    }
                    Section(header: Text("Exercises".uppercased())) {
                        ForEach(workoutExercises) { workoutExercise in
                            self.workoutExerciseCell(workoutExercise: workoutExercise)
                        }
                        .onDelete { offsets in
                            let workoutExercises = self.workoutExercises
                            for i in offsets {
                                let workoutExercise = workoutExercises[i]
                                self.managedObjectContext.delete(workoutExercise)
                                workoutExercise.workout?.removeFromWorkoutExercises(workoutExercise)
                            }
                        }
                        .onMove { source, destination in
                            var workoutExercises = self.workoutExercises
                            workoutExercises.move(fromOffsets: source, toOffset: destination)
                            self.workout.workoutExercises = NSOrderedSet(array: workoutExercises)
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
                .listStyleCompat_InsetGroupedListStyle()
            }
            .navigationBarTitle(Text(workout.displayTitle(in: exerciseStore.exercises)), displayMode: .inline)
            .navigationBarItems(leading: cancelButton, trailing: EditButton())
            
            Text("No exercise selected")
                .foregroundColor(.secondary)
        }
        .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 1 : 0) // hack that makes the master view show on iPad on portrait mode
        .sheet(item: $activeSheet) { type in
            self.sheetView(type: type)
        }
        .actionSheet(isPresented: $showingCancelActionSheet, content: {
            ActionSheet(title: Text("This cannot be undone."), message: nil, buttons: [
                .destructive(Text("Discard Workout"), action: {
                    self.cancelWorkout()
                }),
                .cancel()
            ])
        })
    }
}

#if DEBUG
struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        if RestTimerStore.shared.restTimerRemainingTime == nil {
            RestTimerStore.shared.restTimerStart = Date()
            RestTimerStore.shared.restTimerDuration = 10
        }
        return CurrentWorkoutView(workout: MockWorkoutData.metricRandom.currentWorkout)
            .mockEnvironment(weightUnit: .metric)
    }
}
#endif
