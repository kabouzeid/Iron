//
//  OneRepMaxView.swift
//  IronIntentsUI
//
//  Created by Karim Abou Zeid on 08.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Charts
import WorkoutDataKit

struct OneRepMaxView: View {
    let exercise: Exercise
    let highlightDate: Date
    
    private var chartView: some View {
        OneRepMaxChartView(exercise: exercise, highlightDate: highlightDate)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(exercise.title)
                .font(.body)
            
            Text(WorkoutExerciseChartData.MeasurementType.oneRM.title).font(.caption).foregroundColor(.secondary)

            chartView
        }
    }
}

struct OneRepMaxChartView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.managedObjectContext) var managedObjectContext
    
    var exercise: Exercise
    var highlightDate: Date

    private var workoutExercises: [WorkoutExercise] {
        let until = Date()
        let passedTime = until.timeIntervalSince(highlightDate)
        let from = highlightDate.addingTimeInterval(-passedTime)
        
        return (try? managedObjectContext.fetch(WorkoutExercise.historyFetchRequest(of: exercise.uuid, from: from, until: until))) ?? []
    }
    
    private var chartData: ChartData {
        WorkoutExerciseChartDataGenerator(workoutExercises: workoutExercises,evaluator: WorkoutExerciseChartData.evaluator(
            for: .oneRM,
            weightUnit: settingsStore.weightUnit,
            maxRepetitionsForOneRepMax: settingsStore.maxRepetitionsOneRepMax)
        ).lineChartData(label: WorkoutExerciseChartData.MeasurementType.oneRM.title)
    }
    
    private var xAxisFormatter: AxisValueFormatter {
        WorkoutExerciseChartData.xAxisValueFormatter(for: .oneRM, weightUnit: settingsStore.weightUnit)
    }
    
    private var yAxisFormatter: AxisValueFormatter {
        WorkoutExerciseChartData.yAxisValueFormatter(for: .oneRM, weightUnit: settingsStore.weightUnit)
    }
    
    private var balloonFormatter: BalloonValueFormatter {
        WorkoutExerciseChartData.ballonValueFormatter(for: .oneRM, weightUnit: settingsStore.weightUnit)
    }
    
    var body: some View {
        ChartsLineChartViewRepresentable(chartData: chartData, xAxisValueFormatter: xAxisFormatter, yAxisValueFormatter: yAxisFormatter, balloonValueFormatter: balloonFormatter, postCustomization:  { chartView in
            let dateValue = WorkoutExerciseChartDataGenerator.dateToValue(date: self.highlightDate)
            chartView.highlightValue(x: dateValue, dataSetIndex: 0)
        })
    }
}
