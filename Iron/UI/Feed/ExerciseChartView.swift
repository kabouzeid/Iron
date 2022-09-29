//
//  ExerciseChartView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Charts
import WorkoutDataKit

struct ExerciseChartView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @Environment(\.isEnabled) var isEnabled
    
    var exercise: Exercise
    var measurementType: WorkoutExerciseChartData.MeasurementType

    private var workoutExercises: [WorkoutExercise] {
        let timeFrame = WorkoutExerciseChartData.TimeFrame.threeMonths
        return (try? managedObjectContext.fetch(WorkoutExercise.historyFetchRequest(of: exercise.uuid, from: timeFrame.from, until: timeFrame.until))) ?? []
    }
    
    private var chartData: ChartData {
        WorkoutExerciseChartDataGenerator(workoutExercises: workoutExercises, evaluator: WorkoutExerciseChartData.evaluator(
            for: measurementType,
            weightUnit: settingsStore.weightUnit,
            maxRepetitionsForOneRepMax: settingsStore.maxRepetitionsOneRepMax)
        ).lineChartData(label: measurementType.title)
    }
    
    private var xAxisFormatter: AxisValueFormatter {
        WorkoutExerciseChartData.xAxisValueFormatter(for: measurementType, weightUnit: settingsStore.weightUnit)
    }
    
    private var yAxisFormatter: AxisValueFormatter {
        WorkoutExerciseChartData.yAxisValueFormatter(for: measurementType, weightUnit: settingsStore.weightUnit)
    }
    
    private var balloonFormatter: BalloonValueFormatter {
        WorkoutExerciseChartData.ballonValueFormatter(for: measurementType, weightUnit: settingsStore.weightUnit)
    }
    
    var body: some View {
        ChartsLineChartViewRepresentable(chartData: chartData, xAxisValueFormatter: xAxisFormatter, yAxisValueFormatter: yAxisFormatter, balloonValueFormatter: balloonFormatter, preCustomization: { chartView, data in
            chartView.isUserInteractionEnabled = isEnabled
            if isEnabled {
                if #available(iOS 14.0, *) {
                    chartView.tintColor = UIColor(exercise.muscleGroupColor)
                } else {
                    chartView.tintColor = .systemBlue
                }
            } else {
                if #available(iOS 14.0, *) {
                    chartView.tintColor = UIColor(.accentColor)
                } else {
                    chartView.tintColor = .systemBlue
                }
            }
        })
    }
}

#if DEBUG
struct ExerciseChartView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseChartView(exercise: ExerciseStore.shared.exercises.first(where: { $0.everkineticId == 42 })!, measurementType: .oneRM)
            .environmentObject(SettingsStore.mockMetric)
            .environment(\.managedObjectContext, MockWorkoutData.metricRandom.context)
            .previewLayout(.sizeThatFits)
    }
}
#endif
