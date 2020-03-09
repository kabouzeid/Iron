//
//  ExerciseStore+Migrate.swift
//  Iron
//
//  Created by Karim Abou Zeid on 06.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit
import os.log

extension ExerciseStore {
    static func migrateCustomExercisesToAppGroupIfNecessary() {
        if let localURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("custom_exercises").appendingPathExtension("json") {
            let groupURL = ExerciseStore.customExercisesURL
            if FileManager.default.fileExists(atPath: localURL.path) && !FileManager.default.fileExists(atPath: groupURL.path) {
                os_log("Migrating custom exercises to app group", log: .migration, type: .default)
                do {
                    os_log("Moving %@ to %@", log: .migration, type: .debug, localURL.path, groupURL.path)
                    try FileManager.default.moveItem(at: localURL, to: groupURL)
                    os_log("Successfully migrated custom exercises to app group", log: .migration, type: .info)
                } catch {
                    os_log("Could not move custom exercises file to app group: %{public}@", log: .migration, type: .fault, error.localizedDescription)
                }
            }
        }
    }
}

extension ExerciseStore {
    private static let hiddenExerciseUuidsKey = "hiddenExerciseUuids"
    
    static func migrateHiddenExercisesToAppGroupIfNecessary() {
        let didMigrateHiddenExercisesToAppGroup = "didMigrateHiddenExercisesToAppGroup"
        guard !UserDefaults.standard.bool(forKey: didMigrateHiddenExercisesToAppGroup) else { return }
        os_log("Migrating hidden exercises to app group", log: .migration, type: .default)
        guard let groupUserDefaults = UserDefaults(suiteName: FileManager.appGroupIdentifier) else {
            fatalError("Could not create user defaults for group suite \(FileManager.appGroupIdentifier)")
        }
        
        if let uuids = hiddenExerciseUUIDs() {
            groupUserDefaults.set(uuids, forKey: hiddenExerciseUuidsKey)
        }

        UserDefaults.standard.set(true, forKey: didMigrateHiddenExercisesToAppGroup)
        os_log("Successfully migrated hidden exercises to app group", log: .migration, type: .info)
    }
    
    private static func hiddenExerciseUUIDs() -> [String]? {
        if let uuids = UserDefaults.standard.array(forKey: hiddenExerciseUuidsKey) as? [String] {
            return uuids
        }
        
        if let ids = UserDefaults.standard.array(forKey: hiddenExerciseUuidsKey) as? [Int] {
            return ids.compactMap { id in ExerciseStore.shared.exercises.first { exercise in exercise.everkineticId == id }?.uuid.uuidString }
        }
        
        return nil
    }
}
