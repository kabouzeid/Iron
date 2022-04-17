//
//  WorkoutTab.swift
//  Iron
//
//  Created by Karim Abou Zeid on 11.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct WorkoutTab: View {
    @StateObject var viewModel = ViewModel(database: .shared)
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let workout = viewModel.activeWorkout {
                        Button {
                            viewModel.resumeWorkout(workout: workout)
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
                            viewModel.startWorkout()
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
        .task {
            try? await viewModel.fetchData()
        }
        .sheet(item: $viewModel.displayedWorkout) { workout in
            ActiveWorkoutView(workout: workout)
        }
    }
}

import GRDB
import IronData

extension WorkoutTab {
    @MainActor
    class ViewModel: ObservableObject {
        let database: AppDatabase
        
        nonisolated init(database: AppDatabase) {
            self.database = database
        }
        
        @Published var activeWorkout: Workout? = nil
        
        @Published var displayedWorkout: Workout? = nil
        
        func fetchData() async throws {
            for try await activeWorkout in activeWorkoutStream() {
                self.activeWorkout = activeWorkout
            }
        }
        
        private func activeWorkoutStream() -> AsyncValueObservation<Workout?> {
            ValueObservation.tracking(Workout.filter(Workout.Columns.isActive == true).fetchOne)
                .values(in: database.databaseReader, scheduling: .immediate)
        }
        
        // MARK: - Actions
        
        func startWorkout() {
            // TODO
        }
        
        func resumeWorkout(workout: Workout) {
            displayedWorkout = workout
        }
    }
}

struct WorkoutTab_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutTab(viewModel: .init(database: .random()))
    }
}
