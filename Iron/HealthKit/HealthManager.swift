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
    func requestPermissions(completion: @escaping () -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let share: Set = [HKObjectType.workoutType()]
        
        healthStore.requestAuthorization(toShare: share, read: nil) { (success, error) in
            guard success else {
                if let error = error { print(error) }
                return
            }
            completion()
        }
    }
}
