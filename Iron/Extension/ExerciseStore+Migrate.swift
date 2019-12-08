//
//  ExerciseStore+Migrate.swift
//  Iron
//
//  Created by Karim Abou Zeid on 06.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit

extension ExerciseStore {
    static func migrateCustomExercisesToAppGroupIfNecessary() {
        if let localURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("custom_exercises").appendingPathExtension("json") {
            let groupURL = ExerciseStore.customExercisesURL
            if FileManager.default.fileExists(atPath: localURL.path) && !FileManager.default.fileExists(atPath: groupURL.path) {
                print("attempt to migrate custom exercises to app group")
                do {
                    try FileManager.default.moveItem(at: localURL, to: groupURL)
                    print("migrated custom exercises to app group")
                } catch {
                    print("could not move custom_exercises.json: \(error)")
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
        print("attempt to migrate hidden exercises to app group")
        guard let groupUserDefaults = UserDefaults(suiteName: FileManager.appGroupIdentifier) else {
            fatalError("could not create user defaults for group suite \(FileManager.appGroupIdentifier)")
        }
        
        if let uuids = hiddenExerciseUUIDs() {
            groupUserDefaults.set(uuids, forKey: hiddenExerciseUuidsKey)
        }

        UserDefaults.standard.set(true, forKey: didMigrateHiddenExercisesToAppGroup)
        print("migrated hidden exercises to app group")
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
