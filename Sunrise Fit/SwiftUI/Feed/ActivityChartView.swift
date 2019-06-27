//
//  ActivityChartView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Charts

struct ActivityChartView : UIViewRepresentable {
    @ObjectBinding var trainingsDataStore: TrainingsDataStore
    
    func makeUIView(context: UIViewRepresentableContext<ActivityChartView>) -> StyledBarChartView {
        return StyledBarChartView()
    }
    
    func updateUIView(_ uiView: StyledBarChartView, context: UIViewRepresentableContext<ActivityChartView>) {
        updateChartView(chartView: uiView)
        return
    }
    
    func updateChartView(chartView: StyledBarChartView) {
        let trainingsPerWeekChartInfo = TrainingsPerWeekChartInfo(context: trainingsDataStore.context)
        let chartData = trainingsPerWeekChartInfo.chartData()

        chartView.xAxis.valueFormatter = trainingsPerWeekChartInfo.xAxisValueFormatter
        chartView.leftAxis.valueFormatter = trainingsPerWeekChartInfo.yAxisValueFormatter
        
        chartView.xAxis.labelCount = chartData.entryCount
        chartView.leftAxis.axisMinimum = 0
        chartView.dragXEnabled = false
        chartView.scaleXEnabled = false
        chartView.leftAxis.drawAxisLineEnabled = false
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.isUserInteractionEnabled = false
        
        chartView.data = chartData
        chartView.fitScreen()
    }
}

#if DEBUG
struct ActivityChartView_Previews : PreviewProvider {
    static var previews: some View {
        return ActivityChartView(trainingsDataStore: mockTrainingsDataStore)
    }
}
#endif
