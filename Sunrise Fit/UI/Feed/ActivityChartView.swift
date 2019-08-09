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
    @Environment(\.managedObjectContext) var managedObjectContext
    // TODO: update on context changes
    
    var body: some View {
        let chartInfo = TrainingsPerWeekChartInfo(context: managedObjectContext)
        return _BarChartView(chartData: chartInfo.chartData(), xAxisValueFormatter: chartInfo.xAxisValueFormatter, yAxisValueFormatter: chartInfo.yAxisValueFormatter) { chartView, chartData in
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
            .environment(\.managedObjectContext, mockManagedObjectContext)
            .previewLayout(.sizeThatFits)
    }
}
#endif
