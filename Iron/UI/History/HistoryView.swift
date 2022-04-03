//
//  HistoryView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 24.03.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import IronData

struct HistoryView: View {
    @StateObject var viewModel: ViewModel = ViewModel(database: .shared)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.workoutInfos) { workoutInfo in
                        NavigationLink {
                            Text("TODO")
                        } label: {
                            WorkoutCell(viewModel: .init(
                                workoutInfo: workoutInfo,
                                personalRecordInfo: viewModel.prInfo(for: workoutInfo),
                                bodyWeight: viewModel.bodyWeight(for: workoutInfo)
                            ))
                            .contentShape(Rectangle())
                            .onChange(of: workoutInfo, perform: { newWorkoutInfo in
                                Task { try await viewModel.fetchBodyWeight(for: newWorkoutInfo) }
                            })
                            .onReceive(viewModel.personalRecordsStaleSubject, perform: {
                                Task { try await viewModel.fetchPRInfo(for: workoutInfo) }
                            })
                            .task { try? await viewModel.fetchBodyWeight(for: workoutInfo) }
                            .task { try? await viewModel.fetchPRInfo(for: workoutInfo) }
                        }
                        .buttonStyle(.plain)
                        .scenePadding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .contextMenu {
                            Button {
                                viewModel.share(workoutInfo: workoutInfo)
                            } label: {
                                Text("Share")
                                Image(systemName: "square.and.arrow.up")
                            }
                            
                            Button {
                                viewModel.repeat(workoutInfo: workoutInfo)
                            } label: {
                                Text("Repeat")
                                Image(systemName: "arrow.clockwise")
                            }
                            
                            Button(role: .destructive) {
                                viewModel.confirmDelete(workoutInfo: workoutInfo)
                            } label: {
                                Text("Delete")
                                Image(systemName: "trash")
                            }
                            
                        }
                    }
                }
                .scenePadding(.horizontal)
            }
            .actionSheet(item: $viewModel.deletionWorkout) { workout in
                ActionSheet(title: Text("This cannot be undone."), buttons: [
                    .destructive(Text("Delete Workout"), action: {
                        viewModel.delete(workout: workout)
                    }),
                    .cancel()
                ])
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .placeholder(show: viewModel.workoutInfos.isEmpty, Text("Your finished workouts will appear here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            )
            .navigationBarTitle(Text("History"))
            
            // Double Column Placeholder (iPad)
            Text("No workout selected")
                .foregroundColor(.secondary)
        }
        .navigationViewStyle(.stack)
        .task { try? await viewModel.fetchData() }
    }
}

import Combine
import GRDB

extension HistoryView {
    @MainActor
    class ViewModel: ObservableObject {
        let database: AppDatabase
        nonisolated init(database: AppDatabase) {
            self.database = database
        }
        
        // MARK: - Workout Infos
        
        @Published var workoutInfos: [WorkoutInfo] = []
        
        public struct WorkoutInfo: Decodable, FetchableRecord, Equatable, Identifiable {
            public var workout: Workout
            public var workoutExerciseInfos: [WorkoutExerciseInfo]
            
            public var id: Workout.ID { workout.id }
            
            public struct WorkoutExerciseInfo: Decodable, FetchableRecord, Equatable {
                public var workoutExercise: WorkoutExercise
                public var exercise: Exercise
                public var workoutSets: [WorkoutSet]
            }
            
            static func all() -> QueryInterfaceRequest<WorkoutInfo> {
                Workout.including(all: Workout.workoutExercises
                    .forKey(CodingKeys.workoutExerciseInfos)
                    .including(all: WorkoutExercise.workoutSets)
                    .including(required: WorkoutExercise.exercise)
                )
                .orderByStart()
                .asRequest(of: WorkoutInfo.self)
            }
        }
        
        private func workoutInfosStream() -> AsyncValueObservation<[WorkoutInfo]> {
            ValueObservation.tracking(WorkoutInfo.all().fetchAll)
                .values(in: database.databaseReader, scheduling: .immediate)
        }
        
        func fetchData() async throws {
            for try await workoutInfos in workoutInfosStream() {
                withAnimation {
                    self.workoutInfos = workoutInfos
                }
                personalRecordsStaleSubject.send()
            }
        }
        
        // MARK: - Body Weight
        
        @Published private var bodyWeights: [Date : Measurement<UnitMass>] = [:]
        
        func fetchBodyWeight(for workoutInfo: WorkoutInfo) async throws {
            let date = workoutInfo.workout.start
            guard bodyWeights[date] == nil else { return } // save power/performance by only loading the bodyweight once from HK
            let bodyWeight = try await HealthManager.shared.healthStore.fetchBodyWeight(date: date)
            withAnimation {
                bodyWeights[date] = bodyWeight
            }
        }
        
        func bodyWeight(for workoutInfo: WorkoutInfo) -> Measurement<UnitMass>? {
            bodyWeights[workoutInfo.workout.start]
        }
        
        // MARK: - Personal Records
        
        @Published private var personalRecordInfos: [Workout.ID.Wrapped : PersonalRecordInfo] = [:]
        var personalRecordsStaleSubject = PassthroughSubject<Void, Never>() // sent whenever views should refetch PRs
        
        typealias PersonalRecordInfo = [WorkoutExercise.ID.Wrapped : Bool]
        
        func fetchPRInfo(for workoutInfo: WorkoutInfo) async throws {
            // NOTE: for now we don't return the cached value
            // if we want to use the cached value here, then we also need to reset the cache in `fetchData`
            // potential downside of this might be flickering everytime we reset the cache
            
            let prInfo = try await database.databaseReader.read { db -> PersonalRecordInfo in
                var map = PersonalRecordInfo()
                for workoutExerciseInfo in workoutInfo.workoutExerciseInfos {
                    map[workoutExerciseInfo.workoutExercise.id!] = try workoutExerciseInfo.workoutSets.contains { workoutSet in
                        try workoutSet.isPersonalRecord(db, info: (workoutExercise: workoutExerciseInfo.workoutExercise, workout: workoutInfo.workout))
                    }
                }
                return map
            }
            withAnimation {
                personalRecordInfos[workoutInfo.workout.id!] = prInfo
            }
        }
        
        func prInfo(for workoutInfo: WorkoutInfo) -> PersonalRecordInfo? {
            personalRecordInfos[workoutInfo.workout.id!]
        }
        
        // MARK: - Actions
        
        @Published var deletionWorkout: Workout?
        
        func delete(workout: Workout) {
            Task {
                try! await database.deleteWorkouts(ids: [workout.id!])
            }
        }
        
        private func shouldConfirmDelete(workoutInfo: WorkoutInfo) -> Bool {
            /// returns true if there is at least one completed set
            return workoutInfo.workoutExerciseInfos.contains { workoutExerciseInfo in
                workoutExerciseInfo.workoutSets.contains { workoutSet in
                    workoutSet.isCompleted
                }
            }
        }
        
        func confirmDelete(workoutInfo: WorkoutInfo) {
            if shouldConfirmDelete(workoutInfo: workoutInfo) {
                deletionWorkout = workoutInfo.workout
            } else {
                delete(workout: workoutInfo.workout)
            }
        }
        
        func share(workoutInfo: WorkoutInfo) {
            // TODO
            //            guard let logText = workout.logText(in: self.exerciseStore.exercises, weightUnit: self.settingsStore.weightUnit) else { return }
            //            self.activityItems = [logText]
        }
        
        func `repeat`(workoutInfo: WorkoutInfo) {
            // TODO
            //            WorkoutDetailView.repeatWorkout(workout: workout, settingsStore: self.settingsStore, sceneState: sceneState)
        }
    }
}

#if DEBUG
struct HistoryView_Previews : PreviewProvider {
    static var previews: some View {
        TabView {
            HistoryView(viewModel: .init(database: .random()))
                .mockEnvironment(weightUnit: .metric, isPro: true)
        }
    }
}
#endif
