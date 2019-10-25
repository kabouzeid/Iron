//
//  UserDefaults+PinnedCharts.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 03.11.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

extension UserDefaults {
    enum PinnedChartsKeys: String {
        case pinnedChartsKey
    }
    
    var pinnedCharts: [PinnedChart] {
        set {
            let data = try? JSONEncoder().encode(newValue.uniqed())
            self.set(data, forKey: PinnedChartsKeys.pinnedChartsKey.rawValue)
        }
        get {
            guard let data = self.data(forKey: PinnedChartsKeys.pinnedChartsKey.rawValue) else { return [] }
            if let pinnedCharts = try? JSONDecoder().decode([PinnedChart].self, from: data) {
                return pinnedCharts
            }
            
            // TODO: remove in future
            print("Trying to decode pinnedChartUuids as Ids")
            if let pinnedChartsOld = try? JSONDecoder().decode([PinnedChartOldId].self, from: data) {
                let pinnedCharts: [PinnedChart] = pinnedChartsOld.compactMap { pinnedChart in
                    guard let uuid = ExerciseStore.shared.exercises.first(where: { exercise in exercise.everkineticId == pinnedChart.exerciseId })?.uuid else { return nil }
                    return PinnedChart(exerciseUuid: uuid, measurementType: pinnedChart.measurementType)
                }
                self.pinnedCharts = pinnedCharts
                return pinnedCharts
            }
            
            return []
        }
    }
    
    // TODO: remove in future
    private struct PinnedChartOldId: Hashable, Codable {
        let exerciseId: Int
        let measurementType: WorkoutExerciseChartDataGenerator.MeasurementType
    }

}
