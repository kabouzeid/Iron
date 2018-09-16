//
//  SegmentedChartView.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 12.09.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import Charts

protocol SegmentedChartViewDelegate: class {
    func segmentedChartView(_ segmentedChartView: SegmentedChartView, didSelectSegmentIndex: Int)
}

class SegmentedChartView: UIView {
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var chartView: LineChartView!
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        delegate?.segmentedChartView(self, didSelectSegmentIndex: segmentedControl.selectedSegmentIndex)
    }

    weak var delegate: SegmentedChartViewDelegate?

    var segmentTitles = [String]() {
        didSet {
            segmentedControl.removeAllSegments()
            for (i, title) in segmentTitles.enumerated() {
                segmentedControl.insertSegment(withTitle: title, at: i, animated: false)
            }
        }
    }

    var selectedSegmentIndex: Int {
        get {
            return segmentedControl.selectedSegmentIndex
        }
        set {
            segmentedControl.selectedSegmentIndex = newValue
        }
    }

    private var balloonMarker: BalloonMarker!

    func updateChartView(with data: LineChartData, xAxisFormatter: IAxisValueFormatter? = nil, yAxisFormatter: IAxisValueFormatter? = nil, balloonValueFormatter: BalloonValueFormatter? = nil, showLegend: Bool = false, styleData: Bool = true) {
        chartView.highlightValues(nil) // reset highlighted values

        chartView.dragYEnabled = false
        chartView.scaleYEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.legend.enabled = false
        chartView.chartDescription?.enabled = false
        chartView.extraTopOffset = 28 // for the balloon marker
        balloonMarker.valueFormatter = balloonValueFormatter
        chartView.marker = balloonMarker

        chartView.rightAxis.enabled = false
        chartView.leftAxis.gridColor = .veryLightGray
        chartView.leftAxis.axisLineColor = .lightGray
        chartView.leftAxis.labelTextColor = .lightGray
        chartView.leftAxis.labelFont = .boldSystemFont(ofSize: 10)
        chartView.leftAxis.valueFormatter = yAxisFormatter
        chartView.leftAxis.granularity = 1
        chartView.leftAxis.granularityEnabled = true

        chartView.xAxis.labelCount = 4
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.valueFormatter = xAxisFormatter
        chartView.xAxis.granularity = 1
        chartView.xAxis.granularityEnabled = true
        chartView.xAxis.gridColor = .veryLightGray
        chartView.xAxis.axisLineColor = .lightGray
        chartView.xAxis.labelTextColor = .lightGray
        chartView.xAxis.labelFont = .boldSystemFont(ofSize: 10)

        chartView.legend.enabled = showLegend
        chartView.legend.form = Legend.Form.circle
        chartView.legend.font = .boldSystemFont(ofSize: 10)
        chartView.legend.textColor = .lightGray

        if styleData {
            for dataSet in data.dataSets {
                SegmentedChartView.styleChartDataSet(chartDataSet: dataSet as! LineChartDataSet, color: chartView.tintColor, fillEnabled: true)
            }
        }

        let hasData = data.dataSets.reduce(into: false, { (notEmpty, dataSet) in
            notEmpty = notEmpty || (dataSet.entryCount > 0)
        })
        chartView.data = hasData ? data : nil

//        chartView.minOffset = chartView.xAxis.labelWidth.rounded(.up) / 2)
        chartView.minOffset = 12 // 8 margin + 4 circle radius
    }

    // use this in the DataLoader funcs for optimal styling
    static func styleChartDataSet(chartDataSet: LineChartDataSet, color: UIColor, fillEnabled: Bool) {
        chartDataSet.drawValuesEnabled = false
        chartDataSet.lineWidth = 3
        chartDataSet.circleRadius = 4
        chartDataSet.setColor(color)
        chartDataSet.setCircleColor(color)
        chartDataSet.drawCircleHoleEnabled = true
        chartDataSet.circleHoleRadius = 1.5
        chartDataSet.mode = .horizontalBezier
        chartDataSet.cubicIntensity = 0.05
        chartDataSet.drawHorizontalHighlightIndicatorEnabled = false
        chartDataSet.highlightColor = color
        chartDataSet.highlightLineWidth = 2

        chartDataSet.drawFilledEnabled = fillEnabled
        if fillEnabled {
            let gradientColors = [color.withAlphaComponent(0).cgColor,
                                  color.withAlphaComponent(0.8).cgColor]
            let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!

            chartDataSet.fillAlpha = 1 // TODO: could be replaced with 0.8?
            chartDataSet.fill = Fill(linearGradient: gradient, angle: 90)
        }
    }

    func animateChartView() {
        chartView.animate(yAxisDuration: 0.8, easingOption: .easeOutCubic)
    }

    // MARK: - NIB
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        self.addSubview(view)

        balloonMarker = BalloonMarker(chartView: chartView)
    }

    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "SegmentedChartView", bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
}
