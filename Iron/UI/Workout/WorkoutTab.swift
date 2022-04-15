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
        Group {
            if let workout = viewModel.activeWorkout {
                ActiveWorkoutView(workout: workout)
            } else {
                Text("TODO: Start Workout")
            }
        }
        .task {
            try? await viewModel.fetchData()
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
        
        func fetchData() async throws {
            for try await activeWorkout in activeWorkoutStream() {
                self.activeWorkout = activeWorkout
            }
        }
        
        private func activeWorkoutStream() -> AsyncValueObservation<Workout?> {
            ValueObservation.tracking(Workout.filter(Workout.Columns.isActive == true).fetchOne)
                .values(in: database.databaseReader, scheduling: .immediate)
        }
    }
}

struct WorkoutTab_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutTab(viewModel: .init(database: .random()))
    }
}
