//
//  UserDefaultsExtension.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 03.11.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

extension UserDefaults {
    enum Keys: String {
        case pinnedCharstKey
    }
    
    private class PinnedChartRaw: Codable {
        let exerciseId: Int
        let measurementTypeRawValue: String
        init(exerciseId: Int, measurementTypeRawValue: String) {
            self.exerciseId = exerciseId
            self.measurementTypeRawValue = measurementTypeRawValue
        }
    }
    
    struct PinnedChart {
        let exerciseId: Int
        let measurementType: TrainingExerciseChartDataGenerator.MeasurementType
    }
    
    func pinnedCharts() -> [PinnedChart] {
        if let data = self.data(forKey: Keys.pinnedCharstKey.rawValue),
            let pinnedCharts = try? JSONDecoder().decode([PinnedChartRaw].self, from: data) {
            let pinnedCharts = pinnedCharts.filter { TrainingExerciseChartDataGenerator.MeasurementType.init(rawValue: $0.measurementTypeRawValue) != nil }
            return pinnedCharts.map {
                PinnedChart(
                    exerciseId: $0.exerciseId,
                    measurementType: TrainingExerciseChartDataGenerator.MeasurementType.init(rawValue: $0.measurementTypeRawValue)!)
            }
        }
        return []
    }
    
    func setPinnedCharts(pinnedCharts: [PinnedChart]) {
        let data = try? JSONEncoder().encode(pinnedCharts.map {
            PinnedChartRaw(
                exerciseId: $0.exerciseId,
                measurementTypeRawValue: $0.measurementType.rawValue)
        })
        self.set(data, forKey: Keys.pinnedCharstKey.rawValue)
    }
    
    func addPinnedChart(exerciseId: Int, measurmentType: TrainingExerciseChartDataGenerator.MeasurementType) {
        var values = pinnedCharts()
        if (values.contains { $0.exerciseId == exerciseId && $0.measurementType == measurmentType }) {
            return
        }
        values.append(PinnedChart(exerciseId: exerciseId, measurementType: measurmentType))
        setPinnedCharts(pinnedCharts: values)
    }

    func removePinnedChart(exerciseId: Int, measurmentType: TrainingExerciseChartDataGenerator.MeasurementType) {
        var values = pinnedCharts()
        values.removeAll { $0.exerciseId == exerciseId && $0.measurementType == measurmentType }
        setPinnedCharts(pinnedCharts: values)
    }
    
    func hasPinnedChart(exerciseId: Int, measurmentType: TrainingExerciseChartDataGenerator.MeasurementType) -> Bool {
        return pinnedCharts().contains { $0.exerciseId == exerciseId && $0.measurementType == measurmentType }
    }
}
