//
//  WorkoutList.swift
//  Iron
//
//  Created by Karim Abou Zeid on 24.03.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import GRDBQuery

struct WorkoutList: View {
    @Environment(\.appDatabase) private var database: AppDatabase
    @EnvironmentObject private var settingsStore: SettingsStore
    
    @Query(WorkoutInfosRequest(), isAutoupdating: false) private var workoutInfos: [WorkoutInfo]
//    @State private var workoutInfos: [WorkoutInfo] = []
    
    @State private var bodyWeights: [Date : Measurement<UnitMass>] = [:]
    
    @State private var personalRecordInfos: [Workout.ID.Wrapped : PersonalRecordInfo] = [:]
    
    @State private var deletionWorkout: Workout?
    
//    @State private var loading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(workoutInfos) { workoutInfo in
                        NavigationLink {
                            WorkoutView(workoutID: workoutInfo.workout.id!)
                        } label: {
                            WorkoutCell(
                                workoutInfo: workoutInfo,
                                personalRecordInfo: personalRecordInfo(for: workoutInfo),
                                bodyWeight: bodyWeight(for: workoutInfo),
                                massFormat: settingsStore.massFormat
                            )
                            .contentShape(Rectangle())
                            .onChange(of: workoutInfo, perform: { newWorkoutInfo in
                                Task { try await fetchBodyWeight(for: newWorkoutInfo) }
                            })
                            .onChange(of: workoutInfos, perform: { newWorkoutInfos in
                                guard let workoutInfo = newWorkoutInfos.first(where: { $0.id == workoutInfo.id }) else { return }
                                Task { try await fetchPersonalRecordInfo(for: workoutInfo) }
                            })
                            .task { try? await fetchBodyWeight(for: workoutInfo) }
                            .task { try? await fetchPersonalRecordInfo(for: workoutInfo) }
                        }
                        .buttonStyle(.plain)
                        .scenePadding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .contextMenu {
                            Button {
                                share(workoutInfo: workoutInfo)
                            } label: {
                                Text("Share")
                                Image(systemName: "square.and.arrow.up")
                            }
                            
                            Button {
                                self.repeat(workoutInfo: workoutInfo)
                            } label: {
                                Text("Repeat")
                                Image(systemName: "arrow.clockwise")
                            }
                            
                            Button(role: .destructive) {
                                confirmDelete(workoutInfo: workoutInfo)
                            } label: {
                                Text("Delete")
                                Image(systemName: "trash")
                            }
                            
                        }
                    }
                }
                .scenePadding(.horizontal)
            }
            .actionSheet(item: $deletionWorkout) { workout in
                ActionSheet(title: Text("This cannot be undone."), buttons: [
                    .destructive(Text("Delete Workout"), action: {
                        delete(workout: workout)
                    }),
                    .cancel()
                ])
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .placeholder(show: workoutInfos.isEmpty, Text("Your finished workouts will appear here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            )
//            .placeholder(show: loading, ProgressView())
            .navigationBarTitle(Text("History"))
            
            // Double Column Placeholder (iPad)
            Text("No workout selected")
                .foregroundColor(.secondary)
        }
        .navigationViewStyle(.stack)
        .animation(.default, value: workoutInfos)
        .mirrorAppearanceState(to: $workoutInfos.isAutoupdating)
//        .task { try? await fetchWorkoutInfos() }
    }
}

// MARK: - View Model

import IronData
import GRDB
import Combine

extension WorkoutList {
    // MARK: - Workout Infos
    
    struct WorkoutInfo: Decodable, FetchableRecord, Equatable, Identifiable {
        var workout: Workout
        var workoutExerciseInfos: [WorkoutExerciseInfo]
        
        var id: Workout.ID { workout.id }
        
        struct WorkoutExerciseInfo: Decodable, FetchableRecord, Equatable {
            var workoutExercise: WorkoutExercise
            var exercise: Exercise
            var workoutSets: [WorkoutSet]
        }
        
        static func filterFinished() -> QueryInterfaceRequest<WorkoutInfo> {
            Workout
                .filter(Workout.Columns.isActive == false)
                .including(all: Workout.workoutExercises
                    .forKey(CodingKeys.workoutExerciseInfos)
                    .including(all: WorkoutExercise.workoutSets)
                    .including(required: WorkoutExercise.exercise)
                )
                .orderByStart()
                .asRequest(of: WorkoutInfo.self)
        }
    }
    
    struct WorkoutInfosRequest: Queryable {
        static var defaultValue: [WorkoutInfo] { [] }

        func publisher(in database: AppDatabase) -> AnyPublisher<[WorkoutInfo], Error> {
            ValueObservation.trackingConstantRegion(WorkoutInfo.filterFinished().fetchAll(_:))
                .publisher(in: database.databaseReader)
                .eraseToAnyPublisher()
        }
    }
    
//    func fetchWorkoutInfos() async throws {
//        let observation = ValueObservation
//            .tracking(WorkoutInfo.filterFinished().fetchAll(_:))
//            .values(in: database.databaseReader)
//        for try await workoutInfos in observation {
//            self.workoutInfos = workoutInfos
//            loading = false
//        }
//    }
    
    // MARK: - Body Weight
    
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
    
    typealias PersonalRecordInfo = [WorkoutExercise.ID.Wrapped : Int]
    
    func fetchPersonalRecordInfo(for workoutInfo: WorkoutInfo) async throws {
        // NOTE: for now we don't return the cached value
        // if we want to use the cached value here, then we also need to reset the cache in `fetchData`
        // potential downside of this might be flickering everytime we reset the cache
        
        let personalRecordInfo = try await database.databaseReader.read { db -> PersonalRecordInfo in
            var map = PersonalRecordInfo()
            for workoutExerciseInfo in workoutInfo.workoutExerciseInfos {
                map[workoutExerciseInfo.workoutExercise.id!] = try workoutExerciseInfo.workoutSets.filter { workoutSet in
                    try workoutSet.isPersonalRecord(db, info: (workoutExercise: workoutExerciseInfo.workoutExercise, workout: workoutInfo.workout))
                }.count
            }
            return map
        }
        withAnimation {
            personalRecordInfos[workoutInfo.workout.id!] = personalRecordInfo
        }
    }
    
    func personalRecordInfo(for workoutInfo: WorkoutInfo) -> PersonalRecordInfo? {
        personalRecordInfos[workoutInfo.workout.id!]
    }
    
    // MARK: - Actions
    
    func delete(workout: Workout) {
        Task { try! await database.deleteWorkouts(ids: [workout.id!]) }
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

struct WorkoutList_Previews : PreviewProvider {
    static var previews: some View {
        WorkoutList()
            .environment(\.appDatabase, .random())
            .environmentObject(SettingsStore.mockMetric)
    }
}
