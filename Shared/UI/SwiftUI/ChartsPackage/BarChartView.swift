//
//  _BarChartView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Charts

struct _BarChartView : UIViewRepresentable {
    var chartData: ChartData
    var xAxisValueFormatter: IAxisValueFormatter
    var yAxisValueFormatter: IAxisValueFormatter
    var preCustomization: ((BarChartView, ChartData) -> ())?
    var postCustomization: ((BarChartView) -> ())?

    func makeUIView(context: UIViewRepresentableContext<_BarChartView>) -> StyledBarChartView {
        StyledBarChartView()
    }
    
    func updateUIView(_ uiView: StyledBarChartView, context: UIViewRepresentableContext<_BarChartView>) {
        uiView.xAxis.valueFormatter = xAxisValueFormatter
        uiView.leftAxis.valueFormatter = yAxisValueFormatter
        preCustomization?(uiView, chartData)
        uiView.data = chartData
        uiView.fitScreen()
        postCustomization?(uiView)
    }
}
