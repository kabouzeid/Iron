//
//  WorkoutExerciseMigrationPolicyV1_V2.swift
//  Iron
//
//  Created by Karim Abou Zeid on 25.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

class WorkoutExerciseMigrationPolicyV1_V2: NSEntityMigrationPolicy {
    
    @objc
    func uuidForId(id: NSNumber) -> NSUUID { // don't change the func name, it is referenced from the mapping model
        guard let exercise = ExerciseStore.shared.exercises.first(where: { NSNumber(value: $0.everkineticId) == id }) else {
            print("Couldn't find exercise with id \(id).") // this should actually never happen
            return reuseOrCreateUuidForId(id: id)
        }
        return exercise.uuid as NSUUID
    }
    
    // just to be safe, but shouldn't actually be needed
    private var uuidMapping = [NSNumber : NSUUID]()
    private func reuseOrCreateUuidForId(id: NSNumber) -> NSUUID {
        if let uuid = uuidMapping[id] {
            print("Reusing UUID for id \(id)")
            return uuid
        }
        print("Creating new UUID for id \(id)")
        let uuid = UUID() as NSUUID
        uuidMapping[id] = uuid
        return uuid
    }
}
