//
//  ActiveWorkoutView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 09.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: ViewModel
    
    @State private var inputTitle: String = ""
    @State private var inputNotes: String = ""
    @State private var showNotesEditor = false
    
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollViewProxy in
                VStack(spacing: 0) {
                    List {
                        Section {
                            TextField("Title", text: $inputTitle)
                                .onSubmit { Task { try await viewModel.setTitle(inputTitle) } }
                            
                            NavigationLink(isActive: $showNotesEditor) {
                                TextEditor(text: $inputNotes)
                                    .navigationTitle("Notes")
                                    .scenePadding()
                            } label: {
                                Text(viewModel.notes ?? "Notes")
                                    .foregroundColor(viewModel.notes == nil ? Color(uiColor: .tertiaryLabel) : .primary)
                                    .disabled(true)
                            }
                            .onChange(of: showNotesEditor) { isShown in
                                if !isShown {
                                    Task { try await viewModel.setNotes(inputNotes) }
                                }
                            }
                        }
                        
                        ForEach(viewModel.workoutExerciseInfos) { workoutExerciseInfo in
                            Section {
                                ExerciseSection(viewModel: .init(
                                    workoutExerciseInfo: workoutExerciseInfo,
                                    selectedWorkoutSetID: viewModel.selectedWorkoutSet?.id!,
                                    onSelect: { workoutSetID in
                                        viewModel.select(workoutSetID: workoutSetID)
                                    },
                                    onAddWorkoutSet: {
                                        viewModel.addWorkoutSet(to: workoutExerciseInfo)
                                    },
                                    onDeleteWorkoutExercise: {
                                        viewModel.deleteWorkoutExercise(id: workoutExerciseInfo.workoutExercise.id!)
                                    },
                                    onDeleteWorkoutSets: { ids in
                                        viewModel.deleteWorkoutSets(ids: ids)
                                    }
                                ))
                            }
                        }
                        
                        Button {
                            viewModel.finish()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Finish Workout")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .onChange(of: viewModel.selectedWorkoutSetID) { id in
                        withAnimation {
                            scrollViewProxy.scrollTo(id, anchor: .center)
                        }
                    }
                    
                    if let viewModel = viewModel.workoutSetEditorViewModel {
                        Divider()
                        WorkoutSetEditor(viewModel: viewModel)
                    }
                }
            }
            //            .navigationTitle(viewModel.title)
            .navigationTitle("48:32")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        
                    } label: {
                        HStack {
                            Image(systemName: "timer")
                            Text("1:19")
                                .font(Font.body.monospacedDigit())
                        }
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Section {
                            Button {
                                // TODO
                            } label: {
                                Label("Reorder", systemImage: "arrow.triangle.swap")
                            }
                            
                            Button {
                                
                            } label: {
                                Label("Start/End Time", systemImage: "clock")
                            }
                        }
                        
                        Button {
                            // TODO
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive) {
                            // TODO
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .task {
            try? await viewModel.fetchData(dismiss: {
                dismiss()
            })
        }
    }
}

extension ActiveWorkoutView {
    init(workout: Workout) {
        self.init(viewModel: .init(database: .shared, settingsStore: .shared, workout: workout))
    }
}

import GRDB
import IronData

extension ActiveWorkoutView {
    @MainActor
    class ViewModel: ObservableObject {
        private let database: AppDatabase
        private let settingsStore: SettingsStore
        
        nonisolated init(database: AppDatabase, settingsStore: SettingsStore, workout: Workout) {
            self.database = database
            self.settingsStore = settingsStore
            self._workoutInfo = Published(initialValue: .init(workout: workout, workoutExerciseInfos: []))
        }
        
        var title: String {
            workoutInfo.workout.displayTitle(infos: workoutInfo.workoutExerciseInfos.map { ($0.exercise, $0.workoutSets) })
        }
        
        var notes: String? {
            workoutInfo.workout.comment
        }
        
        var workoutExerciseInfos: [WorkoutInfo.WorkoutExerciseInfo] {
            workoutInfo.workoutExerciseInfos
        }
        
        // MARK: - Workout Info
        
        @Published var workoutInfo: WorkoutInfo
        
        public struct WorkoutInfo: Decodable, FetchableRecord, Equatable {
            public var workout: Workout
            public var workoutExerciseInfos: [WorkoutExerciseInfo]
            
            public struct WorkoutExerciseInfo: Decodable, FetchableRecord, Equatable, Identifiable {
                public var workoutExercise: WorkoutExercise
                public var exercise: Exercise
                public var workoutSets: [WorkoutSet]
                
                public var id: WorkoutExercise.ID { workoutExercise.id }
            }
            
            static func allActive() -> QueryInterfaceRequest<WorkoutInfo> {
                Workout
                    .filter(Workout.Columns.isActive == true)
                    .order(Workout.Columns.id) // in case there is a bug and there are multiple active workouts
                    .including(all: Workout.workoutExercises
                        .forKey(CodingKeys.workoutExerciseInfos)
                        .including(all: WorkoutExercise.workoutSets)
                        .including(required: WorkoutExercise.exercise)
                    )
                    .orderByStart()
                    .asRequest(of: WorkoutInfo.self)
            }
        }
        
        private func workoutInfoStream() -> AsyncValueObservation<WorkoutInfo?> {
            ValueObservation.tracking(WorkoutInfo.allActive().fetchOne)
                .values(in: database.databaseReader, scheduling: .immediate)
        }
        
        func fetchData(dismiss: () -> Void) async throws {
            for try await workoutInfo in workoutInfoStream() {
                guard let workoutInfo = workoutInfo else {
                    dismiss()
                    return
                }
                
                let updatedDatabase = try await initWorkoutSets(database: database, workoutInfo: workoutInfo)
                
                if !updatedDatabase {
                    withAnimation {
                        self.workoutInfo = workoutInfo
                    }
                }
            }
        }
        
        private func initWorkoutSets(database: AppDatabase, workoutInfo: WorkoutInfo) async throws -> Bool {
            var updatedWorkoutSets = [WorkoutSet]()
            for workoutExerciseInfo in workoutInfo.workoutExerciseInfos {
                let nextIndex = workoutExerciseInfo.workoutSets.firstIndex { !$0.isCompleted }
                guard let nextIndex = nextIndex else { continue }
                let workoutSet = workoutExerciseInfo.workoutSets[nextIndex]
                guard workoutSet.weight == nil && workoutSet.repetitions == nil else { continue } // both nil
                
                let prediction = try await database.databaseReader.read { db in
                    try workoutSet.weightAndRepetitionsFromPreviousSet(db, info: (
                        previousWorkoutSets: Array(workoutExerciseInfo.workoutSets[0..<nextIndex]),
                        workoutExercise: workoutExerciseInfo.workoutExercise,
                        workout: workoutInfo.workout
                    ))
                }
                let weight: Double?
                let repetitions: Int?
                
                if let prediction = prediction, prediction.weight != nil || prediction.repetitions != nil {
                    weight = prediction.weight
                    repetitions = prediction.repetitions
                } else if nextIndex > 0 {
                    let previousWorkoutSet = workoutExerciseInfo.workoutSets[nextIndex - 1]
                    weight = previousWorkoutSet.weight
                    repetitions = previousWorkoutSet.repetitions
                } else {
                    weight = 20 // TODO: proper initial weight
                    repetitions = 5
                }
                
                var updatedWorkoutSet = workoutSet
                updatedWorkoutSet.weight = weight
                updatedWorkoutSet.repetitions = repetitions
                updatedWorkoutSets.append(updatedWorkoutSet)
            }
            
            try await database.saveWorkoutSets(&updatedWorkoutSets)
            
            return updatedWorkoutSets.count > 0
        }
        
        // MARK: - Selected Set
        
        @Published var selectedWorkoutSetID: WorkoutSet.ID.Wrapped?
        
        var selectedWorkoutSet: WorkoutSet? {
            guard let id = selectedWorkoutSetID, let index = indexForWorkoutSet(id: id) else { return nil }
            return workoutExerciseInfos[index[0]].workoutSets[index[1]]
        }
        
        func select(workoutSetID: WorkoutSet.ID.Wrapped) {
            withAnimation {
                if workoutSetID == selectedWorkoutSetID {
                    selectedWorkoutSetID = nil
                } else {
                    selectedWorkoutSetID = workoutSetID
                }
            }
        }
        
        // MARK: - Set Editor
        
        private func indexForWorkoutSet(id: WorkoutSet.ID.Wrapped) -> IndexPath? {
            for (i, workoutExericseInfo) in workoutExerciseInfos.enumerated() {
                for (j, workoutSet) in workoutExericseInfo.workoutSets.enumerated() {
                    if workoutSet.id! == id {
                        return [i,j]
                    }
                }
            }
            return nil
        }
        
        var workoutSetEditorViewModel: WorkoutSetEditor.ViewModel? {
            guard let id = selectedWorkoutSetID else { return nil }
            guard let index = indexForWorkoutSet(id: id) else { return nil }
            var workoutSet = workoutExerciseInfos[index[0]].workoutSets[index[1]]
            let exerciseCategory = workoutExerciseInfos[index[0]].exercise.category
            
            return .init(
                workoutSet: Binding(get: { workoutSet }, set: { self.updateWorkoutSet($0) }),
                exerciseCategory: exerciseCategory,
                massFormat: settingsStore.massFormat,
                onDone: {
                    if !workoutSet.isCompleted {
                        workoutSet.isCompleted = true
                        self.updateWorkoutSet(workoutSet)
                    }
                    self.selectNextWorkoutSet()
                },
                onHide: {
                    withAnimation {
                        self.selectedWorkoutSetID = nil
                    }
                }
            )
        }
        
        /// save a workout set and update the local model immediately
        private func updateWorkoutSet(_ updatedWorkoutSet: WorkoutSet) {
            // optimistically already modify the local data to avoid visual glitches
            guard let index = indexForWorkoutSet(id: updatedWorkoutSet.id!) else { return }
            workoutInfo.workoutExerciseInfos[index[0]].workoutSets[index[1]] = updatedWorkoutSet
            
            // after save the data will be reloaded
            Task {
                var workoutSet = updatedWorkoutSet
                try await database.saveWorkoutSet(&workoutSet)
            }
        }
        
        // MARK: - Actions
        
        func setTitle(_ title: String) async throws {
            let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            var workout = workoutInfo.workout
            workout.title = title.isEmpty ? nil : title
            try await database.saveWorkout(&workout)
        }
        
        func setNotes(_ notes: String) async throws {
            let notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            var workout = workoutInfo.workout
            workout.comment = notes.isEmpty ? nil : notes
            try await database.saveWorkout(&workout)
        }
        
        func deleteWorkoutExercise(id: WorkoutExercise.ID.Wrapped) {
            Task { try await database.deleteWorkoutExercises(ids: [id]) }
        }
        
        func deleteWorkoutSets(ids: [WorkoutSet.ID.Wrapped]) {
            Task { try await database.deleteWorkoutSets(ids: ids) }
        }
        
        func addWorkoutSet(to workoutExerciseInfo: WorkoutInfo.WorkoutExerciseInfo) {
            Task {
                var workoutSets = workoutExerciseInfo.workoutSets
                workoutSets.append(WorkoutSet.new(workoutExerciseId: workoutExerciseInfo.workoutExercise.id!))
                try await database.saveWorkoutSetsOrdered(&workoutSets)
            }
        }
        
        private func selectNextWorkoutSet() {
            guard let id = selectedWorkoutSetID, let index = indexForWorkoutSet(id: id) else { return }
            
            guard let nextWorkoutSet = workoutExerciseInfos[index[0]]
                .workoutSets[index[1]...]
                .first(where: { workoutSet in
                    !workoutSet.isCompleted
                })
            else {
                withAnimation {
                    selectedWorkoutSetID = nil
                }
                return
            }
            
            withAnimation {
                selectedWorkoutSetID = nextWorkoutSet.id!
            }
        }
        
        func finish() {
            Task {
                var workout = workoutInfo.workout
                workout.end = Date()
                workout.isActive = false
                try await database.saveWorkout(&workout)
            }
            
            // TODO: properly finish
            // 1. clean up sets
            // 2. watch companion, health etc
        }
    }
}

struct ActiveWorkoutView_Previews: PreviewProvider {
    static let database = AppDatabase.random()
    static var previews: some View {
        ActiveWorkoutView(viewModel: .init(
            database: database,
            settingsStore: .shared,
            workout: try! database.databaseReader.read { db in try Workout.fetchOne(db)! }
        ))
    }
}
