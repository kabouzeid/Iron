//
//  ExerciseStatisticsView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 06.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Charts

struct ExerciseStatisticsView : View {
    var exercise: Exercise
    
    var body: some View {
        List(TrainingExerciseChartDataGenerator.MeasurementType.allCases, id: \.self) { measurementType in
            ExerciseChartViewCell(exercise: self.exercise, measurementType: measurementType)
        }
    }
}

#if DEBUG
struct ExerciseStatisticsView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseStatisticsView(exercise: appExerciseStore.find(with: 99)!)
            .environmentObject(mockSettingsStoreMetric)
            .environment(\.managedObjectContext, mockManagedObjectContext)
    }
}
#endif
