//
//  WorkoutLog.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 12.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct WorkoutLog: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @ObservedObject var workout: Workout
    
    private func workoutExerciseText(workoutExercise: WorkoutExercise) -> String? {
        guard let workoutSets = workoutExercise.workoutSets else { return nil }
        let text = workoutSets
            .compactMap { $0 as? WorkoutSet }
            .filter { $0.isCompleted }
            .map { $0.logTitle(unit: settingsStore.weightUnit) }
            .joined(separator: "\n")
        return text.isEmpty ? nil : text
    }
    
    var body: some View {
        List {
            Section {
                WorkoutLogBannerView(workout: workout)
                    .listRowBackground(workout.muscleGroupColor(in: exerciseStore.exercises))
                    .environment(\.colorScheme, .dark) // TODO: check whether accent color is actually dark
            }
            Section {
                ForEach(workout.workoutExercisesWhereNotAllSetsAreUncompleted ?? [], id: \.objectID) { workoutExercise in
                    VStack(alignment: .leading) {
                        Text(workoutExercise.exercise(in: self.exerciseStore.exercises)?.title ?? "")
                            .font(.body)
                        self.workoutExerciseText(workoutExercise: workoutExercise).map {
                            Text($0)
                                .font(Font.body.monospacedDigit())
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}

private struct WorkoutLogBannerView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @ObservedObject var workout: Workout
    
    var body: some View {
        BannerView(entries: bannerViewEntries)
    }
    
    private var bannerViewEntries: [BannerViewEntry] {
        var entries = [BannerViewEntry]()
        
        entries.append(BannerViewEntry(id: 0, title: Text("Sets"), text: Text(String(workout.numberOfCompletedSets ?? 0))))
        entries.append(BannerViewEntry(id: 1, title: Text("Weight"), text: Text("\(WeightUnit.format(weight: workout.totalCompletedWeight ?? 0, from: .metric, to: settingsStore.weightUnit))")))
        return entries
    }
}

#if DEBUG
struct WorkoutLog_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutLog(workout: MockWorkoutData.metricRandom.currentWorkout)
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
