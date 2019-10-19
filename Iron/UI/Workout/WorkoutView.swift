//
//  WorkoutView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import StoreKit
import AVKit
import HealthKit

struct WorkoutView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var restTimerStore: RestTimerStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    @EnvironmentObject var settingsStore: SettingsStore
    
    @ObservedObject var workout: Workout
    
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
            return self.workoutsLogSheet.typeErased
        case .exerciseSelector:
            return AddExercisesSheet(exercises: exerciseStore.shownExercises, onAdd: { selection in
                for exercise in selection {
                    let workoutExercise = WorkoutExercise(context: self.managedObjectContext)
                    self.workout.addToWorkoutExercises(workoutExercise)
                    workoutExercise.exerciseId = Int16(exercise.id)
                    precondition(self.workout.isCurrentWorkout == true)
                    workoutExercise.addToWorkoutSets(self.createDefaultWorkoutSets(workoutExercise: workoutExercise))
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
            let workoutSet = WorkoutSet(context: managedObjectContext)
            workoutSets.append(workoutSet)
        }
        return NSOrderedSet(array: workoutSets)
    }

    private var workoutExercises: [WorkoutExercise] {
        workout.workoutExercises?.array as? [WorkoutExercise] ?? []
    }
    
    @ObservedObject private var workoutCommentInput = ValueHolder<String?>(initial: nil)
    private var workoutComment: Binding<String> {
        Binding(
            get: {
                self.workoutCommentInput.value ?? self.workout.comment ?? ""
        },
            set: { newValue in
                self.workoutCommentInput.value = newValue
        }
        )
    }
    private func adjustAndSaveWorkoutCommentInput() {
        guard let newValue = workoutCommentInput.value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutCommentInput.value = newValue
        workout.comment = newValue.isEmpty ? nil : newValue
    }
    
    @ObservedObject private var workoutTitleInput = ValueHolder<String?>(initial: nil)
    private var workoutTitle: Binding<String> {
        Binding(
            get: {
                self.workoutTitleInput.value ?? self.workout.title ?? ""
            },
            set: { newValue in
                self.workoutTitleInput.value = newValue
            }
        )
    }
    private func adjustAndSaveWorkoutTitleInput() {
        guard let newValue = workoutTitleInput.value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutTitleInput.value = newValue
        workout.title = newValue.isEmpty ? nil : newValue
    }
    
    private func currentWorkoutExerciseDetailView(workoutExercise: WorkoutExercise) -> some View {
        VStack(spacing: 0) {
            TimerBannerView(workout: workout)
            Divider()
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
                    Text(workoutExercise.exercise(in: exerciseStore.exercises)?.title ?? "Unknown Exercise (id: \(workoutExercise.exerciseId))")
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
    
    private var workoutsLogSheet: some View {
        NavigationView {
            WorkoutLog(workout: self.workout)
                .navigationBarTitle("Log", displayMode: .inline)
                .navigationBarItems(
                    leading: closeSheetButton,
                    trailing:
                    Button(action: {
                        // TODO: share
                        // UIActivityViewController doesn't work in sheets as of 13.1 beta3
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                )
                .environmentObject(settingsStore)
                .environmentObject(exerciseStore)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func finishWorkout() {
        self.managedObjectContext.safeSave() // just in case the precondition below fires
        
        // save the workout
        self.workout.prepareForFinish()
        self.workout.isCurrentWorkout = false
        self.managedObjectContext.safeSave()
        
        self.cancelRestTimer()
        
        // haptic feedback
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(.success)
        AudioServicesPlaySystemSound(1103) // Tink sound
        
        HealthManager.shared.requestPermissions {
            if let start = self.workout.start, let end = self.workout.end, let duration = self.workout.duration { // should never fail
                let title = self.workout.displayTitle(in: self.exerciseStore.exercises)
                let hkWorkout = HKWorkout(activityType: .traditionalStrengthTraining, start: start, end: end, duration: duration, totalEnergyBurned: nil, totalDistance: nil, device: .local(), metadata: [HKMetadataKeyWorkoutBrandName : title])
                HealthManager.shared.healthStore.save(hkWorkout) { _,_ in }
            }
        }
        
        UserDefaults.standard.finishedWorkoutsCount += 1
        if UserDefaults.standard.finishedWorkoutsCount == 3 {
            // ask for review after the user finishes his third workout
            SKStoreReviewController.requestReview()
        }
    }
    
    private var finishWorkoutSheet: some View {
        NavigationView {
            WorkoutLog(workout: self.workout)
                .navigationBarTitle("Summary", displayMode: .inline)
                .navigationBarItems(
                    leading: closeSheetButton,
                    trailing:
                    Button("Finish") {
                        self.finishWorkout()
                    }
                )
                .environmentObject(settingsStore)
                .environmentObject(exerciseStore)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func cancelWorkout() {
        self.managedObjectContext.delete(self.workout)
        self.managedObjectContext.safeSave()
        self.cancelRestTimer()
        
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
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
                        ForEach(workoutExercises, id: \.objectID) { workoutExercise in
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
                .listStyle(GroupedListStyle())
            }
            .navigationBarTitle(Text(workout.displayTitle(in: exerciseStore.exercises)), displayMode: .inline)
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
        .navigationViewStyle(StackNavigationViewStyle()) // TODO: remove, currently needed for iPad as of 13.1.1
        .sheet(item: $activeSheet) { type in
            self.sheetView(type: type)
        }
        .actionSheet(isPresented: $showingCancelActionSheet, content: {
            ActionSheet(title: Text("This cannot be undone."), message: nil, buttons: [
                .destructive(Text("Delete Workout"), action: {
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
        return WorkoutView(workout: MockWorkoutData.metricRandom.currentWorkout)
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
