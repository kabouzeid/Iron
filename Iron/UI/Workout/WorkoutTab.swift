//
//  WorkoutTab.swift
//  Iron
//
//  Created by Karim Abou Zeid on 11.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct WorkoutTab: View {
    @FetchRequest(fetchRequest: Workout.currentWorkoutFetchRequest) var currentWorkouts
    
    private var currentWorkout: Workout? {
        assert(currentWorkouts.count <= 1)
        return currentWorkouts.first
    }
    
    private func workoutView(workout: Workout?) -> some View {
        Group { // is Group the appropiate choice here? (want to avoid AnyView)
            if workout != nil {
                WorkoutView(workout: workout!)
            } else {
                StartWorkoutView()
            }
        }
    }
    
    var body: some View {
        workoutView(workout: currentWorkout)
    }
}

#if DEBUG
struct WorkoutTab_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutTab()
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
