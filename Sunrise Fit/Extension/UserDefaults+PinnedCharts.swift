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
    
    private class PinnedChartRaw: Codable {
        let exerciseId: Int
        let measurementTypeRawValue: String
        init(exerciseId: Int, measurementTypeRawValue: String) {
            self.exerciseId = exerciseId
            self.measurementTypeRawValue = measurementTypeRawValue
        }
    }
    
    var pinnedCharts: [PinnedChart] {
        get {
            guard let data = self.data(forKey: PinnedChartsKeys.pinnedChartsKey.rawValue), let pinnedCharts = try? JSONDecoder().decode([PinnedChartRaw].self, from: data) else { return [] }
            return pinnedCharts.filter {
                    TrainingExerciseChartDataGenerator.MeasurementType.init(rawValue: $0.measurementTypeRawValue) != nil
            }.map {
                PinnedChart(
                    exerciseId: $0.exerciseId,
                    measurementType: TrainingExerciseChartDataGenerator.MeasurementType.init(rawValue: $0.measurementTypeRawValue)!)
            }
        }
        set {
            let data = try? JSONEncoder().encode(newValue.uniq().map {
                PinnedChartRaw(
                    exerciseId: $0.exerciseId,
                    measurementTypeRawValue: $0.measurementType.rawValue)
            })
            self.set(data, forKey: PinnedChartsKeys.pinnedChartsKey.rawValue)
        }
    }
}
