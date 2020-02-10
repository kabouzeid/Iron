//
//  WorkoutPlanView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct WorkoutPlanView: View {
    @EnvironmentObject var exerciseStore: ExerciseStore
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var workoutPlan: WorkoutPlan
    
    @ObservedObject private var workoutPlanTitleInput = ValueHolder<String?>(initial: nil)
    private var workoutPlanTitle: Binding<String> {
        Binding(
            get: {
                self.workoutPlanTitleInput.value ?? self.workoutPlan.title ?? ""
            },
            set: { newValue in
                self.workoutPlanTitleInput.value = newValue
            }
        )
    }
    private func adjustAndSaveWorkoutTitleInput() {
        guard let newValue = workoutPlanTitleInput.value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        if newValue.isEmpty {
            workoutPlanTitleInput.value = nil
        } else {
            workoutPlanTitleInput.value = newValue
            workoutPlan.title = newValue
        }
    }
    
    private var workoutRoutines: [WorkoutRoutine] {
        workoutPlan.workoutRoutines?.array as? [WorkoutRoutine] ?? []
    }
    
    private func workoutRoutineExercises(workoutRoutine: WorkoutRoutine) -> [WorkoutRoutineExercise] {
        workoutRoutine.workoutRoutineExercises?.array as? [WorkoutRoutineExercise] ?? []
    }
    
    private func workoutRoutineExercisesString(workoutRoutine: WorkoutRoutine) -> String {
        workoutRoutineExercises(workoutRoutine: workoutRoutine)
            .compactMap { $0.exercise(in: self.exerciseStore.exercises)?.title }
            .joined(separator: ", ")
    }
    
    var body: some View {
        List {
            Section {
                TextField("Title", text: workoutPlanTitle, onEditingChanged: { isEditingTextField in
                    if !isEditingTextField {
                        self.adjustAndSaveWorkoutTitleInput()
                    }
                })
            }
            Section(header: Text("Routines".uppercased())) {
                ForEach(workoutRoutines, id: \.objectID) { workoutRoutine in
                    NavigationLink(destination: Text("TODO")) {
                        VStack(alignment: .leading) {
                            Text(workoutRoutine.title ?? "")
                            Text(self.workoutRoutineExercisesString(workoutRoutine: workoutRoutine))
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                .onDelete { offsets in
                    let workoutRoutines = self.workoutRoutines
                    for i in offsets {
                        let workoutRoutine = workoutRoutines[i]
                        self.managedObjectContext.delete(workoutRoutine)
                        workoutRoutine.workoutPlan?.removeFromWorkoutRoutines(workoutRoutine)
                    }
                }
                .onMove { source, destination in
                    var workoutRoutines = self.workoutRoutines
                    workoutRoutines.move(fromOffsets: source, toOffset: destination)
                    self.workoutPlan.workoutRoutines = NSOrderedSet(array: workoutRoutines)
                }
                
                Button(action: {
                    #warning("TODO add routine sheet")
//                    self.activeSheet = .exerciseSelector
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Routine")
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text(workoutPlan.title ?? ""), displayMode: .inline)
        .navigationBarItems(trailing: EditButton())
    }
}

#if DEBUG
struct WorkoutPlanView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutPlanView(workoutPlan: MockWorkoutData.metric.workoutPlan)
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
