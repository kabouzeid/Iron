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

    let xAxisDateFormatter: DateFormatter
    let xAxisYearDateFormatter: DateFormatter
    let balloonDateFormatter: DateFormatter
    let balloonYearDateFormatter: DateFormatter

    let yAxisValueFormatter = DefaultAxisValueFormatter(decimals: 0)

    init(exercise: Exercise? = nil) {
        self.exercise = exercise

        // init the date formatters, it's cheaper to init them just once
        xAxisDateFormatter = DateFormatter()
        balloonDateFormatter = DateFormatter()
        xAxisYearDateFormatter = DateFormatter()
        balloonYearDateFormatter = DateFormatter()

        xAxisDateFormatter.doesRelativeDateFormatting = true
        balloonDateFormatter.doesRelativeDateFormatting = true
        xAxisYearDateFormatter.doesRelativeDateFormatting = true
        balloonYearDateFormatter.doesRelativeDateFormatting = true

        xAxisDateFormatter.setLocalizedDateFormatFromTemplate("MMMd")
        balloonDateFormatter.setLocalizedDateFormatFromTemplate("MMMdjmm")
        xAxisYearDateFormatter.setLocalizedDateFormatFromTemplate("yyyyMMMd")
        balloonYearDateFormatter.setLocalizedDateFormatFromTemplate("yyyyMMMdjmm")
    }

    enum MeasurementType: CaseIterable {
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

    func formatters(for measurementType: MeasurementType, timeFrame: TimeFrame) -> (IAxisValueFormatter, IAxisValueFormatter, BalloonValueFormatter) {
        let balloonValueFormatter = BaseBalloonValueFormatter()

        let xAxisDateFormatter: DateFormatter
        let balloonDateFormatter: DateFormatter

        switch timeFrame {
        case .month, .threeMonths, .year:
            xAxisDateFormatter = self.xAxisDateFormatter
            balloonDateFormatter = self.balloonDateFormatter
        case .all:
            xAxisDateFormatter = xAxisYearDateFormatter
            balloonDateFormatter = balloonYearDateFormatter
        }

        let xAxisValueFormatter = DateAxisFormatter(dateFormatter: xAxisDateFormatter)
        balloonValueFormatter.xFormatter = { balloonDateFormatter.string(from: valueToDate(value: $0)) }

        switch measurementType {
        case .oneRM, .totalWeight:
            balloonValueFormatter.yFormatter = { Float($0).shortStringValue + "kg" }
        case .totalSets, .totalRepetitions:
            balloonValueFormatter.yFormatter = { Float($0).shortStringValue }
        }

        return (xAxisValueFormatter, yAxisValueFormatter, balloonValueFormatter)
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

        return LineChartDataSet(values: entries, label: label)
    }

    // MARK: - Formatter
    class DateAxisFormatter: IAxisValueFormatter {
        let dateFormatter: DateFormatter

        init(dateFormatter: DateFormatter) {
            self.dateFormatter = dateFormatter
        }

        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            return dateFormatter.string(from: valueToDate(value: value))
        }
    }

    class BaseBalloonValueFormatter: BalloonValueFormatter {
        typealias Formatter = (Double) -> String?
        var xFormatter: Formatter?
        var yFormatter: Formatter?

        func stringForXValue(x: Double) -> String? {
            return xFormatter?(x)
        }

        func stringForYValue(y: Double) -> String? {
            return yFormatter?(y)
        }
    }
}

private func dateToValue(date: Date) -> Double {
    return date.timeIntervalSince1970 / (60 * 60)
}

private func valueToDate(value: Double) -> Date {
    return Date(timeIntervalSince1970: value * (60 * 60))
}
