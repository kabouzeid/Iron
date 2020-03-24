//
//  WorkoutDataKit+Identifieable.swift
//  Iron
//
//  Created by Karim Abou Zeid on 24.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit
import CoreData

extension Workout: Identifiable {
    public var id: NSManagedObjectID { self.objectID }
}

extension WorkoutExercise: Identifiable {
    public var id: NSManagedObjectID { self.objectID }
}

extension WorkoutSet: Identifiable {
    public var id: NSManagedObjectID { self.objectID }
}

extension WorkoutPlan: Identifiable {
    public var id: NSManagedObjectID { self.objectID }
}

extension WorkoutRoutine: Identifiable {
    public var id: NSManagedObjectID { self.objectID }
}

extension WorkoutRoutineExercise: Identifiable {
    public var id: NSManagedObjectID { self.objectID }
}

extension WorkoutRoutineSet: Identifiable {
    public var id: NSManagedObjectID { self.objectID }
}
