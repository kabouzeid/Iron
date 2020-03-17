//
//  WorkoutPlan.swift
//  WorkoutDataKit
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

public class WorkoutRoutineSet: NSManagedObject {
    
    // MARK: Normalized properties
    
    public var repetitionsMinValue: Int16? {
        get {
            repetitionsMin?.int16Value
        }
        set {
            repetitionsMin = newValue as NSNumber?
        }
    }
    
    public var repetitionsMaxValue: Int16? {
        get {
            repetitionsMax?.int16Value
        }
        set {
            repetitionsMax = newValue as NSNumber?
        }
    }
}
