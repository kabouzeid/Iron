//
//  WorkoutExerciseChartData.swift
//  IronIntentsUI
//
//  Created by Karim Abou Zeid on 08.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Charts
import WorkoutDataKit

// x formatter
// y formatter
// balloon formatter
// data(exercise, weighUnit)
// data(exercise, weightUnit, maxReps)

struct WorkoutExerciseChartDataGenerator {
    typealias Evaluator = (WorkoutExercise) -> Double?
    
    let workoutExercises: [WorkoutExercise]
    let evaluator: Evaluator
    
    func chartDataEntries() -> [ChartDataEntry] {
        workoutExercises
            .reversed()  // fixes a strange bug, where the chart line is not drawn
            .compactMap { workoutExercise in
                guard let start = workoutExercise.workout?.start else { return nil }
                guard let yValue = evaluator(workoutExercise) else { return nil }
                let xValue = Self.dateToValue(date: start)
                return ChartDataEntry(x: xValue, y: yValue)
            }
    }
    
    static func dateToValue(date: Date) -> Double {
        return date.timeIntervalSince1970 / (60 * 60)
    }

    static func valueToDate(value: Double) -> Date {
        return Date(timeIntervalSince1970: value * (60 * 60))
    }
}

// MARK: - Convenience
extension WorkoutExerciseChartDataGenerator {
    func lineChartData(label: String) -> LineChartData {
        LineChartData(dataSet: lineChartDataSet(label: label))
    }
    
    func lineChartDataSet(label: String) -> LineChartDataSet {
        LineChartDataSet(entries: chartDataEntries(), label: label)
    }
}

// MARK: - Formatter
extension WorkoutExerciseChartDataGenerator {
    class DateAxisFormatter: IAxisValueFormatter {
        let dateFormatter: DateFormatter
        let yearDateFormatter: DateFormatter

        weak var chartView: LineChartView!

        init() {
            dateFormatter = DateFormatter()
            yearDateFormatter = DateFormatter()
            dateFormatter.doesRelativeDateFormatting = true
            yearDateFormatter.doesRelativeDateFormatting = true
            dateFormatter.setLocalizedDateFormatFromTemplate("MMMd")
            yearDateFormatter.setLocalizedDateFormatFromTemplate("yyyyMMMd")
        }

        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            let date = valueToDate(value: value)
            if Calendar.current.compare(date, to: Date(), toGranularity: .year) == .orderedSame {
                return dateFormatter.string(from: date)
            }
            return yearDateFormatter.string(from: date)
        }
    }

    class DateBalloonValueFormatter: BalloonValueFormatter {
        let yAxisValueFormatter = DefaultAxisValueFormatter(formatter: {
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 1
            formatter.usesGroupingSeparator = true
            return formatter
        }())
        let dateFormatter: DateFormatter
        let yearDateFormatter: DateFormatter
        let yUnit: String?

        init(yUnit: String?) {
            self.yUnit = yUnit
            dateFormatter = DateFormatter()
            yearDateFormatter = DateFormatter()
            dateFormatter.doesRelativeDateFormatting = true
            yearDateFormatter.doesRelativeDateFormatting = true
            dateFormatter.setLocalizedDateFormatFromTemplate("MMMdjmm")
            yearDateFormatter.setLocalizedDateFormatFromTemplate("yyyyMMMdjmm")
        }

        func stringForXValue(x: Double) -> String? {
            let date = valueToDate(value: x)
            if Calendar.current.compare(valueToDate(value: x), to: Date(), toGranularity: .year) == .orderedSame {
                return dateFormatter.string(from: date)
            }
            return yearDateFormatter.string(from: date)
        }

        func stringForYValue(y: Double) -> String? {
            return yAxisValueFormatter.stringForValue(y, axis: nil) + (yUnit.map { " " + $0 } ?? "")
        }
    }
}
