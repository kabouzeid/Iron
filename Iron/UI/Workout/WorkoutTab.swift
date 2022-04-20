//
//  WorkoutTab.swift
//  Iron
//
//  Created by Karim Abou Zeid on 11.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import GRDBQuery

struct WorkoutTab: View {
    @Query(ActiveWorkoutRequest(), isAutoupdating: false) private var activeWorkout: Workout?
    
    @Environment(\.appDatabase) private var database
    
    @State private var openWorkout: Workout?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if activeWorkout != nil {
                        Button {
                            resumeWorkout()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Resume Workout").font(.headline)
                                Spacer()
                            }
                            .overlay {
                                HStack {
                                    Spacer()
                                    Text("48:32").font(.subheadline.monospacedDigit()) // TODO
                                }
                            }
                            .padding(6)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            startWorkout()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Start Workout").font(.headline)
                                Spacer()
                            }
                            .padding(6)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                
                Text("Push")
                
                Text("Pull")
                
                Text("Legs")
            }
            .navigationTitle("Workout")
        }
        .onChange(of: activeWorkout) { _ in
            if activeWorkout == nil {
                openWorkout = nil
            } else if openWorkout != nil {
                openWorkout = activeWorkout
            }
        }
        .sheet(item: $openWorkout) { workout in
            NavigationView {
                WorkoutView(workoutID: workout.id!)
            }
        }
        .mirrorAppearanceState(to: $activeWorkout.isAutoupdating)
    }
}

import IronData
import GRDB
import Combine

extension WorkoutTab {
    struct ActiveWorkoutRequest: Queryable {
        static var defaultValue: Workout? { nil }
        
        func publisher(in database: AppDatabase) -> AnyPublisher<Workout?, Error> {
            ValueObservation.tracking(Workout.filter(Workout.Columns.isActive == true).fetchOne(_:))
                .publisher(in: database.databaseReader, scheduling: .immediate)
                .eraseToAnyPublisher()
        }
    }
    
    // MARK: - Actions
    
    func startWorkout() {
        Task {
            let workout: Workout? = try await database.databaseWriter.write { db in
                guard try Workout.filter(Workout.Columns.isActive == true).fetchCount(db) == 0 else { return nil }
                
                var workout = Workout.new(start: .init())
                workout.isActive = true
                try workout.save(db)
                return workout
            }
            guard let workout = workout else { return }
            openWorkout = workout
        }
        
        // TODO: properly start workout: watch, health, etc
    }
    
    func resumeWorkout() {
        openWorkout = activeWorkout
    }
}

struct WorkoutTab_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutTab()
            .environment(\.appDatabase, .random())
    }
}
