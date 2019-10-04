//
//  WorkoutDetailView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct WorkoutDetailView : View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    @ObservedObject var workout: Workout

//    @Environment(\.editMode) var editMode
    @State private var showingExerciseSelectorSheet = false

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

    private var workoutExercises: [WorkoutExercise] {
        workout.workoutExercises?.array as? [WorkoutExercise] ?? []
    }
    
    private func workoutSets(workoutExercise: WorkoutExercise) -> [WorkoutSet] {
        workoutExercise.workoutSets?.array as? [WorkoutSet] ?? []
    }
    
    private func workoutExerciseView(workoutExercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading) {
            Text(workoutExercise.exercise(in: self.exerciseStore.exercises)?.title ?? "")
                .font(.body)
            workoutExercise.comment.map {
                Text($0.enquoted)
                    .lineLimit(1)
                    .font(Font.caption.italic())
                    .foregroundColor(.secondary)
            }
            ForEach(self.workoutSets(workoutExercise: workoutExercise), id: \.objectID) { workoutSet in
                Text(workoutSet.logTitle(unit: self.settingsStore.weightUnit))
                    .font(Font.body.monospacedDigit())
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                WorkoutDetailBannerView(workout: workout)
                    .listRowBackground(workout.muscleGroupColor(in: self.exerciseStore.exercises))
                    .environment(\.colorScheme, .dark) // TODO: check whether accent color is actually dark
            }
            
            // editMode still doesn't work in 13.1 beta2
//            if editMode?.wrappedValue == .active {
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
                
                Section {
                    DatePicker(selection: $workout.safeStart, in: ...min(workout.safeEnd, Date())) {
                        Text("Start")
                    }
                    
                    DatePicker(selection: $workout.safeEnd, in: workout.safeStart...Date()) {
                        Text("End")
                    }
                }
//            }

            Section {
                ForEach(workoutExercises, id: \.objectID) { workoutExercise in
                    NavigationLink(destination: WorkoutExerciseDetailView(workoutExercise: workoutExercise).environmentObject(self.settingsStore)) {
                        self.workoutExerciseView(workoutExercise: workoutExercise)
                    }
                }
                .onDelete { offsets in
                    let workoutExercises = self.workoutExercises
                    for i in offsets {
                        let workoutExercise = workoutExercises[i]
                        self.managedObjectContext.delete(workoutExercise)
                        workoutExercise.workout?.removeFromWorkoutExercises(workoutExercise)
                    }
                    self.managedObjectContext.safeSave()
                }
                .onMove { source, destination in
                    guard var workoutExercises = self.workout.workoutExercises?.array as? [WorkoutExercise] else { return }
                    workoutExercises.move(fromOffsets: source, toOffset: destination)
                    self.workout.workoutExercises = NSOrderedSet(array: workoutExercises)
                    self.managedObjectContext.safeSave()
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
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text(workout.displayTitle(in: exerciseStore.exercises)), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack(spacing: NAVIGATION_BAR_SPACING) {
                Button(action: {
                    guard let logText = self.workout.logText(in: self.exerciseStore.exercises, weightUnit: self.settingsStore.weightUnit) else { return }
                    let ac = UIActivityViewController(activityItems: [logText], applicationActivities: nil)
                    // TODO: replace this hack with a proper way to retreive the rootViewController
                    guard let rootVC = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else { return }
                    rootVC.present(ac, animated: true)
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                EditButton()
            }
        )
        .sheet(isPresented: $showingExerciseSelectorSheet) {
            AddExercisesSheet(exercises: self.exerciseStore.exercises, onAdd: { selection in
                for exercise in selection {
                    let workoutExercise = WorkoutExercise(context: self.managedObjectContext)
                    self.workout.addToWorkoutExercises(workoutExercise)
                    workoutExercise.exerciseId = Int16(exercise.id)
                }
                self.managedObjectContext.safeSave()
            })
        }
    }
}

#if DEBUG
struct WorkoutDetailView_Previews : PreviewProvider {
    static var previews: some View {
        WorkoutDetailView(workout: MockWorkoutData.metricRandom.workout)
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
