//
//  PinnedChartView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct PinnedChartView : UIViewRepresentable {
    var trainingsDataStore: TrainingsDataStore
    var pinnedChart: UserDefaults.PinnedChart
    
    func makeUIView(context: UIViewRepresentableContext<PinnedChartView>) -> StyledLineChartView {
        return StyledLineChartView()
    }
    
    func updateUIView(_ uiView: StyledLineChartView, context: UIViewRepresentableContext<PinnedChartView>) {
        updateChartView(chartView: uiView)
        return
    }
    
    func updateChartView(chartView: StyledLineChartView) {
        let exercise = EverkineticDataProvider.findExercise(id: pinnedChart.exerciseId)
        let chartDataGenerator = TrainingExerciseChartDataGenerator(context: trainingsDataStore.context, exercise: exercise)
        
        let formatters = chartDataGenerator.formatters(for: pinnedChart.measurementType)
        let chartData = chartDataGenerator.chartData(for: pinnedChart.measurementType, timeFrame: .threeMonths)
        
        chartView.xAxis.valueFormatter = formatters.0
        chartView.leftAxis.valueFormatter = formatters.1
        chartView.balloonMarker.valueFormatter = formatters.2
        
        chartView.data = chartData
        chartView.fitScreen()
        
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pinnedChartHeaderTapped))
//        tapGestureRecognizer.delegate = self
//        cell.chartView.addGestureRecognizer(tapGestureRecognizer)
    }
}

#if DEBUG
struct PinnedChartView_Previews : PreviewProvider {
    static var previews: some View {
        PinnedChartView(trainingsDataStore: mockTrainingsDataStore, pinnedChart: UserDefaults.PinnedChart(exerciseId: 42, measurementType: .totalRepetitions))
    }
}
#endif
