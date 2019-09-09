//
//  ExerciseChartView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Charts

struct ExerciseChartView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.managedObjectContext) var managedObjectContext
    
    var exercise: Exercise
    var measurementType: TrainingExerciseChartDataGenerator.MeasurementType

    private func chartData(_ chartDataGenerator: TrainingExerciseChartDataGenerator) -> ChartData {
        chartDataGenerator.chartData(for: measurementType, timeFrame: .threeMonths, weightUnit: settingsStore.weightUnit, maxRepetitionsFor1rm: settingsStore.maxRepetitionsOneRepMax)
    }
    
    private func xAxisFormatter(_ chartDataGenerator: TrainingExerciseChartDataGenerator) -> IAxisValueFormatter {
        chartDataGenerator.xAxisValueFormatter(for: measurementType, weightUnit: settingsStore.weightUnit)
    }
    
    private func yAxisFormatter(_ chartDataGenerator: TrainingExerciseChartDataGenerator) -> IAxisValueFormatter {
        chartDataGenerator.yAxisValueFormatter(for: measurementType, weightUnit: settingsStore.weightUnit)
    }
    
    private func balloonFormatter(_ chartDataGenerator: TrainingExerciseChartDataGenerator) -> BalloonValueFormatter {
        chartDataGenerator.ballonValueFormatter(for: measurementType, weightUnit: settingsStore.weightUnit)
    }
    
    var body: some View {
        let chartDataGenerator = TrainingExerciseChartDataGenerator(context: managedObjectContext, exercise: exercise)
        return _LineChartView(
            chartData: chartData(chartDataGenerator),
            xAxisValueFormatter: xAxisFormatter(chartDataGenerator),
            yAxisValueFormatter: yAxisFormatter(chartDataGenerator),
            balloonValueFormatter: balloonFormatter(chartDataGenerator)
        )
    }
}

#if DEBUG
struct ExerciseChartView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseChartView(exercise: Exercises.findExercise(id: 42)!, measurementType: .oneRM)
            .environmentObject(mockSettingsStoreMetric)
            .environment(\.managedObjectContext, mockManagedObjectContext)
            .previewLayout(.sizeThatFits)
    }
}
#endif
