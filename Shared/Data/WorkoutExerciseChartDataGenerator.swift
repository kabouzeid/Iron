//
//  WorkoutExerciseChartDataGenerator.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 16.09.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
import Charts
import WorkoutDataKit

enum WorkoutExerciseChartData {
    static func xAxisValueFormatter(for measurementType: MeasurementType, weightUnit: WeightUnit) -> IAxisValueFormatter {
        WorkoutExerciseChartDataGenerator.DateAxisFormatter()
    }
    
    static func yAxisValueFormatter(for measurementType: MeasurementType, weightUnit: WeightUnit) -> IAxisValueFormatter {
        DefaultAxisValueFormatter(decimals: 0)
    }
    
    static func ballonValueFormatter(for measurementType: MeasurementType, weightUnit: WeightUnit) -> BalloonValueFormatter {
        switch measurementType {
        case .oneRM, .totalWeight:
            return WorkoutExerciseChartDataGenerator.DateBalloonValueFormatter(yUnit: weightUnit.unit.symbol)
        case .totalSets, .totalRepetitions:
            return WorkoutExerciseChartDataGenerator.DateBalloonValueFormatter(yUnit: nil)
        }
    }

    static func evaluator(for measurementType: MeasurementType, weightUnit: WeightUnit, maxRepetitionsForOneRepMax: Int) -> WorkoutExerciseChartDataGenerator.Evaluator {
        switch measurementType {
        case .oneRM:
            return {
                $0.workoutSets?
                    .compactMap { $0 as? WorkoutSet }
                    .compactMap { $0.estimatedOneRepMax(maxReps: maxRepetitionsForOneRepMax) }
                    .max()
                    .map { WeightUnit.convert(weight: $0, from: .metric, to: weightUnit) }
            }
        case .totalWeight:
            return  { $0.totalCompletedWeight.map { WeightUnit.convert(weight: Double($0), from: .metric, to: weightUnit) } }
        case .totalSets:
            return { $0.numberOfCompletedSets.map { Double($0) } }
        case .totalRepetitions:
            return  { $0.numberOfCompletedRepetitions.map { Double($0) } }
        }
    }
    
    static func workoutExercises(uuid: UUID, timeFrame: TimeFrame, context: NSManagedObjectContext) -> [WorkoutExercise]? {
        try? context.fetch(WorkoutExercise.historyFetchRequest(of: uuid, from: timeFrame.from, until: timeFrame.until))
    }
    
    // MARK: - Enums
    enum MeasurementType: String, CaseIterable {
        case oneRM
        case totalWeight
        case totalSets
        case totalRepetitions

        var title: String {
            switch self {
            case .oneRM:
                return "Estimated 1RM"
            case .totalWeight:
                return "Total Weight"
            case .totalSets:
                return "Total Sets"
            case .totalRepetitions:
                return "Total Repetitions"
            }
        }
    }

    enum TimeFrame: CaseIterable {
        case month
        case threeMonths
        case year
        case all

        var title: String {
            switch self {
            case .month:
                return "Month"
            case .threeMonths:
                return "3 Months"
            case .year:
                return "Year"
            case .all:
                return "All"
            }
        }
        
        var from: Date? {
            switch self {
            case .month:
                return Calendar.current.date(byAdding: .month, value: -1, to: Date())
            case .threeMonths:
                return Calendar.current.date(byAdding: .month, value: -3, to: Date())
            case .year:
                return Calendar.current.date(byAdding: .year, value: -1, to: Date())!
            case .all:
                return nil
            }
        }
        
        var until: Date? { nil }
    }
}
