//
//  ExerciseDemoChartView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Charts

struct ExerciseDemoChartView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    var exercise: Exercise
    var measurementType: TrainingExerciseChartDataGenerator.MeasurementType
    
    private let xAxisValueFormatter = TrainingExerciseChartDataGenerator.DateAxisFormatter()
    private let yAxisValueFormatter = DefaultAxisValueFormatter(decimals: 0)

    private var chartData: LineChartData {
        let entries = stride(from: 0, to: 90, by: 5)
            .compactMap { Calendar.current.date(byAdding: .day, value: $0 - Int.random(in: 0...1), to: Date()) }
            .sorted()
            .map { ChartDataEntry(x: dateToValue(date: $0), y: newRandomDemoValue()) }
        
        
        return LineChartData(dataSet: LineChartDataSet(entries: entries, label: measurementType.title))
    }
    
    private var baseValue: Double {
        switch measurementType {
        case .oneRM:
            return 80
        case .totalWeight:
            return 1500
        case .totalSets:
            return 5
        case .totalRepetitions:
            return 30
        }
    }
    
    private func newRandomDemoValue() -> Double {
        (baseValue * Double.random(in: 1...1.2)).rounded()
    }
    
    private func dateToValue(date: Date) -> Double {
        return date.timeIntervalSince1970 / (60 * 60)
    }
    
    var body: some View {
        _LineChartView(
            chartData: chartData,
            xAxisValueFormatter: xAxisValueFormatter,
            yAxisValueFormatter: yAxisValueFormatter,
            balloonValueFormatter: nil,
            customization: { uiView, _ in uiView.isUserInteractionEnabled = false }
        )
    }
}

#if DEBUG
struct ExerciseDemoChartView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseDemoChartView(exercise: ExerciseStore.shared.find(with: 42)!, measurementType: .oneRM)
            .environmentObject(SettingsStore.mockMetric)
            .environment(\.managedObjectContext, mockManagedObjectContext)
            .previewLayout(.sizeThatFits)
    }
}
#endif
