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
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    var exercise: Exercise
    var measurementType: TrainingExerciseChartDataGenerator.MeasurementType

    private var chartDataGenerator: TrainingExerciseChartDataGenerator {
        TrainingExerciseChartDataGenerator(context: trainingsDataStore.context, exercise: exercise)
    }
    
    private var chartData: ChartData {
        chartDataGenerator.chartData(for: measurementType, timeFrame: .threeMonths, weightUnit: settingsStore.weightUnit)
    }
    
    private var xAxisFormatter: IAxisValueFormatter {
        chartDataGenerator.formatters(for: measurementType, weightUnit: settingsStore.weightUnit).0
    }
    
    private var yAxisFormatter: IAxisValueFormatter {
        chartDataGenerator.formatters(for: measurementType, weightUnit: settingsStore.weightUnit).1
    }
    
    private var balloonFormatter: BalloonValueFormatter {
        chartDataGenerator.formatters(for: measurementType, weightUnit: settingsStore.weightUnit).2
    }
    
    var body: some View {
        _LineChartView(chartData: chartData, xAxisValueFormatter: xAxisFormatter, yAxisValueFormatter: yAxisFormatter, balloonValueFormatter: balloonFormatter)
    }
}

#if DEBUG
struct ExerciseChartView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseChartView(exercise: EverkineticDataProvider.findExercise(id: 42)!, measurementType: .oneRM)
            .environmentObject(mockTrainingsDataStore)
            .environmentObject(mockSettingsStoreMetric)
            .previewLayout(.sizeThatFits)
    }
}
#endif
