//
//  ActivityChartView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Charts

struct ActivityChartView : View {
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    
    private var trainingsPerWeekChartInfo: TrainingsPerWeekChartInfo {
        TrainingsPerWeekChartInfo(context: trainingsDataStore.context)
    }
    
    private var chartData: ChartData {
        trainingsPerWeekChartInfo.chartData()
    }
    
    private var xAxisFormatter: IAxisValueFormatter {
        trainingsPerWeekChartInfo.xAxisValueFormatter
    }
    
    private var yAxisFormatter: IAxisValueFormatter {
        trainingsPerWeekChartInfo.yAxisValueFormatter
    }
    
    var body: some View {
        _BarChartView(chartData: chartData, xAxisValueFormatter: xAxisFormatter, yAxisValueFormatter: yAxisFormatter) { chartView, chartData in
            chartView.xAxis.labelCount = chartData.entryCount
            chartView.leftAxis.axisMinimum = 0
            chartView.dragXEnabled = false
            chartView.scaleXEnabled = false
            chartView.leftAxis.drawAxisLineEnabled = false
            chartView.xAxis.drawGridLinesEnabled = false
            chartView.isUserInteractionEnabled = false
        }
    }
}

#if DEBUG
struct ActivityChartView_Previews : PreviewProvider {
    static var previews: some View {
        ActivityChartView()
            .environmentObject(mockTrainingsDataStore)
            .previewLayout(.sizeThatFits)
    }
}
#endif
