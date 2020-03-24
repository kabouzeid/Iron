//
//  WorkoutRoutineExerciseView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 21.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct WorkoutRoutineExerciseView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.editMode) var editMode
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @ObservedObject var workoutRoutineExercise: WorkoutRoutineExercise
    @State private var selectedWorkoutRoutineSet: WorkoutRoutineSet? = nil
    
    @ObservedObject private var workoutRoutineExerciseCommentInput = ValueHolder<String?>(initial: nil)
    private var workoutRoutineExerciseComment: Binding<String> {
        Binding(
            get: {
                self.workoutRoutineExerciseCommentInput.value ?? self.workoutRoutineExercise.comment ?? ""
            },
            set: { newValue in
                self.workoutRoutineExerciseCommentInput.value = newValue
            }
        )
    }
    private func adjustAndSaveWorkoutRoutineExerciseCommentInput() {
        guard let newValue = workoutRoutineExerciseCommentInput.value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutRoutineExerciseCommentInput.value = newValue
        workoutRoutineExercise.comment = newValue.isEmpty ? nil : newValue
    }
    
    private func workoutRoutineSets(for workoutRoutineExercise: WorkoutRoutineExercise) -> [WorkoutRoutineSet] {
        workoutRoutineExercise.workoutRoutineSets?.array as? [WorkoutRoutineSet] ?? []
    }
    
    private func indexedWorkoutRoutineSets(for workoutRoutineExercise: WorkoutRoutineExercise) -> [(Int, WorkoutRoutineSet)] {
        workoutRoutineSets(for: workoutRoutineExercise).enumerated().map { ($0 + 1, $1) }
    }
    
    private func select(set: WorkoutRoutineSet?) {
        // reset the temporary state of the set editor
        editorRepetitionsMin = nil
        editorRepetitionsMax = nil
        
        // only animate if we would show/hide the editor
        if set == nil && selectedWorkoutRoutineSet != nil || set != nil && selectedWorkoutRoutineSet == nil {
            withAnimation {
                selectedWorkoutRoutineSet = set
            }
        } else {
            selectedWorkoutRoutineSet = set
        }
    }
    
    private var workoutRoutineSets: some View {
        ForEach(indexedWorkoutRoutineSets(for: workoutRoutineExercise), id: \.1.id) { (index, workoutRoutineSet) in
            WorkoutRoutineSetCell(workoutRoutineSet: workoutRoutineSet, index: index, isSelected: self.selectedWorkoutRoutineSet == workoutRoutineSet)
                .background(Color.fakeClear) // hack that allows tap gesture to work (13.1 beta2)
                .onTapGesture {
                    guard self.editMode?.wrappedValue != .active else { return }
                    if self.selectedWorkoutRoutineSet?.hasChanges ?? false {
                        self.managedObjectContext.safeSave()
                    }
                    if self.selectedWorkoutRoutineSet == workoutRoutineSet {
                        self.select(set: nil)
                    } else {
                        self.select(set: workoutRoutineSet)
                    }
            }
        }
        .onDelete { offsets in
            let workoutRoutineSets = self.workoutRoutineSets(for: self.workoutRoutineExercise)
            for i in offsets {
                let workoutRoutineSet = workoutRoutineSets[i]
                self.managedObjectContext.delete(workoutRoutineSet)
                workoutRoutineSet.workoutRoutineExercise?.removeFromWorkoutRoutineSets(workoutRoutineSet)
            }
            self.managedObjectContext.safeSave()
        }
        .onMove { source, destination in
            var workoutRoutineSets = self.workoutRoutineSets(for: self.workoutRoutineExercise)
            workoutRoutineSets.move(fromOffsets: source, toOffset: destination)
            self.workoutRoutineExercise.workoutRoutineSets = NSOrderedSet(array: workoutRoutineSets)
        }
    }
    
    private var addSetButton: some View {
        Button(action: {
            // get the lastSet before adding a new set
            let lastSet = self.workoutRoutineExercise.workoutRoutineSets?.lastObject as? WorkoutRoutineSet
            
            let workoutRoutineSet = WorkoutRoutineSet.create(context: self.managedObjectContext)
            workoutRoutineSet.workoutRoutineExercise = self.workoutRoutineExercise
            
            if let previousSet = lastSet {
                workoutRoutineSet.repetitionsMinValue = previousSet.repetitionsMinValue
                workoutRoutineSet.repetitionsMaxValue = previousSet.repetitionsMaxValue
            } else {
                workoutRoutineSet.repetitionsMinValue = 5
                workoutRoutineSet.repetitionsMaxValue = 5
            }
            
            self.managedObjectContext.safeSave()
        }) {
            HStack {
                Image(systemName: "plus")
                Text("Add Set")
            }
        }
    }
    
    @State private var editorRepetitionsMin: Int16?
    @State private var editorRepetitionsMax: Int16?
    private var workoutRoutineSetEditor: some View {
        let sets = self.workoutRoutineSets(for: self.workoutRoutineExercise)
        
        return VStack(spacing: 0) {
            Divider()
            WorkoutRoutineSetEditor(
                workoutRoutineSet: self.selectedWorkoutRoutineSet!,
                overwriteRepetitionsMin: $editorRepetitionsMin,
                overwriteRepetitionsMax: $editorRepetitionsMax,
                showNext: self.selectedWorkoutRoutineSet! != sets.last,
                onDone: {
                    if self.selectedWorkoutRoutineSet?.hasChanges ?? false {
                        self.managedObjectContext.safeSave()
                    }
                    
                    if let index = sets.firstIndex(of: self.selectedWorkoutRoutineSet!), index + 1 < sets.count {
                        self.select(set: sets[index + 1])
                    } else {
                        self.select(set: nil)
                    }
            })
            .background(Color(.systemFill).opacity(0.5))
        }
        .transition(AnyTransition.move(edge: .bottom))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    TextField("Comment", text: workoutRoutineExerciseComment, onEditingChanged: { isEditingTextField in
                        if !isEditingTextField {
                            self.adjustAndSaveWorkoutRoutineExerciseCommentInput()
                        }
                    })
                    
                    workoutRoutineSets
                    addSetButton
                }
            }
            .listStyle(GroupedListStyle())
            
            if selectedWorkoutRoutineSet != nil &&
                (self.workoutRoutineExercise.workoutRoutineSets?.contains(self.selectedWorkoutRoutineSet!) ?? false) &&
                editMode?.wrappedValue != .active {
                workoutRoutineSetEditor
            }
        }
        .navigationBarTitle(Text(workoutRoutineExercise.exercise(in: exerciseStore.exercises)?.title ?? ""), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack(spacing: NAVIGATION_BAR_SPACING) {
                iOS13_3.map { // otherwise crashes when going back on iOS 13.2.2
                    workoutRoutineExercise.exercise(in: exerciseStore.exercises).map {
                        NavigationLink(destination: ExerciseDetailView(exercise: $0)) {
                                Image(systemName: "info.circle")
                                    .padding([.leading, .top, .bottom])
                        }
                    }
                }
                EditButton()
            }
        )
        .onDisappear {
            self.managedObjectContext.safeSave()
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
struct WorkoutRoutineExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutRoutineExerciseView(workoutRoutineExercise: MockWorkoutData.metric.workoutRoutineExercise)
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
