//
//  WorkoutDataKit+Identifieable.swift
//  Iron
//
//  Created by Karim Abou Zeid on 24.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit

extension Workout: Identifiable {
    public var id: UUID? { self.uuid }
}

extension WorkoutExercise: Identifiable {
    public var id: UUID? { self.uuid }
}

extension WorkoutSet: Identifiable {
    public var id: UUID? { self.uuid }
}

extension WorkoutPlan: Identifiable {
    public var id: UUID? { self.uuid }
}

extension WorkoutRoutine: Identifiable {
    public var id: UUID? { self.uuid }
}

extension WorkoutRoutineExercise: Identifiable {
    public var id: UUID? { self.uuid }
}

extension WorkoutRoutineSet: Identifiable {
    public var id: UUID? { self.uuid }
}
