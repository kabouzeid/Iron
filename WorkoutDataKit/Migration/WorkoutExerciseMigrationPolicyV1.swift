//
//  WorkoutExerciseMigrationPolicyV1.swift
//  Iron
//
//  Created by Karim Abou Zeid on 25.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
import os.log

class WorkoutExerciseMigrationPolicyV1: UuidMigrationPolicy {
    private static let exerciseStore = ExerciseStore(
        // not completely clean to hardcode the custom exercises path here
        customExercisesURL: FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.kabouzeid.Iron")?
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("custom_exercises").appendingPathExtension("json")
    )
    
    @objc
    func uuidForId(id: NSNumber) -> NSUUID { // don't change the func name, it is referenced from the mapping model
        guard let exercise = Self.exerciseStore.exercises.first(where: { NSNumber(value: $0.everkineticId) == id }) else {
            os_log("Could not find exercise with id=%d", log: .migration, type: .error, id) // this should actually never happen
            return reuseOrCreateUuidForId(id: id)
        }
        return exercise.uuid as NSUUID
    }
    
    // just to be safe, but shouldn't actually be needed
    private var uuidMapping = [NSNumber : NSUUID]()
    private func reuseOrCreateUuidForId(id: NSNumber) -> NSUUID {
        if let uuid = uuidMapping[id] {
            os_log("Reusing UUID for id=%d", log: .migration, type: .debug, id)
            return uuid
        }
        os_log("Creating new UUID for id=%d", log: .migration, type: .debug, id)
        let uuid = UUID() as NSUUID
        uuidMapping[id] = uuid
        return uuid
    }
}
