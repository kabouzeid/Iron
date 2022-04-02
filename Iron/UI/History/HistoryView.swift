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
    @StateObject var viewModel: ViewModel = ViewModel(database: AppDatabase.shared)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.workoutInfos) { workoutInfo in
                        Section {
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
            .navigationBarItems(trailing:
                                    Button {
                try! AppDatabase.shared.createRandomWorkouts()
            } label: {
                Text("reset")
            }
            )
            
            // Double Column Placeholder (iPad)
            Text("No workout selected")
                .foregroundColor(.secondary)
        }
        .navigationViewStyle(.stack)
        .task { try? await viewModel.fetchData() }
    }
}

import Combine
extension HistoryView {
    @MainActor
    class ViewModel: ObservableObject {
        let database: AppDatabase
        
        @Published var workoutInfos: [AppDatabase.WorkoutInfo] = []
        @Published var deletionWorkout: Workout?
        @Published private var bodyWeights: [Date : Double] = [:]
        @Published private var personalRecordInfos: [Workout.ID.Wrapped : PersonalRecordInfo] = [:]
        
        var personalRecordsStaleSubject = PassthroughSubject<Void, Never>() // sent whenever views should refetch PRs
        
        nonisolated init(database: AppDatabase) {
            self.database = database
        }
        
        private func shouldConfirmDelete(workoutInfo: AppDatabase.WorkoutInfo) -> Bool {
            /// returns true if there is at least one completed set
            return workoutInfo.workoutExerciseInfos.contains { workoutExerciseInfo in
                workoutExerciseInfo.workoutSets.contains { workoutSet in
                    workoutSet.isCompleted
                }
            }
        }
        
        func delete(workout: Workout) {
            Task {
                try! await database.deleteWorkouts(ids: [workout.id!])
            }
        }
        
        func confirmDelete(workoutInfo: AppDatabase.WorkoutInfo) {
            if shouldConfirmDelete(workoutInfo: workoutInfo) {
                deletionWorkout = workoutInfo.workout
            } else {
                delete(workout: workoutInfo.workout)
            }
        }
        
        func fetchData() async throws {
            for try await workoutInfos in database.workoutInfos() {
                withAnimation {
                    self.workoutInfos = workoutInfos
                }
                personalRecordsStaleSubject.send()
            }
        }
        
        func fetchBodyWeight(for workoutInfo: AppDatabase.WorkoutInfo) async throws {
            let date = workoutInfo.workout.start
            guard bodyWeights[date] == nil else { return } // save power/performance by only loading the bodyweight once from HK
            let bodyWeight = try await HealthManager.shared.healthStore.fetchBodyWeight(date: date)
            withAnimation {
                bodyWeights[date] = bodyWeight
            }
        }
        
        func bodyWeight(for workoutInfo: AppDatabase.WorkoutInfo) -> Double? {
            bodyWeights[workoutInfo.workout.start]
        }
        
        typealias PersonalRecordInfo = [WorkoutExercise.ID.Wrapped : Bool]
        
        func fetchPRInfo(for workoutInfo: AppDatabase.WorkoutInfo) async throws {
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
        
        func prInfo(for workoutInfo: AppDatabase.WorkoutInfo) -> PersonalRecordInfo? {
            personalRecordInfos[workoutInfo.workout.id!]
        }
        
        func share(workoutInfo: AppDatabase.WorkoutInfo) {
            // TODO
            //            guard let logText = workout.logText(in: self.exerciseStore.exercises, weightUnit: self.settingsStore.weightUnit) else { return }
            //            self.activityItems = [logText]
        }
        
        func `repeat`(workoutInfo: AppDatabase.WorkoutInfo) {
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
