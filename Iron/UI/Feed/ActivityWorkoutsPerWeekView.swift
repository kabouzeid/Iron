//
//  ActivityWorkoutsPerWeekView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import WorkoutDataKit

struct ActivityWorkoutsPerWeekView: View {
    @Environment(\.calendar) var calendar
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @EnvironmentObject var exerciseStore: ExerciseStore
    @EnvironmentObject var entitlementStore: EntitlementStore
    
    @FetchRequest(fetchRequest: Workout.fetchRequest()) var workoutHistory
    
    static let NUMBER_OF_WEEKS = 7
    
    private static func fetchRequest(calendar: Calendar) -> NSFetchRequest<Workout> {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(
            format: "\(#keyPath(Workout.isCurrentWorkout)) != %@ AND \(#keyPath(Workout.start)) >= %@",
            NSNumber(booleanLiteral: true),
            calendar.startOfWeek(for: calendar.date(byAdding: .weekOfYear ,value: -(NUMBER_OF_WEEKS - 1), to: Date())!)! as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        return request
    }
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("Md")
        return dateFormatter
    }()
    
    init() {
        self._workoutHistory = FetchRequest(fetchRequest: Self.fetchRequest(calendar: calendar))
    }

    private var weeks: [Date] {
        let date = Date()
        return (0..<Self.NUMBER_OF_WEEKS).map { i in
            calendar.startOfWeek(for: calendar.date(byAdding: .weekOfYear, value: -i, to: date)!)!
        }.reversed()
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
    
    private var chartData: [BarStack] {
        workoutsPerWeek(workouts: workoutHistory.map { $0 }, weeks: weeks).map { (arg) -> BarStack in
            let (workouts, week) = arg
            return BarStack(
                entries: workouts.map { workout in
                    let muscleGroup = workout.muscleGroups(in: exerciseStore.exercises).first ?? "other"
                    return BarStackEntry(color: .accentColor /*Exercise.colorFor(muscleGroup: muscleGroup)*/, label: muscleGroup.capitalized)
                },
                label: Self.dateFormatter.string(from: week)
            )
        }
    }
    
    private var hasData: Bool {
        !chartData.flatMap { $0.entries }.isEmpty
    }
    
    @ViewBuilder
    private var chartView: some View {
        if hasData {
            BarStacksView(barStacks: chartData, spacing: 2, stackSize: 4) // assume 4 workouts / week
        } else {
            Color.clear.overlay(
                Text("No data available")
                    .foregroundColor(.secondary)
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            chartView
                .modifier(if: !entitlementStore.isPro) {
                    $0.overlay(UnlockProOverlay(size: .fill).padding())
                }
            
            Divider()
            
            BarLabelsView(barStacks: chartData, labelCount: chartData.count)
                .padding([.top, .bottom], 4)
        }
    }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date? {
        self.date(from: self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))
    }
}

#if DEBUG
struct MyActivityBarChartView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActivityWorkoutsPerWeekView()
                .mockEnvironment(weightUnit: .metric, isPro: true)
                .frame(height: 250)
                .previewLayout(.sizeThatFits)
            
            List {
                ActivityWorkoutsPerWeekView()
                    .mockEnvironment(weightUnit: .metric, isPro: true)
                    .frame(height: 250)
            }.listStyleCompat_InsetGroupedListStyle()
        }
    }
}
#endif
