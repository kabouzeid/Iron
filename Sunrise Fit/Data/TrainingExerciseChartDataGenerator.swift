//
//  TrainingExerciseChartDataGenerator.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 16.09.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Charts

class TrainingExerciseChartDataGenerator {

    var exercise: Exercise? {
        didSet {
            if let exercise = exercise {
                trainingExerciseHistory = TrainingExercise.fetchHistory(of: exercise.id, until: Date(), context: AppDelegate.instance.persistentContainer.viewContext) ?? []
            } else {
                trainingExerciseHistory = []
            }
        }
    }
    private var trainingExerciseHistory = [TrainingExercise]()

    init(exercise: Exercise? = nil) {
        defer { self.exercise = exercise } // without defer, didSet is not called
    }

    enum MeasurementType: String, CaseIterable {
        case oneRM
        case totalWeight
        case totalSets
        case totalRepetitions

        var title: String {
            switch self {
            case .oneRM:
                return "1RM"
            case .totalWeight:
                return "Total Weight"
            case .totalSets:
                return "Total Sets"
            case .totalRepetitions:
                return "Total Repetitions"
            }
        }
    }

    enum TimeFrame: CaseIterable {
        case month
        case threeMonths
        case year
        case all

        var title: String {
            switch self {
            case .month:
                return "Month"
            case .threeMonths:
                return "3 Months"
            case .year:
                return "Year"
            case .all:
                return "All"
            }
        }

        var filter: (TrainingExercise) -> Bool {
            switch self {
            case .month:
                return { $0.training!.start! >= Calendar.current.date(byAdding: .month, value: -1,  to: Date())! }
            case .threeMonths:
                return { $0.training!.start! >= Calendar.current.date(byAdding: .month, value: -3,  to: Date())! }
            case .year:
                return { $0.training!.start! >= Calendar.current.date(byAdding: .year, value: -1,   to: Date())! }
            case .all:
                return { _ -> Bool in return true }
            }
        }
    }

    let countBalloonValueFormatter = DateBalloonValueFormatter(append: "x")
    let kgBalloonValueFormatter = DateBalloonValueFormatter(append: "kg")
    let xAxisValueFormatter = DateAxisFormatter()
    let yAxisValueFormatter = DefaultAxisValueFormatter(decimals: 0)

    func formatters(for measurementType: MeasurementType) -> (IAxisValueFormatter, IAxisValueFormatter, BalloonValueFormatter) {
        switch measurementType {
        case .oneRM, .totalWeight:
            return (xAxisValueFormatter, yAxisValueFormatter, kgBalloonValueFormatter)
        case .totalSets, .totalRepetitions:
            return (xAxisValueFormatter, yAxisValueFormatter, countBalloonValueFormatter)
        }
    }

    func chartData(for measurementType: MeasurementType, timeFrame: TimeFrame) -> LineChartData {
        let dataSet = generateChartDataSet(
            trainingExercises: trainingExerciseHistory.filter(timeFrame.filter),
            trainingExerciseToValue: trainingExerciseToValue(for: measurementType),
            label: measurementType.title)
        return LineChartData(dataSet: dataSet)
    }

    private func trainingExerciseToValue(for measurementType: MeasurementType) -> TrainingExerciseToValue {
        switch measurementType {
        case .oneRM:
            return {
                $0.trainingSets!.map({ (trainingSet) -> Double in
                    let trainingSet = trainingSet as! TrainingSet
                    if trainingSet.repetitions > 5 {
                        // accuracy goes way down for more than 5 reps
                        return 0
                    }
                    return Double(trainingSet.weight) * (36 / (37 -     Double(trainingSet.repetitions))) // Brzycki 1RM formula
                }).max() ?? 0
            }
        case .totalWeight:
            return  { Double($0.totalCompletedWeight) }
        case .totalSets:
            return { Double($0.numberOfCompletedSets ?? 0) }
        case .totalRepetitions:
            return  { Double($0.numberOfCompletedRepetitions) }
        }
    }

    private typealias TrainingExerciseToValue = (TrainingExercise) -> Double
    private func generateChartDataSet(trainingExercises: [TrainingExercise], trainingExerciseToValue: TrainingExerciseToValue, label: String?) -> LineChartDataSet {
        // Define chart entries
        var entries = [ChartDataEntry]()
        for trainingExercise in trainingExercises {
            let xValue = dateToValue(date: trainingExercise.training!.start!)
            let yValue = trainingExerciseToValue(trainingExercise)
            let entry = ChartDataEntry(x: xValue, y: yValue)
            entries.append(entry)
        }
        entries.reverse() // fixes a strange bug, where the chart line is not drawn

        return LineChartDataSet(entries: entries, label: label)
    }

    // MARK: - Formatter
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
        let yAxisValueFormatter = DefaultAxisValueFormatter(decimals: 0)
        let dateFormatter: DateFormatter
        let yearDateFormatter: DateFormatter
        let append: String?

        init(append: String?) {
            self.append = append
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
            return yAxisValueFormatter.stringForValue(y, axis: nil) + (append ?? "")
        }
    }
    
    public static func dateEqualsValue(date: Date, value: Double) -> Bool {
        return dateToValue(date: date) == value
    }
}

private func dateToValue(date: Date) -> Double {
    return date.timeIntervalSince1970 / (60 * 60)
}

private func valueToDate(value: Double) -> Date {
    return Date(timeIntervalSince1970: value * (60 * 60))
}
