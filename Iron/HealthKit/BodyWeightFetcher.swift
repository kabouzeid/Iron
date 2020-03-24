//
//  BodyWeightFetcher.swift
//  Iron
//
//  Created by Karim Abou Zeid on 02.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Combine
import HealthKit

class BodyWeightFetcher: ObservableObject {
    @Published var bodyWeight: Double? // always metric (kg)
    
    private let date: Date?
    
    init(date: Date?) {
        self.date = date
    }
    
    // gets the closest body weight +-1 day to date
    func fetchBodyWeight() {
        HealthManager.shared.requestReadBodyWeightPermission {
            guard let date = self.date else { return }
            
            guard let sampleType = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }
            let predicate = HKQuery.predicateForSamples(
                withStart: Calendar.current.date(byAdding: .day, value: -1, to: date),
                end: Calendar.current.date(byAdding: .day, value: 1, to: date)
            )
            
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil) { (query, samples, error) in
                    guard let samples = samples as? [HKQuantitySample] else {
                        if let error = error { print(error) }
                        return
                    }
                    let _closestSample = samples.min { $0.startDate.distance(to: date) < $1.startDate.distance(to: date) }
                    guard let closestSample = _closestSample else { return }
                    
                    let kiloUnit = HKUnit.gramUnit(with: .kilo)
                    guard closestSample.quantity.is(compatibleWith: kiloUnit) else { return }
                    
                    DispatchQueue.main.async {
                        self.bodyWeight = closestSample.quantity.doubleValue(for: kiloUnit)
                    }
            }
            HealthManager.shared.healthStore.execute(query)
        }
    }
}
