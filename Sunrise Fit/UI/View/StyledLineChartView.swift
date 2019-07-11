//
//  SegmentedChartView.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 12.09.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import Charts

class StyledLineChartView: LineChartView {
    private(set) var balloonMarker: BalloonMarker!
    var autoStyleData: Bool = true

    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        self.extraTopOffset = self.layoutMargins.top
        self.extraLeftOffset = self.layoutMargins.left
        self.extraRightOffset = self.layoutMargins.right
        self.extraBottomOffset = self.layoutMargins.bottom
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
        setupStyle()
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
                    BarLineChartViewBase.styleChartDataSet(chartDataSet: dataSet as! LineChartDataSet, color: self.tintColor, fillEnabled: true)
                }
            }
            let hasData = newValue.dataSets.reduce(into: false, { (notEmpty, dataSet) in
                notEmpty = notEmpty || (dataSet.entryCount > 0)
            })
            super.data = hasData ? newValue : nil
        }
    }
}
