//
//  ActiveWorkoutViewExerciseSection.swift
//  Iron
//
//  Created by Karim Abou Zeid on 09.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

extension WorkoutView {
    struct ExerciseSection: View {
        let workoutExerciseInfo: WorkoutView.WorkoutInfo.WorkoutExerciseInfo
        let selectedWorkoutSetID: WorkoutSet.ID.Wrapped?
        let onSelect: (WorkoutSet.ID.Wrapped) -> Void
        let onAddWorkoutSet: () -> Void
        let onDeleteWorkoutExercise: () -> Void
        let onDeleteWorkoutSets: ([WorkoutSet.ID.Wrapped]) -> Void
        
        @State private var showExerciseDetails = false
        
        var body: some View {
            ForEach(1...1, id: \.self) { _ in // hack to get `onDelete`
                Menu {
                    Section {
                        Button {
                            // TODO
                        } label: {
                            Label("Move", systemImage: "arrow.triangle.swap")
                        }
                        
                        Button {
                            // TODO
                        } label: {
                            Label("Replace", systemImage: "arrow.left.arrow.right")
                        }
                        
                        Button(role: .destructive) {
                            // TODO
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    
                    Section {
                        Button {
                            // TODO
                        } label: {
                            Label("Add Note", systemImage: "square.and.pencil")
                        }
                        
                        Button {
                            showExerciseDetails = true
                        } label: {
                            Label("Details", systemImage: "info.circle")
                        }
                    }
                } label: {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        NavigationLink(isActive: $showExerciseDetails) {
                            ExerciseDetailView(exerciseID: workoutExerciseInfo.exercise.id!)
                        } label: {
                            EmptyView()
                        }
                        .frame(width: 0, height: 0)
                        .hidden()
                        
                        Spacer()
                        
                        Image(systemName: "ellipsis")
                    }
                }
//                .listRowSeparator(.hidden) // visual glitches witht this enabled (iOS 15.4)
            }
            .onDelete { _ in deleteWorkoutExercise() }
            
            ForEach(workoutSets, id: \.workoutSet.id) { workoutSet in
                Button {
                    if workoutSet.state != .pending {
                        select(workoutSet: workoutSet)
                    }
                } label: {
                    WorkoutView.SetCell(viewModel: workoutSet)
                        .id(workoutSet.workoutSet.id!)
                }
                .foregroundColor(.primary)
                .buttonStyle(.borderless)
            }
            .onDelete { indices in
                deleteWorkoutSets(at: indices)
            }
            
            Button {
                onAddWorkoutSet()
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Set")
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button {
                            // TODO
                        } label: {
                            //                            Text("\(lastIndex)")
                            //                                .hidden()
                            //                                .overlay(
                            Label("History", systemImage: "clock.arrow.circlepath")
                                .labelStyle(.iconOnly)
                            //                                )
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }
}

extension WorkoutView.ExerciseSection {
    var title: String {
        workoutExerciseInfo.exercise.title
    }
    
    var workoutSets: [WorkoutView.SetCell.ViewModel] {
        let nextIndex = workoutExerciseInfo.workoutSets.firstIndex { $0.isCompleted == false } ?? workoutExerciseInfo.workoutSets.count
        return workoutExerciseInfo.workoutSets.enumerated().map { (index, workoutSet) in
                .init(
                    workoutSet: workoutSet,
                    exerciseCategory: workoutExerciseInfo.exercise.category,
                    index: index + 1,
                    state: index == nextIndex ? .next : (workoutSet.isCompleted ? .completed : .pending),
                    isSelected: selectedWorkoutSetID == workoutSet.id!,
                    isPersonalRecord1RM: false, // TODO
                    isPersonalRecordWeight: false, // TODO
                    isPersonalRecordVolume: false // TODO
                )
        }
    }
    
    var lastIndex: Int {
        workoutExerciseInfo.workoutSets.count
    }
    
    func select(workoutSet: WorkoutView.SetCell.ViewModel) {
        self.onSelect(workoutSet.workoutSet.id!)
    }
    
    func deleteWorkoutExercise() {
        onDeleteWorkoutExercise()
    }
    
    func deleteWorkoutSets(at indices: IndexSet) {
        let ids = indices.map { workoutExerciseInfo.workoutSets[$0].id! }
        onDeleteWorkoutSets(ids)
    }
}

import IronData

struct ActiveWorkoutViewExerciseCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section {
                WorkoutView.ExerciseSection(
                    workoutExerciseInfo: workoutExerciseInfo,
                    selectedWorkoutSetID: workoutExerciseInfo.workoutSets.last?.id!,
                    onSelect: { _ in },
                    onAddWorkoutSet: { },
                    onDeleteWorkoutExercise: { },
                    onDeleteWorkoutSets: { _ in }
                )
            }
        }
    }
    
    static var workoutExerciseInfo: WorkoutView.WorkoutInfo.WorkoutExerciseInfo {
        var exercise = Exercise.new(title: "Bench Press: Barbell", category: .barbell)
        exercise.bodyPart = .chest
        exercise.id = 0
        var workoutExercise = WorkoutExercise.new(exerciseId: 0, workoutId: 0)
        workoutExercise.id = 0
        
        var workoutSet1 = WorkoutSet.new(workoutExerciseId: 0)
        workoutSet1.id = 0
        workoutSet1.weight = 100
        workoutSet1.repetitions = 5
        workoutSet1.isCompleted = true
        
        var workoutSet2 = WorkoutSet.new(workoutExerciseId: 0)
        workoutSet2.id = 1
        workoutSet2.weight = 140
        workoutSet2.repetitions = 5
        workoutSet2.isCompleted = true
        
        return .init(workoutExercise: workoutExercise, exercise: exercise, workoutSets: [workoutSet1, workoutSet2])
    }
}
