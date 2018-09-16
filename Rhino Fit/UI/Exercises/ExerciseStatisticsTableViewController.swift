//
//  ExerciseStatisticsTableViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 08.09.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import Charts
import Benchmark

class ExerciseStatisticsTableViewController: UITableViewController, ChartCellDelegate {

    var exercise: Exercise? {
        didSet {
            self.title = exercise?.title
            chartDataGenerator.exercise = exercise
            tableViewEntries = createTableViewEntries()
        }
    }

    private var chartDataGenerator = TrainingExerciseChartDataGenerator()

    private class TableViewEntry {
        let measurementType: TrainingExerciseChartDataGenerator.MeasurementType
        let timeFrames: [TrainingExerciseChartDataGenerator.TimeFrame]
        let segmentTitles: [String]

        var hasBeenAnimated = false
        var selectedSegmentIndex = 1

        var selectedTimeFrame: TrainingExerciseChartDataGenerator.TimeFrame {
            return timeFrames[selectedSegmentIndex]
        }

        var cache: [Int : LineChartData] = [:]

        init(measurementType: TrainingExerciseChartDataGenerator.MeasurementType, timeFrames: [TrainingExerciseChartDataGenerator.TimeFrame]) {
            self.measurementType = measurementType
            self.timeFrames = timeFrames
            self.segmentTitles = timeFrames.map { $0.title }
        }
    }
    private var tableViewEntries = [TableViewEntry]() {
        didSet {
            tableView?.reloadData()
        }
    }

    private func createTableViewEntries() -> [TableViewEntry] {
        return TrainingExerciseChartDataGenerator.MeasurementType.allCases.map {
            TableViewEntry(measurementType: $0, timeFrames: TrainingExerciseChartDataGenerator.TimeFrame.allCases)
        }
    }

    private func updateChartView(segmentedChartView: SegmentedChartView, with entry: TableViewEntry) {
        let formatters = chartDataGenerator.formatters(for: entry.measurementType, timeFrame: entry.selectedTimeFrame)
        let chartData = entry.cache[entry.selectedSegmentIndex] ?? chartDataGenerator.chartData(for: entry.measurementType, timeFrame: entry.selectedTimeFrame)
        entry.cache[entry.selectedSegmentIndex] = chartData
        segmentedChartView.updateChartView(with: chartData, xAxisFormatter: formatters.0, yAxisFormatter: formatters.1, balloonValueFormatter: formatters.2, showLegend: true)
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

        cell.delegate = self
        cell.segmentedChartView.delegate = cell
        cell.segmentedChartView.segmentTitles = entry.segmentTitles
        cell.segmentedChartView.selectedSegmentIndex = entry.selectedSegmentIndex

        updateChartView(segmentedChartView: cell.segmentedChartView, with: entry)

        if !entry.hasBeenAnimated { // animate just once
            cell.segmentedChartView.animateChartView()
            entry.hasBeenAnimated = true
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return min(tableView.frame.width * (1/1.61), (tableView.frame.height - tableView.safeAreaInsets.top - tableView.safeAreaInsets.bottom) * 0.9) // golden ratio
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    // MARK: - ChartCell

    func chartCell(_ chartCell: ChartCell, didSelectSegmentIndex: Int) {
        guard let indexPath = tableView.indexPath(for: chartCell) else { return } // should never happen
        let entry = tableViewEntries[indexPath.section]
        entry.selectedSegmentIndex = didSelectSegmentIndex

        updateChartView(segmentedChartView: chartCell.segmentedChartView, with: entry)
    }
}

protocol ChartCellDelegate: class {
    func chartCell(_ chartCell: ChartCell, didSelectSegmentIndex: Int)
}

class ChartCell: UITableViewCell, SegmentedChartViewDelegate {
    @IBOutlet weak var segmentedChartView: SegmentedChartView!

    weak var delegate: ChartCellDelegate?

    func segmentedChartView(_ segmentedChartView: SegmentedChartView, didSelectSegmentIndex: Int) {
        delegate?.chartCell(self, didSelectSegmentIndex: didSelectSegmentIndex)
    }
}
