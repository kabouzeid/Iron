//
//  PinnedChartViewCell.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct PinnedChartViewCell : View {
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    
    let pinnedChart: UserDefaults.PinnedChart
    var exercise: Exercise? { EverkineticDataProvider.findExercise(id: pinnedChart.exerciseId) }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(exercise?.title ?? "")
                .font(.body)
            Text(pinnedChart.measurementType.title)
                .font(.caption)
                .color(.secondary)
            PinnedChartView(trainingsDataStore: trainingsDataStore, pinnedChart: pinnedChart)
                .frame(height: 200)
        }
    }
}

#if DEBUG
struct PinnedChartViewCell_Previews : PreviewProvider {
    static var previews: some View {
        PinnedChartViewCell(pinnedChart: UserDefaults.PinnedChart(exerciseId: 42, measurementType: .totalRepetitions))
            .environmentObject(mockTrainingsDataStore)
    }
}
#endif
