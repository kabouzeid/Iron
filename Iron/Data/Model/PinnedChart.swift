//
//  PinnedChart.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

struct PinnedChart: Hashable, Codable {
    let exerciseUuid: UUID
    let measurementType: WorkoutExerciseChartData.MeasurementType
}

extension WorkoutExerciseChartData.MeasurementType: Codable {}
