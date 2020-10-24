//
//  ChartsBarChartViewRepresentable.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Charts

struct ChartsBarChartViewRepresentable : UIViewRepresentable {
    var chartData: ChartData
    var xAxisValueFormatter: IAxisValueFormatter
    var yAxisValueFormatter: IAxisValueFormatter
    var preCustomization: ((Charts.BarChartView, ChartData) -> ())?
    var postCustomization: ((Charts.BarChartView) -> ())?

    func makeUIView(context: UIViewRepresentableContext<ChartsBarChartViewRepresentable>) -> StyledBarChartView {
        StyledBarChartView()
    }
    
    func updateUIView(_ uiView: StyledBarChartView, context: UIViewRepresentableContext<ChartsBarChartViewRepresentable>) {
        uiView.xAxis.valueFormatter = xAxisValueFormatter
        uiView.leftAxis.valueFormatter = yAxisValueFormatter
        preCustomization?(uiView, chartData)
        uiView.data = chartData
        uiView.fitScreen()
        postCustomization?(uiView)
    }
}
