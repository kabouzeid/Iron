//
//  AddExercisesSheet.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 03.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit
import CoreData

struct AddExercisesSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    let onAdd: (Set<Exercise>) -> Void
    
    @ObservedObject private var filter: ExerciseGroupFilter
    
    @State private var exerciseSelectorSelection: Set<Exercise> = Set()
    
    init(exercises: [Exercise], recentExercises: [Exercise], onAdd: @escaping (Set<Exercise>) -> Void) {
        let recentExercisesGroup = ExerciseGroup(title: "Recent", exercises: recentExercises)
        let exerciseGroups = ExerciseStore.splitIntoMuscleGroups(exercises: exercises)
        self.filter = ExerciseGroupFilter(exerciseGroups: recentExercisesGroup.exercises.isEmpty ? exerciseGroups : [recentExercisesGroup] + exerciseGroups)
        self.onAdd = onAdd
    }
    
    private func resetAndDismiss() {
        self.presentationMode.wrappedValue.dismiss()
        self.exerciseSelectorSelection.removeAll()
        self.filter.filter = ""
    }
    
    static func loadRecentExercises(context: NSManagedObjectContext, exercises: [Exercise], maxCount: Int = 7) -> [Exercise] {
        guard maxCount > 0 else { return [] }
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) != %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        guard let workouts = try? context.fetch(request) else { return [] }
        var recentExercises = [Exercise]()
        for workout in workouts {
            if let workoutExercises = workout.workoutExercises?.array as? [WorkoutExercise] {
                for workoutExercise in workoutExercises {
                    if let exercise = workoutExercise.exercise(in: exercises) {
                        if !recentExercises.contains(exercise) {
                            recentExercises.append(exercise)
                            if recentExercises.count >= maxCount {
                                return recentExercises
                            }
                        }
                    }
                }
            }
        }
        return recentExercises
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                SheetBar(title: "Add Exercises",
                    leading:
                    Button("Cancel") {
                        self.resetAndDismiss()
                    },
                    trailing:
                    Button("Add") {
                        self.onAdd(self.exerciseSelectorSelection)
                        self.resetAndDismiss()
                    }
                    .environment(\.isEnabled, !self.exerciseSelectorSelection.isEmpty)
                )
                TextField("Search", text: $filter.filter)
                    .textFieldStyle(SearchTextFieldStyle(text: $filter.filter))
                    .padding(.top)
            }.padding()
            
            ExerciseMultiSelectionView(exerciseGroups: filter.exerciseGroups, selection: self.$exerciseSelectorSelection)
        }
    }
}

struct AddExercisesSheet_Previews: PreviewProvider {
    static var previews: some View {
//        Color.clear.sheet(isPresented: .constant(true)) {
        AddExercisesSheet(
            exercises: ExerciseStore.shared.shownExercises,
            recentExercises: [],
            onAdd: { _ in }
        )
//        }
    }
}
