//
//  SegmentedChartView.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 12.09.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import Charts

class StyledChartView: LineChartView {
    private(set) var balloonMarker: BalloonMarker!
    var autoStyleData: Bool = true

    var headerViewSpacing: CGFloat = 8 {
        didSet {
            self.extraTopOffset = calculateExtraTopOffset()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        assert(subviews.count <= 1, "Not more than one subview supported")
        if let headerView = subviews.first {
            headerView.translatesAutoresizingMaskIntoConstraints = false
            headerView.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor, constant: 0).isActive = true
            headerView.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor, constant: 0).isActive = true
            self.layoutMarginsGuide.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: 0).isActive = true
        }
        self.extraTopOffset = calculateExtraTopOffset()
    }

    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        self.extraTopOffset = calculateExtraTopOffset()
        self.extraLeftOffset = self.layoutMargins.left
        self.extraRightOffset = self.layoutMargins.right
        self.extraBottomOffset = self.layoutMargins.bottom
    }

    private func calculateExtraTopOffset() -> CGFloat {
        let headerView = subviews.first
        return (headerView != nil ? headerView!.frame.height + headerViewSpacing : 0) + self.layoutMargins.top
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    private func setup() {
        balloonMarker = BalloonMarker(chartView: self)
        self.marker = balloonMarker

        // general
        self.dragYEnabled = false
        self.scaleYEnabled = false
        self.doubleTapToZoomEnabled = false
        self.legend.enabled = false
        self.chartDescription?.enabled = false

        // Y Axis
        self.leftAxis.gridColor = .veryLightGray
        self.leftAxis.axisLineColor = .lightGray
        self.leftAxis.labelTextColor = .lightGray
        self.leftAxis.labelFont = .boldSystemFont(ofSize: 10)
        self.leftAxis.granularity = 1
        self.leftAxis.granularityEnabled = true

        self.rightAxis.enabled = false
        self.rightAxis.gridColor = .veryLightGray
        self.rightAxis.axisLineColor = .lightGray
        self.rightAxis.labelTextColor = .lightGray
        self.rightAxis.labelFont = .boldSystemFont(ofSize: 10)
        self.rightAxis.granularity = 1
        self.rightAxis.granularityEnabled = true

        // X Axis
        self.xAxis.labelCount = 4
        self.xAxis.labelPosition = .bottom
        self.xAxis.granularity = 1
        self.xAxis.granularityEnabled = true
        self.xAxis.gridColor = .veryLightGray
        self.xAxis.axisLineColor = .lightGray
        self.xAxis.labelTextColor = .lightGray
        self.xAxis.labelFont = .boldSystemFont(ofSize: 10)

        // legend
        self.legend.enabled = false
        self.legend.form = Legend.Form.circle
        self.legend.font = .boldSystemFont(ofSize: 10)
        self.legend.textColor = .lightGray

        // no data
        self.noDataText = "No data available"
        self.noDataFont = UIFont.preferredFont(forTextStyle: .headline)
        self.noDataTextColor = .lightGray
    }


    override var data: ChartData? {
        get {
            return super.data
        }
        set {
            self.highlightValues(nil) // reset highlighted values
            guard let newValue = newValue else { super.data = nil; return }
            if autoStyleData {
                for dataSet in newValue.dataSets {
                    StyledChartView.styleChartDataSet(chartDataSet: dataSet as! LineChartDataSet, color: self.tintColor, fillEnabled: true)
                }
            }
            let hasData = newValue.dataSets.reduce(into: false, { (notEmpty, dataSet) in
                notEmpty = notEmpty || (dataSet.entryCount > 0)
            })
            super.data = hasData ? newValue : nil
        }
    }

    override var extraTopOffset: CGFloat {
        get {
            return super.extraTopOffset
        }
        set {
            balloonMarker.offset.y = newValue
            super.extraTopOffset = newValue
        }
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

    // convenience
    func animate() {
        self.animate(yAxisDuration: 0.8, easingOption: .easeOutCubic)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        UIView.animate(withDuration: 0.1) {
            self.subviews.first?.alpha = self.markerVisible() ? 0 : 1
        }
    }

    func markerVisible() -> Bool {
        if marker == nil || !isDrawMarkersEnabled || !valuesToHighlight() {
            return false
        }
        for highlight in highlighted {
            let pos = getMarkerPosition(highlight: highlight)
            if viewPortHandler.isInBounds(x: pos.x, y: pos.y) {
                return true
            }
        }
        return false
    }
}
