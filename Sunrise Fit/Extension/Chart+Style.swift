//
//  BarLineChartViewBaseExtension.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 03.11.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import Charts

extension BarLineChartViewBase {
    func setupStyle() {
        // general
        self.dragYEnabled = false
        self.scaleYEnabled = false
        self.doubleTapToZoomEnabled = false
        self.legend.enabled = false
        self.chartDescription?.enabled = false
        
        let gridColor = UIColor.systemGray5
        let axisLineColor = UIColor.systemGray4
        let labelColor = UIColor.tertiaryLabel
        
        // Y Axis
        self.leftAxis.gridColor = gridColor
        self.leftAxis.axisLineColor = axisLineColor
        self.leftAxis.labelTextColor = labelColor
        self.leftAxis.labelFont = .boldSystemFont(ofSize: 10)
        self.leftAxis.granularity = 1
        self.leftAxis.granularityEnabled = true
        
        self.rightAxis.enabled = false
        self.rightAxis.gridColor = gridColor
        self.rightAxis.axisLineColor = axisLineColor
        self.rightAxis.labelTextColor = labelColor
        self.rightAxis.labelFont = .boldSystemFont(ofSize: 10)
        self.rightAxis.granularity = 1
        self.rightAxis.granularityEnabled = true
        
        // X Axis
        self.xAxis.labelCount = 4
        self.xAxis.labelPosition = .bottom
        self.xAxis.granularity = 1
        self.xAxis.granularityEnabled = true
        self.xAxis.gridColor = gridColor
        self.xAxis.axisLineColor = axisLineColor
        self.xAxis.labelTextColor = labelColor
        self.xAxis.labelFont = .boldSystemFont(ofSize: 10) // try caption
        
        // legend
        self.legend.enabled = false
        self.legend.form = Legend.Form.circle
        self.legend.font = .boldSystemFont(ofSize: 10)
        self.legend.textColor = labelColor
        
        // no data
        self.noDataText = "No data available"
        self.noDataFont = UIFont.preferredFont(forTextStyle: .body)
        self.noDataTextColor = .secondaryLabel
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
        chartDataSet.mode = .linear
        chartDataSet.cubicIntensity = 0.05
        chartDataSet.drawHorizontalHighlightIndicatorEnabled = false
        chartDataSet.highlightColor = color
        chartDataSet.highlightLineWidth = 2
        
//        chartDataSet.drawFilledEnabled = fillEnabled
//        if fillEnabled {
//            let gradientColors = [color.withAlphaComponent(0).cgColor,
//                                  color.withAlphaComponent(0.8).cgColor]
//            let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
//
//            chartDataSet.fillAlpha = 1 // TODO: could be replaced with 0.8?
//            chartDataSet.fill = Fill(linearGradient: gradient, angle: 90)
//        }
    }
    
    // use this in the DataLoader funcs for optimal styling
    static func styleChartDataSet(chartDataSet: BarChartDataSet, color: UIColor, fillEnabled: Bool) {
        chartDataSet.drawValuesEnabled = false
        chartDataSet.setColor(color)
//        chartDataSet.highlightColor = color
//        chartDataSet.highlightLineWidth = 2
        
//        if fillEnabled {
//            let gradientColors = [color.withAlphaComponent(0).cgColor,
//                                  color.withAlphaComponent(0.8).cgColor]
//            let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
//
//            chartDataSet.fillAlpha = 1 // TODO: could be replaced with 0.8?
//            chartDataSet.fill = Fill(linearGradient: gradient, angle: 90)
//            chartDataSet.
//        }
    }
    
    func animate() { // convenience
        self.animate(yAxisDuration: 0.8, easingOption: .easeOutCubic)
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
