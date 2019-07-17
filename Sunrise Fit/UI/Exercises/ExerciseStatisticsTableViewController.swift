//
//  ExerciseStatisticsTableViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 08.09.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import Charts

class ExerciseStatisticsTableViewController: UITableViewController {

    var exercise: Exercise? {
        didSet {
            self.title = exercise?.title
            chartDataGenerator.exercise = exercise
            tableViewEntries = createTableViewEntries()
        }
    }

    @IBAction func timeFrameChanged(_ sender: UISegmentedControl) {
        selectedTimeFrame = TrainingExerciseChartDataGenerator.TimeFrame.allCases[sender.selectedSegmentIndex]
    }

    private var selectedTimeFrame: TrainingExerciseChartDataGenerator.TimeFrame = .threeMonths {
        didSet {
            if exercise != nil {
                tableViewEntries = createTableViewEntries()
            }
        }
    }
    private var chartDataGenerator = TrainingExerciseChartDataGenerator(context: AppDelegate.instance.persistentContainer.viewContext)

    private class TableViewEntry {
        let measurementType: TrainingExerciseChartDataGenerator.MeasurementType
        var cache: LineChartData?

        init(measurementType: TrainingExerciseChartDataGenerator.MeasurementType) {
            self.measurementType = measurementType
        }
    }
    private var tableViewEntries = [TableViewEntry]() {
        didSet {
            tableView?.reloadData()
        }
    }

    private func createTableViewEntries() -> [TableViewEntry] {
        return TrainingExerciseChartDataGenerator.MeasurementType.allCases.map {
            TableViewEntry(measurementType: $0)
        }
    }

    private func updateChartView(styledChartView: StyledLineChartView, with entry: TableViewEntry) {
        let formatters = chartDataGenerator.formatters(for: entry.measurementType, weightUnit: settingsStore.weightUnit)
        let chartData = entry.cache ?? chartDataGenerator.chartData(for: entry.measurementType, timeFrame: selectedTimeFrame, weightUnit: settingsStore.weightUnit)
        entry.cache = chartData

        styledChartView.xAxis.valueFormatter = formatters.0
        styledChartView.leftAxis.valueFormatter = formatters.1
        styledChartView.balloonMarker.valueFormatter = formatters.2
        styledChartView.data = chartData
        styledChartView.fitScreen()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewEntries.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chart cell", for: indexPath) as! ChartCell
        let entry = tableViewEntries[indexPath.section]

        cell.detailLabel.text = exercise?.title
        cell.titleLabel.text = entry.measurementType.title

        updateChartView(styledChartView: cell.styledChartView, with: entry)

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return min(tableView.frame.width * (1/1.61), (tableView.frame.height - tableView.safeAreaInsets.top - tableView.safeAreaInsets.bottom) * 0.9) // golden ratio
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

class ChartCell: UITableViewCell {
    @IBOutlet weak var styledChartView: StyledLineChartView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
}
