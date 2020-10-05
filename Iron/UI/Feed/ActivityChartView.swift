//
//  ActivityChartView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import WorkoutDataKit

struct ActivityChartView: View {
    @EnvironmentObject var exerciseStore: ExerciseStore
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @FetchRequest(fetchRequest: Self.fetchRequest) var workoutHistory
    
    private static let NUMBER_OF_WEEKS = 8
    
    private static let fetchRequest: NSFetchRequest<Workout> = {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "isCurrentWorkout != %@ AND start >= %@", NSNumber(booleanLiteral: true), Calendar.current.date(byAdding: Calendar.Component.weekOfYear ,value: -(NUMBER_OF_WEEKS - 1), to: Date())!.startOfWeek! as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]
        return request
    }()
    
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
    
    private func workoutsPerWeek(workouts: [Workout], weeks: [Date]) -> [([Workout], Date)] {
        assert(weeks == weeks.sorted())
        return weeks
            .enumerated()
            .map { i, week in
                (workouts.filter {
                    guard let start = $0.start else { return false }
                    let nextWeek = weeks.count > i + 1 ? weeks[i + 1] : Date()
                    return start >= week && start < nextWeek
                }, week)
        }
    }
    
    private var activityData: [BarStack] {
        workoutsPerWeek(workouts: workoutHistory.map { $0 }, weeks: weeks).map { (arg) -> BarStack in
            let (workouts, week) = arg
            return BarStack(
                entries: workouts.map { workout in
                    let muscleGroup = workout.muscleGroups(in: exerciseStore.exercises).first ?? "other"
                    return BarStackEntry(color: Exercise.colorFor(muscleGroup: muscleGroup), label: muscleGroup.capitalized)
                },
                label: Self.dateFormatter.string(from: week)
            )
        }
    }
    
    private var hasData: Bool {
        !activityData.flatMap { $0.entries }.isEmpty
    }

    var body: some View {
        VStack {
            if hasData {
                BarStacksView(barStacks: activityData, spacing: 2, stackSize: 4) // assume 4 workouts / week
            } else {
                Color.clear.overlay(
                    Text("No data available")
                        .foregroundColor(.secondary)
                )
            }
            BarLabelsView(barStacks: activityData, labelCount: activityData.count)
            LegendView(barStacks: activityData)
        }
    }
}

#if DEBUG
struct MyActivityBarChartView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityChartView()
            .mockEnvironment(weightUnit: .metric, isPro: true)
            .frame(height: 250)
            .previewLayout(.sizeThatFits)
    }
}
#endif
