//
//  WorkoutExerciseSectionHeader.swift
//  Iron
//
//  Created by Karim Abou Zeid on 13.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct WorkoutExerciseSectionHeader: View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    @ObservedObject var workoutExercise: WorkoutExercise
    
    @ObservedObject var bodyWeightFetcher: BodyWeightFetcher
    
    init(workoutExercise: WorkoutExercise) {
        _workoutExercise = .init(initialValue: workoutExercise)
        _bodyWeightFetcher = .init(initialValue: .init(date: workoutExercise.workout?.start))
    }
    
    func format(weight: Double) -> String { // weight should always be in kg
        let weightUnit = settingsStore.weightUnit
        let formatter = weightUnit.formatter
        formatter.numberFormatter.maximumFractionDigits = 1
        return "BW: " + formatter.string(from: Measurement(value: weight, unit: UnitMass.kilograms).converted(to: weightUnit.unit))
    }
    
    var body: some View {
        HStack {
            Text(Workout.dateFormatter.string(from: workoutExercise.workout?.start, fallback: "Unknown date"))
            Spacer()
            bodyWeightFetcher.bodyWeight.map {
                Text(format(weight: $0))
            }
        }.onAppear(perform: bodyWeightFetcher.fetchBodyWeight)
    }
}

#if DEBUG
struct WorkoutExerciseSectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section(header: WorkoutExerciseSectionHeader(workoutExercise: MockWorkoutData.metricRandom.workoutExercise)) {
                Text("Some cell")
            }
        }
        .listStyle(GroupedListStyle())
        .mockEnvironment(weightUnit: .metric, isPro: false)
    }
}
#endif
