//
//  ActiveWorkoutViewExerciseSection.swift
//  Iron
//
//  Created by Karim Abou Zeid on 09.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

extension ActiveWorkoutView {
    struct ExerciseSection: View {
        let viewModel: ViewModel
        
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
                        Text(viewModel.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        NavigationLink(isActive: $showExerciseDetails) {
                            ExerciseDetailView(exercise: viewModel.workoutExerciseInfo.exercise)
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
            .onDelete { _ in viewModel.deleteWorkoutExercise() }
            
            ForEach(viewModel.workoutSets, id: \.workoutSet.id) { workoutSet in
                Button {
                    if workoutSet.state != .pending {
                        viewModel.select(workoutSet: workoutSet)
                    }
                } label: {
                    ActiveWorkoutView.SetCell(viewModel: workoutSet)
                        .id(workoutSet.workoutSet.id!)
                }
                .foregroundColor(.primary)
            }
            .onDelete { indices in
                viewModel.deleteWorkoutSets(at: indices)
            }
            
            Button {
                viewModel.onAddWorkoutSet()
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Set")
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button {
                            // TODO
                        } label: {
                            //                            Text("\(viewModel.lastIndex)")
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

extension ActiveWorkoutView.ExerciseSection {
    struct ViewModel {
        let workoutExerciseInfo: ActiveWorkoutView.ViewModel.WorkoutInfo.WorkoutExerciseInfo
        let selectedWorkoutSetID: WorkoutSet.ID.Wrapped?
        let onSelect: (WorkoutSet.ID.Wrapped) -> Void
        let onAddWorkoutSet: () -> Void
        let onDeleteWorkoutExercise: () -> Void
        let onDeleteWorkoutSets: ([WorkoutSet.ID.Wrapped]) -> Void
        
        var title: String {
            workoutExerciseInfo.exercise.title
        }
        
        var workoutSets: [ActiveWorkoutView.SetCell.ViewModel] {
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
        
        func select(workoutSet: ActiveWorkoutView.SetCell.ViewModel) {
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
}

import IronData

struct ActiveWorkoutViewExerciseCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section {
                ActiveWorkoutView.ExerciseSection(viewModel: .init(
                    workoutExerciseInfo: workoutExerciseInfo,
                    selectedWorkoutSetID: workoutExerciseInfo.workoutSets.last?.id!,
                    onSelect: { _ in },
                    onAddWorkoutSet: { },
                    onDeleteWorkoutExercise: { },
                    onDeleteWorkoutSets: { _ in }
                ))
            }
        }
    }
    
    static var workoutExerciseInfo: ActiveWorkoutView.ViewModel.WorkoutInfo.WorkoutExerciseInfo {
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
