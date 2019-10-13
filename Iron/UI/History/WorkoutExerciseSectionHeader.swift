//
//  WorkoutExerciseSectionHeader.swift
//  Iron
//
//  Created by Karim Abou Zeid on 13.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct WorkoutExerciseSectionHeader: View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    @ObservedObject var workoutExercise: WorkoutExercise
    
    @ObservedObject var bodyWeightFetcher: BodyWeightFetcher
    
    private var weightFormatter: NumberFormatter
    
    init(workoutExercise: WorkoutExercise) {
        _workoutExercise = .init(initialValue: workoutExercise)
        _bodyWeightFetcher = .init(initialValue: .init(date: workoutExercise.workout?.start))
        
        let weightFormatter = NumberFormatter()
        weightFormatter.maximumFractionDigits = 1
        self.weightFormatter = weightFormatter
    }
    
    func format(weight: Double) -> String {
        "BW: \(weightFormatter.string(from: weight as NSNumber) ?? String(format: "%.1f", weight) ) \(settingsStore.weightUnit.abbrev)"
    }
    
    var body: some View {
        HStack {
            Text(Workout.dateFormatter.string(from: workoutExercise.workout?.start, fallback: "Unknown date"))
            Spacer()
            bodyWeightFetcher.bodyWeight.map {
                Text(format(weight: WeightUnit.convert(weight: $0, from: .metric, to: settingsStore.weightUnit)))
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
