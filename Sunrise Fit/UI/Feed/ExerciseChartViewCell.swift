//
//  PinnedChartViewCell.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ExerciseChartViewCell : View {
    var exercise: Exercise
    var measurementType: TrainingExerciseChartDataGenerator.MeasurementType
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(exercise.title)
                .font(.body)
            Text(measurementType.title)
                .font(.caption)
                .foregroundColor(.secondary)
            ExerciseChartView(exercise: exercise, measurementType: measurementType)
                .frame(height: 200)
        }
    }
}

#if DEBUG
struct PinnedChartViewCell_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseChartViewCell(exercise: EverkineticDataProvider.findExercise(id: 42)!, measurementType: .oneRM)
            .environmentObject(mockSettingsStoreMetric)
            .environment(\.managedObjectContext, mockManagedObjectContext)
            .previewLayout(.sizeThatFits)
    }
}
#endif
