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
    
    private var chartData: [Bar] {
        var bars = workoutsPerWeek(workouts: workoutHistory.map { $0 }, weeks: weeks).map {
            Bar(value: $0.0.count, label: Self.dateFormatter.string(from: $0.1))
        }
        
        if let disableUntil = bars.firstIndex(where: { $0.value > 0 }) {
            for i in 0..<disableUntil {
                bars[i].labelColor = Color(.tertiaryLabel)
            }
        }
        
        return bars
    }

    private var hasData: Bool {
        chartData.map { $0.value }.reduce(0, +) > 0
    }
    
    private var meanWorkoutsPerWeek: Double {
        let bars = chartData
        let sum = bars.map { $0.value }.reduce(0, +)
        let ignoredCount = bars.firstIndex(where: { $0.value > 0 }) ?? 0
        return Double(sum) / (Double(bars.count - ignoredCount))
    }
    
    var body: some View {
        Group {
            if hasData {
                BarChartView(bars: chartData, showLabels: entitlementStore.isPro, minimumMaxValue: 4)
                    .modifier(if: !entitlementStore.isPro) {
                        $0.redacted_compat()
                    }
            } else {
                ZStack {
                    Rectangle().hidden()
                    Text("No data available")
                        .foregroundColor(.secondary)
                }
            }
        }
        .modifier(if: !entitlementStore.isPro) {
            $0.overlay(UnlockProOverlay(size: .fill).padding())
        }
        .preference(key: WorkoutsPerWeekMeanKey.self, value: meanWorkoutsPerWeek)
    }
}

struct WorkoutsPerWeekMeanKey: PreferenceKey {
    static var defaultValue: Double?

    static func reduce(value: inout Double?, nextValue: () -> Double?) {
        value = nextValue()
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
