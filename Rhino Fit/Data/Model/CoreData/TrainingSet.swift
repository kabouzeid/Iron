//
//  TrainingSet.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

class TrainingSet: NSManagedObject {
    var displayTitle: String {
        get {
            return "\(repetitions) Repetition\(repetitions == 1 ? "" : "s") x \(weight) kg" // TODO lbs support
        }
    }
}
