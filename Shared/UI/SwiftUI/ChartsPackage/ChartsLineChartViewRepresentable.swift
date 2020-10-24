//
//  ChartsLineChartViewRepresentable.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Charts

struct ChartsLineChartViewRepresentable : UIViewRepresentable {
    let chartData: ChartData
    let xAxisValueFormatter: IAxisValueFormatter?
    let yAxisValueFormatter: IAxisValueFormatter?
    let balloonValueFormatter: BalloonValueFormatter?
    var preCustomization: ((Charts.LineChartView, ChartData) -> ())?
    var postCustomization: ((Charts.LineChartView) -> ())?

    func makeUIView(context: UIViewRepresentableContext<ChartsLineChartViewRepresentable>) -> StyledLineChartView {
        StyledLineChartView()
    }
    
    func updateUIView(_ uiView: StyledLineChartView, context: UIViewRepresentableContext<ChartsLineChartViewRepresentable>) {
        uiView.xAxis.valueFormatter = xAxisValueFormatter
        uiView.leftAxis.valueFormatter = yAxisValueFormatter
        uiView.balloonMarker.valueFormatter = balloonValueFormatter
        preCustomization?(uiView, chartData)
        uiView.data = chartData
        uiView.fitScreen()
        postCustomization?(uiView)
    }
}
