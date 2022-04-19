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
    @Query(ActiveWorkoutRequest()) private var activeWorkout: Workout?
    
    @State private var openWorkout: Workout?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let workout = activeWorkout {
                        Button {
                            resumeWorkout(workout: workout)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Resume Workout")
                                    .font(.headline)
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
                                Text("Start Workout")
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
        .sheet(item: $openWorkout) { workout in
            ActiveWorkoutView()
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
        // TODO
    }
    
    func resumeWorkout(workout: Workout) {
        openWorkout = workout
    }
}

struct WorkoutTab_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutTab()
            .environment(\.appDatabase, .random())
    }
}
