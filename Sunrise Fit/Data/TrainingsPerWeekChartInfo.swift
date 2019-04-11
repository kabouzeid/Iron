//
//  TrainingsPerWeekChartDataGenerator.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 30.09.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Charts
import CoreData

class TrainingsPerWeekChartInfo {

    let xAxisValueFormatter: IAxisValueFormatter
    let yAxisValueFormatter = DefaultAxisValueFormatter(decimals: 0)
    
    private static let NUMBER_OF_WEEKS = 8

    // last weeks + current week (current week is the last element)
    private let weeks: [Date] = {
        var weeks = [Date]()
        var date = Date().startOfWeek! // this week
        weeks.append(date)
        for _ in 1...NUMBER_OF_WEEKS - 1 {
            date = date.yesterday!.startOfWeek!
            weeks.append(date)
        }
        return weeks.reversed()
    }()
    private var trainingsPerWeek: [Int]
    
    init() {
        xAxisValueFormatter = WeekAxisFormatter(weeks: weeks)
        let trainingHistory = (try? AppDelegate.instance.persistentContainer.viewContext.fetch(TrainingsPerWeekChartInfo.fetchRequest)) ?? []
        trainingsPerWeek = TrainingsPerWeekChartInfo.trainingsPerWeek(trainings: trainingHistory, weeks: weeks)
    }
    
    private static func trainingsPerWeek(trainings: [Training], weeks: [Date]) -> [Int] {
        var trainingsPerWeek = [Int]()
        for (i, week) in weeks.enumerated() {
            let upperDate = i+1 < weeks.count ? weeks[i+1] : Date()
            trainingsPerWeek.append(trainings.filter { $0.start! >= week && $0.start! < upperDate }.count)
        }
        return trainingsPerWeek
    }

    private static let fetchRequest: NSFetchRequest<Training> = {
        let request: NSFetchRequest<Training> = Training.fetchRequest()
        request.predicate = NSPredicate(format: "isCurrentTraining != %@ AND start >= %@", NSNumber(booleanLiteral: true), Calendar.current.date(byAdding: Calendar.Component.weekOfYear ,value: -(NUMBER_OF_WEEKS - 1), to: Date())!.startOfWeek! as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]
        return request
    }()

    func chartData() -> BarChartData {
        let dataSet = generateChartDataSet(
            trainingsPerWeek: trainingsPerWeek,
            label: "Trainings per week")
        return BarChartData(dataSet: dataSet)
    }

    private func generateChartDataSet(trainingsPerWeek: [Int], label: String?) -> BarChartDataSet {
        // Define chart entries
        var entries = [BarChartDataEntry]()
        for (i, numberOfTrainings) in trainingsPerWeek.enumerated() {
            let xValue = Double(i)
            let yValue = Double(numberOfTrainings)
            let entry = BarChartDataEntry(x: xValue, y: yValue)
            entries.append(entry)
        }
        return BarChartDataSet(entries: entries, label: label)
    }
    
    // MARK: - Formatter
    class WeekAxisFormatter: IAxisValueFormatter {
        let dateFormatter: DateFormatter
        let weeks: [Date]

        init(weeks: [Date]) {
            self.weeks = weeks
            dateFormatter = DateFormatter()
            dateFormatter.setLocalizedDateFormatFromTemplate("Md")
        }

        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            return dateFormatter.string(from: weeks[Int(value)])
        }
    }
}
