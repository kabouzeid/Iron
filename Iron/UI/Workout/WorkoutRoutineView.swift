//
//  WorkoutRoutineView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 21.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct WorkoutRoutineView: View {
    @EnvironmentObject var exerciseStore: ExerciseStore
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var workoutRoutine: WorkoutRoutine
    
    @State private var showExerciseSelector = false
    
    @ObservedObject private var workoutRoutineTitleInput = ValueHolder<String?>(initial: nil)
    private var workoutRoutineTitle: Binding<String> {
        Binding(
            get: {
                self.workoutRoutineTitleInput.value ?? self.workoutRoutine.title ?? ""
            },
            set: { newValue in
                self.workoutRoutineTitleInput.value = newValue
            }
        )
    }
    private func adjustAndSaveWorkoutRoutineTitleInput() {
        guard let newValue = workoutRoutineTitleInput.value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutRoutineTitleInput.value = newValue
        workoutRoutine.title = newValue.isEmpty ? nil : newValue
    }
    
    @ObservedObject private var workoutRoutineCommentInput = ValueHolder<String?>(initial: nil)
    private var workoutRoutineComment: Binding<String> {
        Binding(
            get: {
                self.workoutRoutineCommentInput.value ?? self.workoutRoutine.comment ?? ""
            },
            set: { newValue in
                self.workoutRoutineCommentInput.value = newValue
            }
        )
    }
    private func adjustAndSaveWorkoutRoutineCommentInput() {
        guard let newValue = workoutRoutineCommentInput.value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutRoutineCommentInput.value = newValue
        workoutRoutine.comment = newValue.isEmpty ? nil : newValue
    }
    
    private var workoutRoutineExercises: [WorkoutRoutineExercise] {
        workoutRoutine.workoutRoutineExercises?.array as? [WorkoutRoutineExercise] ?? []
    }
    
    private var exerciseSelectorSheet: some View {
        AddExercisesSheet(
            exercises: exerciseStore.shownExercises,
            recentExercises: AddExercisesSheet.loadRecentExercises(context: managedObjectContext, exercises: exerciseStore.shownExercises),
            onAdd: { selection in
                for exercise in selection {
                    let workoutRoutineExercise = WorkoutRoutineExercise(context: self.managedObjectContext)
                    workoutRoutineExercise.workoutRoutine = self.workoutRoutine
                    workoutRoutineExercise.exerciseUuid = exercise.uuid
                    // TODO: add default sets?
                }
                self.managedObjectContext.safeSave()
            }
        )
    }
    
    var body: some View {
        List {
            Section {
                TextField("Title", text: workoutRoutineTitle, onEditingChanged: { isEditingTextField in
                    if !isEditingTextField {
                        self.adjustAndSaveWorkoutRoutineTitleInput()
                    }
                })
                TextField("Comment", text: workoutRoutineComment, onEditingChanged: { isEditingTextField in
                    if !isEditingTextField {
                        self.adjustAndSaveWorkoutRoutineCommentInput()
                    }
                })
            }
            Section(header: Text("Exercises".uppercased())) {
                ForEach(workoutRoutineExercises, id: \.objectID) { workoutRoutineExercise in
                    NavigationLink(destination: WorkoutRoutineExerciseView(workoutRoutineExercise: workoutRoutineExercise)) {
                        VStack(alignment: .leading) {
                            Text(workoutRoutineExercise.exercise(in: self.exerciseStore.exercises)?.title ?? "Unknown Exercise")
                            workoutRoutineExercise.subtitle.map {
                                Text($0)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    let workoutRoutineExercises = self.workoutRoutineExercises
                    for i in offsets {
                        let workoutRoutineExercise = workoutRoutineExercises[i]
                        self.managedObjectContext.delete(workoutRoutineExercise)
                        workoutRoutineExercise.workoutRoutine?.removeFromWorkoutRoutineExercises(workoutRoutineExercise)
                    }
                }
                .onMove { source, destination in
                    var workoutRoutineExercises = self.workoutRoutineExercises
                    workoutRoutineExercises.move(fromOffsets: source, toOffset: destination)
                    self.workoutRoutine.workoutRoutineExercises = NSOrderedSet(array: workoutRoutineExercises)
                }

                Button(action: {
                    self.showExerciseSelector = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Exercises")
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text(workoutRoutine.displayTitle), displayMode: .inline)
        .navigationBarItems(trailing: EditButton())
        .sheet(isPresented: self.$showExerciseSelector) {
            self.exerciseSelectorSheet
        }
    }
}

#if DEBUG
struct WorkoutRoutineView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutRoutineView(workoutRoutine: MockWorkoutData.metric.workoutRoutine)
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
