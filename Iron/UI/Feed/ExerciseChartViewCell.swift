//
//  PinnedChartViewCell.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct ExerciseChartViewCell : View {
    @EnvironmentObject var entitlementStore: EntitlementStore
    
    var exercise: Exercise
    var measurementType: WorkoutExerciseChartData.MeasurementType
    
    private var chartView: some View {
        Group {
            if entitlementStore.isPro {
                ExerciseChartView(exercise: exercise, measurementType: measurementType)
            } else {
                ExerciseDemoChartView(exercise: exercise, measurementType: measurementType).overlay(UnlockProOverlay())
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.title)
                .bold()
                .font(.subheadline)
                .foregroundColor(exercise.muscleGroupColor)
            
            Text(measurementType.title + (entitlementStore.isPro ? "" : " (Demo data)"))
                .font(.headline)
            
            Divider()
            
            chartView
                .frame(height: 200)
        }
        .padding([.top, .bottom], 8)
    }
}

#if DEBUG
struct PinnedChartViewCell_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            ExerciseChartViewCell(exercise: ExerciseStore.shared.exercises.first(where: { $0.everkineticId == 42 })!, measurementType: .oneRM)
                .mockEnvironment(weightUnit: .metric, isPro: true)
                .previewLayout(.sizeThatFits)
            
            List {
                ExerciseChartViewCell(exercise: ExerciseStore.shared.exercises.first(where: { $0.everkineticId == 42 })!, measurementType: .oneRM)
                    .mockEnvironment(weightUnit: .metric, isPro: true)
                    .previewLayout(.sizeThatFits)
            }.listStyleCompat_InsetGroupedListStyle()
        }
    }
}
#endif
