//
//  _LineChartView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Charts

struct _LineChartView : UIViewRepresentable {
    let chartData: ChartData
    let xAxisValueFormatter: IAxisValueFormatter?
    let yAxisValueFormatter: IAxisValueFormatter?
    let balloonValueFormatter: BalloonValueFormatter?
    var customization: ((LineChartView, ChartData) -> ())?

    func makeUIView(context: UIViewRepresentableContext<_LineChartView>) -> StyledLineChartView {
        StyledLineChartView()
    }
    
    func updateUIView(_ uiView: StyledLineChartView, context: UIViewRepresentableContext<_LineChartView>) {
        uiView.xAxis.valueFormatter = xAxisValueFormatter
        uiView.leftAxis.valueFormatter = yAxisValueFormatter
        uiView.balloonMarker.valueFormatter = balloonValueFormatter
        customization?(uiView, chartData)
        uiView.data = chartData
        uiView.fitScreen()
    }
}
