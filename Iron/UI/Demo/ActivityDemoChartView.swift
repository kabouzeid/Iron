//
//  ActivityChartView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData

struct ActivityDemoChartView: View {
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    private static let NUMBER_OF_WEEKS = 8
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("Md")
        return dateFormatter
    }()

    private var weeks: [Date] {
        var weeks = [Date]()
        var date = Date().startOfWeek! // this week
        weeks.append(date)
        for _ in 1...Self.NUMBER_OF_WEEKS - 1 {
            date = date.yesterday!.startOfWeek!
            weeks.append(date)
        }
        return weeks.reversed()
    }
    
    private func muscleGroups(n: Int) -> [String] {
        Exercise.muscleNames
            .compactMap { Exercise.muscleGroup(for: $0) }
            .uniqed()
            .shuffled()
            .prefix(5 - Int.random(in: 0...3))
            .map { $0 }
    }
    
    private var activityData: [BarStack] {
//        workoutsPerWeek(workouts: workoutHistory.map { $0 }, weeks: weeks).map { (arg) -> BarStack in
//            let (workouts, week) = arg
//            return BarStack(
//                entries: workouts.map { workout in
//                    let muscleGroup = workout.muscleGroups(in: exerciseStore.exercises).first ?? "other"
//                    return BarStackEntry(color: Exercise.colorFor(muscleGroup: muscleGroup), label: muscleGroup.capitalized)
//                },
//                label: Self.dateFormatter.string(from: week)
//            )
//        }
        // TODO
        weeks.enumerated().map { n, week in
            BarStack(
                entries: muscleGroups(n: n).map { BarStackEntry(color: Exercise.colorFor(muscleGroup: $0), label: $0.capitalized) },
                label: Self.dateFormatter.string(from: week))
        }
    }

    var body: some View {
        VStack {
            BarStacksView(barStacks: activityData, spacing: 2)
            BarLabelsView(barStacks: activityData, labelCount: activityData.count)
            LegendView(barStacks: activityData)
        }
    }
}

#if DEBUG
struct ActivityDemoChartView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityDemoChartView()
            .mockEnvironment(weightUnit: .metric, isPro: false)
    }
}
#endif
