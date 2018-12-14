//
//  FeedTableViewController.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 30.09.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import CoreData
import Charts

class FeedTableViewController: UITableViewController {

    @IBOutlet weak var summaryView: SummaryView!
    
    private var trainingsPerWeekChartInfo: TrainingsPerWeekChartInfo?
    private var trainingsPerWeekChartDataCache: BarChartData?
    
    private var pinnedCharts = [UserDefaults.PinnedChart]()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSummary()
        
        pinnedCharts = UserDefaults.standard.pinnedCharts()
        trainingsPerWeekChartInfo = nil
        trainingsPerWeekChartDataCache = nil
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return pinnedCharts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "bar chart cell", for: indexPath) as! BarChartCell
            cell.titleLabel.text = "Activity"
            cell.detailLabel.text = "Workouts per week"
            
            trainingsPerWeekChartInfo = trainingsPerWeekChartInfo ?? TrainingsPerWeekChartInfo()
            let chartData = trainingsPerWeekChartDataCache ?? trainingsPerWeekChartInfo!.chartData()
            trainingsPerWeekChartDataCache = chartData
            
            cell.chartView.xAxis.valueFormatter = trainingsPerWeekChartInfo!.xAxisValueFormatter
            cell.chartView.leftAxis.valueFormatter = trainingsPerWeekChartInfo!.yAxisValueFormatter
            
            cell.chartView.xAxis.labelCount = chartData.entryCount
            cell.chartView.leftAxis.axisMinimum = 0
            cell.chartView.dragXEnabled = false
            cell.chartView.scaleXEnabled = false
            cell.chartView.leftAxis.drawAxisLineEnabled = false
            cell.chartView.xAxis.drawGridLinesEnabled = false
            cell.chartView.isUserInteractionEnabled = false
            
            cell.chartView.data = chartData
            cell.chartView.fitScreen()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "line chart cell", for: indexPath) as! LineChartCell
            let pinnedChart = pinnedCharts[indexPath.row]
  
            let exercise = EverkineticDataProvider.findExercise(id: pinnedChart.exerciseId)
            let chartDataGenerator = TrainingExerciseChartDataGenerator(exercise: exercise)

            cell.detailLabel.text = exercise?.title
            cell.titleLabel.text = pinnedChart.measurementType.title
            
            let formatters = chartDataGenerator.formatters(for: pinnedChart.measurementType)
            let chartData = chartDataGenerator.chartData(for: pinnedChart.measurementType, timeFrame: .threeMonths)

            cell.chartView.xAxis.valueFormatter = formatters.0
            cell.chartView.leftAxis.valueFormatter = formatters.1
            cell.chartView.balloonMarker.valueFormatter = formatters.2
            
            cell.chartView.data = chartData
            cell.chartView.fitScreen()
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return min(tableView.frame.width * (1/1.61), (tableView.frame.height - tableView.safeAreaInsets.top - tableView.safeAreaInsets.bottom) * 0.9) // golden ratio
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    // MARK: - Summary view

    private func updateSummary() {
        // create the fetch requests
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let sevenDaysRequest: NSFetchRequest<Training> = Training.fetchRequest()
        sevenDaysRequest.predicate = NSPredicate(format: "isCurrentTraining != %@ AND start >= %@",
                                                 NSNumber(booleanLiteral: true),
                                                 sevenDaysAgo as NSDate)

        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: sevenDaysAgo)!
        let fourteenDaysRequest: NSFetchRequest<Training> = Training.fetchRequest()
        fourteenDaysRequest.predicate = NSPredicate(format: "isCurrentTraining != %@ AND start >= %@ AND start < %@",
                                                    NSNumber(booleanLiteral: true),
                                                    fourteenDaysAgo as NSDate,
                                                    sevenDaysAgo as NSDate)

        // fetch the objects
        let trainingsFromSevenDaysAgo = (try? AppDelegate.instance.persistentContainer.viewContext.fetch(sevenDaysRequest)) ?? []
        let trainingsFromFourteenDaysAgo = (try? AppDelegate.instance.persistentContainer.viewContext.fetch(fourteenDaysRequest)) ?? []

        // compute the values
        let valuesSevenDaysAgo = trainingsFromSevenDaysAgo.reduce((0, 0, 0)) { (result, training) -> (TimeInterval, Int, Double) in
            return (result.0 + training.duration, result.1 + training.numberOfCompletedSets, result.2 + training.totalCompletedWeight)
        }
        let valuesFourTeenDaysAgo = trainingsFromFourteenDaysAgo.reduce((0, 0, 0)) { (result, training) -> (TimeInterval, Int, Double) in
            return (result.0 + training.duration, result.1 + training.numberOfCompletedSets, result.2 + training.totalCompletedWeight)
        }

        // set the values
        let durationEntry = summaryView.entries[0]
        let setsEntry = summaryView.entries[1]
        let weightEntry = summaryView.entries[2]

        durationEntry.title.text = "Duration\nLast 7 Days"
        setsEntry.title.text = "Sets\nLast 7 Days"
        weightEntry.title.text = "Weight\nLast 7 Days"

        durationEntry.text.text = Training.durationFormatter.string(from: valuesSevenDaysAgo.0)!
        setsEntry.text.text = "\(valuesSevenDaysAgo.1)"
        weightEntry.text.text = "\(valuesSevenDaysAgo.2.shortStringValue) kg"

        var durationPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (((valuesSevenDaysAgo.0 / valuesFourTeenDaysAgo.0) - 1) * 100)
        durationPercent = abs(durationPercent) < 0.1 ? 0 : durationPercent
        if durationPercent > 0 {
            durationEntry.detail.textColor = UIColor.appleGreen
            durationEntry.detail.text = "+"
        } else if durationPercent < 0 {
            durationEntry.detail.textColor = UIColor.appleRed
            durationEntry.detail.text = ""
        } else {
            durationEntry.detail.textColor = UIColor.darkGray
            durationEntry.detail.text = "+"
        }
        durationEntry.detail.text! += String(format: "%.1f", durationPercent) + "%"
        durationEntry.detail.isHidden = false

        var setsPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (((Float(valuesSevenDaysAgo.1) / Float(valuesFourTeenDaysAgo.1)) - 1) * 100)
        setsPercent = abs(setsPercent) < 0.1 ? 0 : setsPercent
        if setsPercent > 0 {
            setsEntry.detail.textColor = UIColor.appleGreen
            setsEntry.detail.text = "+"
        } else if setsPercent < 0 {
            setsEntry.detail.textColor = UIColor.appleRed
            setsEntry.detail.text = ""
        } else {
            setsEntry.detail.textColor = UIColor.darkGray
            setsEntry.detail.text = "+"
        }
        setsEntry.detail.text! += String(format: "%.1f", setsPercent) + "%"
        setsEntry.detail.isHidden = false

        var weightPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (((valuesSevenDaysAgo.2 / valuesFourTeenDaysAgo.2) - 1) * 100)
        weightPercent = abs(weightPercent) < 0.1 ? 0 : weightPercent
        if weightPercent > 0 {
            weightEntry.detail.textColor = UIColor.appleGreen
            weightEntry.detail.text = "+"
        } else if weightPercent < 0 {
            weightEntry.detail.textColor = UIColor.appleRed
            weightEntry.detail.text = ""
        } else {
            weightEntry.detail.textColor = UIColor.darkGray
            weightEntry.detail.text = "+"
        }
        weightEntry.detail.text! += String(format: "%.1f", weightPercent) + "%"
        weightEntry.detail.isHidden = false
    }
}

// MARK: - Custom cells

class BarChartCell: UITableViewCell {
    @IBOutlet weak var chartView: StyledBarChartView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
}

class LineChartCell: UITableViewCell {
    @IBOutlet weak var chartView: StyledLineChartView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
}
