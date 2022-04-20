//
//  WorkoutView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 09.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import GRDBQuery

struct WorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appDatabase) private var database: AppDatabase
    @EnvironmentObject private var settingsStore: SettingsStore
    
    @Query<WorkoutInfoRequest> private var workoutInfo: WorkoutInfo?
    
    @State private var inputTitle: String = ""
    @State private var inputNotes: String = ""
    @State private var showNotesEditor = false
    
    @State private var selectedWorkoutSet: WorkoutSet?
    
    @State private var shouldSelectNextWorkoutSet = true
    
    init(workoutID: Workout.ID.Wrapped) {
        _workoutInfo = Query(WorkoutInfoRequest(workoutID: workoutID))
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollViewProxy in
                VStack(spacing: 0) {
                    List {
                        Section {
                            TextField("Title", text: $inputTitle)
                                .onSubmit { Task { try await setTitle(inputTitle) } }
                            
                            NavigationLink(isActive: $showNotesEditor) {
                                TextEditor(text: $inputNotes)
                                    .navigationTitle("Notes")
                                    .scenePadding()
                            } label: {
                                Text(notes ?? "Notes")
                                    .foregroundColor(notes == nil ? Color(uiColor: .tertiaryLabel) : .primary)
                                    .disabled(true)
                            }
                            .onChange(of: showNotesEditor) { isShown in
                                if !isShown {
                                    Task { try await setNotes(inputNotes) }
                                }
                            }
                        }
                        
                        if let workoutInfo = workoutInfo {
                            ForEach(workoutInfo.workoutExerciseInfos) { workoutExerciseInfo in
                                Section {
                                    ExerciseSection(
                                        workoutExerciseInfo: workoutExerciseInfo,
                                        selectedWorkoutSetID: selectedWorkoutSet?.id!,
                                        onSelect: { workoutSetID in
                                            select(workoutSetID: workoutSetID)
                                        },
                                        onAddWorkoutSet: {
                                            addWorkoutSet(to: workoutExerciseInfo)
                                        },
                                        onDeleteWorkoutExercise: {
                                            deleteWorkoutExercise(id: workoutExerciseInfo.workoutExercise.id!)
                                        },
                                        onDeleteWorkoutSets: { ids in
                                            deleteWorkoutSets(ids: ids)
                                        }
                                    )
                                }
                            }
                        }
                        
                        if isActive {
                            Button {
                                finish()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark")
                                    Text("Finish Workout")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .onChange(of: selectedWorkoutSet?.id) { id in
                        withAnimation {
                            scrollViewProxy.scrollTo(id, anchor: .center)
                        }
                    }
                    
                    if let viewModel = workoutSetEditorViewModel {
                        Divider()
                        WorkoutSetEditor(viewModel: viewModel)
                    }
                }
            }
            //            .navigationTitle(title)
            .navigationTitle("48:32")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isActive {
                        Button {
                            
                        } label: {
                            HStack {
                                Image(systemName: "timer")
                                Text("1:19")
                                    .font(Font.body.monospacedDigit())
                            }
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
        .onChange(of: workoutInfo) { _ in onWorkoutInfoChanged() }
        .animation(.default, value: selectedWorkoutSet)
    }
}

// MARK: - View Model

import IronData
import GRDB
import Combine

extension WorkoutView {
    var title: String {
        guard let workoutInfo = workoutInfo else { return "" }
        return workoutInfo.workout.displayTitle(infos: workoutInfo.workoutExerciseInfos.map { ($0.exercise, $0.workoutSets) })
    }
    
    var notes: String? {
        workoutInfo?.workout.comment ?? nil
    }
    
    var isActive: Bool {
        workoutInfo?.workout.isActive ?? false
    }
    
    // MARK: - Workout Info
    
    struct WorkoutInfo: Decodable, FetchableRecord, Equatable {
        var workout: Workout
        var workoutExerciseInfos: [WorkoutExerciseInfo]
        
        struct WorkoutExerciseInfo: Decodable, FetchableRecord, Equatable, Identifiable {
            var workoutExercise: WorkoutExercise
            var exercise: Exercise
            var workoutSets: [WorkoutSet]
            
            var id: WorkoutExercise.ID { workoutExercise.id }
        }
        
        static func filter(workoutID: Workout.ID.Wrapped) -> QueryInterfaceRequest<WorkoutInfo> {
            Workout
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
    
    struct WorkoutInfoRequest: Queryable {
        let workoutID: Workout.ID.Wrapped
        
        static var defaultValue: WorkoutInfo? { nil }
        
        func publisher(in database: AppDatabase) -> AnyPublisher<WorkoutInfo?, Error> {
            ValueObservation.tracking(WorkoutInfo.filter(workoutID: workoutID).fetchOne(_:))
                .publisher(in: database.databaseReader, scheduling: .immediate)
                .tryFilter { workoutInfo in
                    guard let workoutInfo = workoutInfo else { return true }
                    let madeChanges = try initWorkoutSets(database: database, workoutInfo: workoutInfo)
                    return !madeChanges
                }
                .eraseToAnyPublisher()
        }
        
        func initWorkoutSets(database: AppDatabase, workoutInfo: WorkoutInfo) throws -> Bool {
            try database.databaseWriter.write { db in
                var madeChanges = false
                for workoutExerciseInfo in workoutInfo.workoutExerciseInfos {
                    let nextIndex = workoutExerciseInfo.workoutSets.firstIndex { !$0.isCompleted }
                    guard let nextIndex = nextIndex else { continue }
                    let workoutSet = workoutExerciseInfo.workoutSets[nextIndex]
                    guard workoutSet.weight == nil && workoutSet.repetitions == nil else { continue } // both nil
                    
                    let prediction = try workoutSet.weightAndRepetitionsFromPreviousSet(db, info: (
                        previousWorkoutSets: Array(workoutExerciseInfo.workoutSets[0..<nextIndex]),
                        workoutExercise: workoutExerciseInfo.workoutExercise,
                        workout: workoutInfo.workout
                    ))
                    
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
                        weight = 20 // TODO: use proper initial weight here
                        repetitions = 5
                    }
                    
                    var updatedWorkoutSet = workoutSet
                    updatedWorkoutSet.weight = weight
                    updatedWorkoutSet.repetitions = repetitions
                    
                    guard updatedWorkoutSet != workoutSet else { continue } // just to be sure
                    try updatedWorkoutSet.save(db)
                    madeChanges = true
                }
                
                return madeChanges
            }
        }
    }
    
    func onWorkoutInfoChanged() {
        guard workoutInfo != nil else {
            dismiss()
            return
        }
        
        if shouldSelectNextWorkoutSet {
            selectNextWorkoutSet()
            shouldSelectNextWorkoutSet = false
        }
    }
    
    // MARK: - Selected Set
    
    func select(workoutSetID: WorkoutSet.ID.Wrapped) {
        guard let workoutInfo = workoutInfo else { return }
        if workoutSetID == selectedWorkoutSet?.id! {
            selectedWorkoutSet = nil
        } else {
            guard let index = indexForWorkoutSet(id: workoutSetID) else { return }
            self.selectedWorkoutSet = workoutInfo.workoutExerciseInfos[index[0]].workoutSets[index[1]]
        }
    }
    
    // MARK: - Set Editor
    
    private func indexForWorkoutSet(id: WorkoutSet.ID.Wrapped) -> IndexPath? {
        guard let workoutInfo = workoutInfo else { return nil }
        for (i, workoutExericseInfo) in workoutInfo.workoutExerciseInfos.enumerated() {
            for (j, workoutSet) in workoutExericseInfo.workoutSets.enumerated() {
                if workoutSet.id! == id {
                    return [i,j]
                }
            }
        }
        return nil
    }
    
    var workoutSetEditorViewModel: WorkoutSetEditor.ViewModel? {
        guard let workoutInfo = workoutInfo else { return nil }
        guard let workoutSet = selectedWorkoutSet else { return nil }
        guard let index = indexForWorkoutSet(id: workoutSet.id!) else { return nil }
        let exerciseCategory = workoutInfo.workoutExerciseInfos[index[0]].exercise.category
        
        return .init(
            workoutSet: Binding(
                get: { workoutSet },
                set: { newWorkoutSet in
                    if selectedWorkoutSet?.id! == newWorkoutSet.id! {
                        selectedWorkoutSet = newWorkoutSet
                    }
                    Task {
                        var workoutSet = newWorkoutSet
                        try await database.saveWorkoutSet(&workoutSet)
                    }
                }
            ),
            exerciseCategory: exerciseCategory,
            massFormat: settingsStore.massFormat,
            onDone: {
                if !workoutSet.isCompleted {
                    Task {
                        var workoutSet = workoutSet
                        workoutSet.isCompleted = true
                        try await database.saveWorkoutSet(&workoutSet)
                        shouldSelectNextWorkoutSet = true
                    }
                } else {
                    selectNextWorkoutSet()
                }
            },
            onHide: {
                selectedWorkoutSet = nil
            }
        )
    }
    
    // MARK: - Actions
    
    func setTitle(_ title: String) async throws {
        guard let workoutInfo = workoutInfo else { return }
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        var workout = workoutInfo.workout
        workout.title = title.isEmpty ? nil : title
        try await database.saveWorkout(&workout)
    }
    
    func setNotes(_ notes: String) async throws {
        guard let workoutInfo = workoutInfo else { return }
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
        guard let workoutInfo = workoutInfo else { return }
        guard let id = selectedWorkoutSet?.id!, let index = indexForWorkoutSet(id: id) else { return }
        
        guard let nextWorkoutSet = workoutInfo.workoutExerciseInfos[index[0]]
            .workoutSets[index[1]...]
            .first(where: { workoutSet in
                !workoutSet.isCompleted
            })
        else {
            selectedWorkoutSet = nil
            return
        }
        
        selectedWorkoutSet = nextWorkoutSet
    }
    
    func finish() {
        guard let workoutInfo = workoutInfo else { return }
        
        enum FinishWorkoutError: Error {
            case workoutNotActive
        }
        
        Task {
            try await database.databaseWriter.write { db in
                guard try Workout.fetchOne(db, id: workoutInfo.workout.id!)?.isActive ?? false else { throw FinishWorkoutError.workoutNotActive }
                
                var workout = workoutInfo.workout
                if workout.end == nil {
                    workout.end = Date()
                }
                workout.isActive = false
                try workout.save(db)
            }
        }
        
        // TODO: properly finish
        // 1. clean up sets
        // 2. watch companion, health etc
    }
    
    //    struct WorkoutRequest: Queryable {
    //        static var defaultValue: [Workout] { [] }
    //
    //        func initial(in database: AppDatabase) throws -> [Workout] {
    //            try database.databaseReader.read(request)
    //        }
    //
    //        func publisher(in database: AppDatabase) -> AnyPublisher<[Workout], Error> {
    //            ValueObservation.tracking(request)
    //                .publisher(in: database.databaseReader)
    //                .eraseToAnyPublisher()
    //        }
    //
    //        // not a protocol requirement
    //        var request: (Database) throws -> [Workout] {
    //            Workout.fetchAll(_:)
    //        }
    //    }
}

//struct ActiveWorkoutView_Previews: PreviewProvider {
//    static var previews: some View {
//        WorkoutView()
//            .environment(\.appDatabase, .random())
//            .environmentObject(SettingsStore.mockMetric)
//    }
//}
