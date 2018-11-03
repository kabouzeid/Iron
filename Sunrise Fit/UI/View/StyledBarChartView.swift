//
//  StyledBarChartView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 03.11.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import Charts

class StyledBarChartView: BarChartView {
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
                    BarLineChartViewBase.styleChartDataSet(chartDataSet: dataSet as! BarChartDataSet, color: self.tintColor, fillEnabled: true)
                }
            }
            let hasData = newValue.dataSets.reduce(into: false, { (notEmpty, dataSet) in
                notEmpty = notEmpty || (dataSet.entryCount > 0)
            })
            super.data = hasData ? newValue : nil
        }
    }
}
