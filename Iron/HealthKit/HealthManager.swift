//
//  HealthManager.swift
//  Iron
//
//  Created by Karim Abou Zeid on 02.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import HealthKit

class HealthManager {
    static let shared = HealthManager()
    
    let healthStore: HKHealthStore
    
    private init() {
        self.healthStore = HKHealthStore()
    }
}

extension HealthManager {
    private func requestPermissions(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping () -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            guard success else {
                if let error = error { print(error) }
                return
            }
            completion()
        }
    }
    
    func requestReadBodyWeightPermission(completion: @escaping () -> Void) {
        let read = Set([
            HKObjectType.quantityType(forIdentifier: .bodyMass)
        ].compactMap { $0 })
        requestPermissions(toShare: nil, read: read, completion: completion)
    }
    
    func requestShareWorkoutPermission(completion: @escaping () -> Void) {
        let share: Set = [HKObjectType.workoutType()]
        requestPermissions(toShare: share, read: nil, completion: completion)
    }
}
