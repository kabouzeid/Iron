//
//  WorkoutExerciseDetailView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 23.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import AVKit
import WorkoutDataKit

struct WorkoutExerciseDetailView : View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.editMode) var editMode
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var restTimerStore: RestTimerStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @FetchRequest(fetchRequest: WorkoutExercise.fetchRequest()) var workoutExerciseHistory // will be overwritten in init()
    @ObservedObject var workoutExercise: WorkoutExercise

    @State private var selectedWorkoutSet: WorkoutSet? = nil
    
    @ObservedObject private var workoutExerciseCommentInput = ValueHolder<String?>(initial: nil)
    private var workoutExerciseComment: Binding<String> {
        Binding(
            get: {
                self.workoutExerciseCommentInput.value ?? self.workoutExercise.comment ?? ""
        },
            set: { newValue in
                self.workoutExerciseCommentInput.value = newValue
        }
        )
    }
    private func adjustAndSaveWorkoutExerciseCommentInput() {
        guard let newValue = workoutExerciseCommentInput.value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutExerciseCommentInput.value = newValue
        workoutExercise.comment = newValue.isEmpty ? nil : newValue
    }
    
    init(workoutExercise: WorkoutExercise) {
        self.workoutExercise = workoutExercise
        _workoutExerciseHistory = FetchRequest(fetchRequest: workoutExercise.historyFetchRequest)
    }

    private func workoutSets(for workoutExercise: WorkoutExercise) -> [WorkoutSet] {
        workoutExercise.workoutSets?.array as? [WorkoutSet] ?? []
    }
    
    private func indexedWorkoutSets(for workoutExercise: WorkoutExercise) -> [(Int, WorkoutSet)] {
        workoutSets(for: workoutExercise).enumerated().map { ($0 + 1, $1) }
    }
    
    private var isCurrentWorkout: Bool {
        workoutExercise.workout?.isCurrentWorkout ?? false
    }

    private var firstUncompletedSet: WorkoutSet? {
        workoutExercise.workoutSets?.first(where: { !($0 as! WorkoutSet).isCompleted }) as? WorkoutSet
    }
    
    private func select(set: WorkoutSet?) {
        if let set = set, !set.isCompleted, set.repetitions == nil || set.weight == nil { // treat as uninitialized
            initRepsAndWeight(for: set)
        }
        
        // only animate if we would show/hide the editor
        if set == nil && selectedWorkoutSet != nil || set != nil && selectedWorkoutSet == nil {
            withAnimation {
                selectedWorkoutSet = set
            }
        } else {
            selectedWorkoutSet = set
        }
        
        if isCurrentWorkout, let uuid = set?.workoutExercise?.workout?.uuid {
            WatchConnectionManager.shared.updateAndObserveWatchWorkoutSelectedSet(workoutSet: set, uuid: uuid)
        }
    }
    
    private func initRepsAndWeight(for set: WorkoutSet) {
        let index = workoutExercise.workoutSets!.index(of: set)
        let previousSet: WorkoutSet?
        if index > 0 { // not the first set
            if let set = previousSetFromEqualExercise(for: set, at: index) {
                previousSet = set
            } else {
                previousSet = workoutExercise.workoutSets![index - 1] as? WorkoutSet
            }
        } else { // first set
            previousSet = workoutExerciseHistory.first?.workoutSets?.firstObject as? WorkoutSet
        }
        if let previousSet = previousSet {
            set.repetitionsValue = previousSet.repetitionsValue
            set.weightValue = previousSet.weightValue
        } else {
            // TODO: let the user configure default repetitions and weight
            set.repetitionsValue = 5
            if workoutExercise.exercise(in: exerciseStore.exercises)?.type == .barbell {
                let weightUnit = self.settingsStore.weightUnit
                set.weightValue = WeightUnit.convert(weight: weightUnit.barbellWeight, from: weightUnit, to: .metric)
            }
        }
    }
    
    // looks for a previous exercise where the same sequence of sets was performed
    private func previousSetFromEqualExercise(for set: WorkoutSet, at index: Int) -> WorkoutSet? {
        let exercise = workoutExerciseHistory.first {
            guard let count = $0.workoutSets?.count, index < count  else { return false }
            for i in 0..<index {
                guard let workoutSet1 = workoutExercise.workoutSets?[i] as? WorkoutSet else { return false }
                guard let workoutSet2 = $0.workoutSets?[i] as? WorkoutSet else { return false }
                if workoutSet1.weightValue != workoutSet2.weightValue || workoutSet1.repetitionsValue != workoutSet2.repetitionsValue {
                    return false
                }
            }
            return true
        }
        return exercise?.workoutSets?[index] as? WorkoutSet
    }
    
    private func moveWorkoutExerciseBehindLastBegun() {
        assert(isCurrentWorkout)
        guard let workout = workoutExercise.workout else { return }
        
        workout.removeFromWorkoutExercises(workoutExercise) // remove before doing the other stuff!
        
        let lastBegun = workout.workoutExercises?
            .compactMap { $0 as? WorkoutExercise }
            .last { $0.numberOfCompletedSets ?? 0 > 0 }
        
        if let lastBegun = lastBegun, let index = workout.workoutExercises?.index(of: lastBegun), index != NSNotFound {
            workout.insertIntoWorkoutExercises(workoutExercise, at: index + 1) // insert after last begun exercise
        } else {
            workout.insertIntoWorkoutExercises(workoutExercise, at: 0) // no workout exercise begun
        }
    }
    
    private func shouldHighlightRow(for set: WorkoutSet) -> Bool {
        !self.isCurrentWorkout || set == self.firstUncompletedSet
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
    
    private var currentWorkoutSets: some View {
        ForEach(indexedWorkoutSets(for: workoutExercise), id: \.1.id) { (index, workoutSet) in
            WorkoutSetCell(workoutSet: workoutSet, index: index, colorMode: self.selectedWorkoutSet == workoutSet ? .selected : self.shouldHighlightRow(for: workoutSet) ? .activated : .deactivated, isPlaceholder: !workoutSet.isCompleted && workoutSet != self.firstUncompletedSet, showCompleted: self.isCurrentWorkout, showUpNextIndicator: self.firstUncompletedSet == workoutSet)
//                .listRowBackground(self.selectedWorkoutSet == workoutSet && self.editMode?.wrappedValue != .active ? Color(UIColor.systemGray4) : nil)
                .background(Color.fakeClear) // hack that allows tap gesture to work (13.1 beta2)
                .onTapGesture {
                    guard self.editMode?.wrappedValue != .active else { return }
                    if self.selectedWorkoutSet?.hasChanges ?? false {
                        self.managedObjectContext.saveOrCrash()
                    }
                    if self.selectedWorkoutSet == workoutSet {
                        self.select(set: nil)
                    } else if workoutSet.isCompleted || workoutSet == self.firstUncompletedSet {
                        self.select(set: workoutSet)
                    }
                }
        }
        .onDelete { offsets in
            var deletedSelectedSet = false
            let workoutSets = self.workoutSets(for: self.workoutExercise)
            for i in offsets {
                let workoutSet = workoutSets[i]
                self.managedObjectContext.delete(workoutSet)
                workoutSet.workoutExercise?.removeFromWorkoutSets(workoutSet)
                
                if workoutSet == self.selectedWorkoutSet {
                    deletedSelectedSet = true
                }
            }
            if deletedSelectedSet {
                self.select(set: self.firstUncompletedSet)
            }
            self.managedObjectContext.saveOrCrash()
        }
        // TODO: move is yet too buggy
        //                        .onMove { source, destination in
        //                            guard source.first != destination || source.count > 1 else { return }
        //                            // make sure the destination is completed
        //                            guard (self.workoutExercise.workoutSets![destination] as! WorkoutSet).isCompleted else { return }
        //                            // make sure all sources are completed
        //                            guard source.reduce(true, { (allCompleted, index) in
        //                                allCompleted && (self.workoutExercise.workoutSets![index] as! WorkoutSet).isCompleted
        //                            }) else { return }
        //
        //                            // TODO: replace with swift 5.1 move() function when available
        //                            guard let index = source.first else { return }
        //                            guard let workoutSet = self.workoutExercise.workoutSets?[index] as? WorkoutSet else { return }
        //                            self.workoutExercise.removeFromWorkoutSets(at: index)
        //                            self.workoutExercise.insertIntoWorkoutSets(workoutSet, at: destination)
        //                        }
    }
    
    private var addSetButton: some View {
        Button(action: {
            let workoutSet = WorkoutSet.create(context: self.workoutExercise.managedObjectContext!)
            workoutSet.workoutExercise = self.workoutExercise
            self.select(set: self.firstUncompletedSet)
            if !self.isCurrentWorkout {
                // don't allow uncompleted sets if not in current workout
                workoutSet.isCompleted = true
            }
            self.managedObjectContext.saveOrCrash()
        }) {
            HStack {
                Image(systemName: "plus")
                Text("Add Set")
            }
        }
    }
    
    private var historyWorkoutSets: some View {
        ForEach(workoutExerciseHistory) { workoutExercise in
            Section(header: WorkoutExerciseSectionHeader(workoutExercise: workoutExercise)) {
                workoutExercise.comment.map {
                    Text($0.enquoted)
                        .lineLimit(1)
                        .font(Font.body.italic())
                        .foregroundColor(.secondary)
                }
                ForEach(self.indexedWorkoutSets(for: workoutExercise), id: \.1.id) { (index, workoutSet) in
                    WorkoutSetCell(workoutSet: workoutSet, index: index, colorMode: .disabled)
                }
            }
        }
    }
    
    private var restTimerDuration: TimeInterval {
        // TODO: allow customizable default rest timer for each exercise
        switch workoutExercise.exercise(in: exerciseStore.exercises)?.type {
        case .barbell:
            return settingsStore.defaultRestTimeBarbellBased
        case .dumbbell:
            return settingsStore.defaultRestTimeDumbbellBased
        default:
            return settingsStore.defaultRestTime
        }
    }
    
    private var workoutSetEditor: some View {
        VStack(spacing: 0) {
            Divider()
            WorkoutSetEditor(workoutSet: self.selectedWorkoutSet!, onDone: {
                guard let set = self.selectedWorkoutSet else { return }
                
                if !set.isCompleted {
                     assert(self.isCurrentWorkout)
                    // these preconditions should never ever happen, but just to be sure
                    precondition(set.weightValue >= 0)
                    precondition(set.repetitionsValue >= 0)
                    set.isCompleted = true
                    let workout = set.workoutExercise?.workout
                    workout?.start = workout?.start ?? Date()
                    #warning("enable moveWorkoutExerciseBehindLastBegun() again later? Currenlty causes a 'jump back' bug in NavigationView")
//                    self.moveWorkoutExerciseBehindLastBegun()
                    
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.prepare()
                    feedbackGenerator.notificationOccurred(.success)
                    AudioServicesPlaySystemSound(1103) // Tink sound
                    
                    self.restTimerStore.restTimerDuration = self.restTimerDuration
                    self.restTimerStore.restTimerStart = Date() // start the rest timer
                }
                self.select(set: self.firstUncompletedSet)
                
                self.managedObjectContext.saveOrCrash()
            })
            .background(Color(.systemFill).opacity(0.5))
        }
        .transition(AnyTransition.move(edge: .bottom))
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    TextField("Comment", text: workoutExerciseComment, onEditingChanged: { isEditingTextField in
                        if !isEditingTextField {
                            self.adjustAndSaveWorkoutExerciseCommentInput()
                        }
                    })

                    currentWorkoutSets
                    addSetButton
                }
                
                historyWorkoutSets
            }
            .listStyle(GroupedListStyle())
            
            if selectedWorkoutSet != nil &&
                (self.workoutExercise.workoutSets?.contains(self.selectedWorkoutSet!) ?? false) &&
                editMode?.wrappedValue != .active {
                workoutSetEditor
            } // TODO: else if workoutExercise is finished, show next exercise / finish workout button
        }
        .navigationBarTitle(Text(workoutExercise.exercise(in: exerciseStore.exercises)?.title ?? ""), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack(spacing: NAVIGATION_BAR_SPACING) {
                iOS13_3.map { // otherwise crashes when going back on iOS 13.2.2
                    workoutExercise.exercise(in: exerciseStore.exercises).map {
                        NavigationLink(destination: ExerciseDetailView(exercise: $0)
                            .environmentObject(self.settingsStore)) {
                                Image(systemName: "info.circle")
                                    .padding([.leading, .top, .bottom])
                        }
                    }
                }
                EditButton()
            }
        )
        .onAppear {
            self.select(set: self.firstUncompletedSet)
//            self.fetchWorkoutExerciseHistory()
        }
        .onDisappear {
            self.managedObjectContext.saveOrCrash()
        }
    }
    
    // kind of a hack
    private var iOS13_3: Void? {
        if #available(iOS 13.3, *) {
            return ()
        } else {
            return nil
        }
    }
}

#if DEBUG
struct WorkoutExerciseDetailView_Previews : PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutExerciseDetailView(workoutExercise: MockWorkoutData.metricRandom.workoutExercise)
                .mockEnvironment(weightUnit: .metric, isPro: true)
        }
    }
}
#endif
