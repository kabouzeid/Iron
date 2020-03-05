//
//  WorkoutDataStorage+Migrate.swift
//  Iron
//
//  Created by Karim Abou Zeid on 06.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit
import os.log

extension WorkoutDataStorage {
    static func migrateToAppGroupIfNecessary() {
        // check if we need to migrate the stores location
        if let localStoreURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("WorkoutData").appendingPathExtension("sqlite") {
            if FileManager.default.fileExists(atPath: localStoreURL.path) && !FileManager.default.fileExists(atPath: groupStoreURL.path) {
                os_log("Migrating workout data to app group", log: .migration, type: .default)
                os_log("local=%@ group=%@", log: .migration, type: .debug, localStoreURL.path, groupStoreURL.path)
                
                let coordinator = WorkoutDataStorage(storeDescription: .init(url: localStoreURL)).persistentContainer.persistentStoreCoordinator
                guard let store = coordinator.persistentStore(for: localStoreURL) else {
                    fatalError("Local workout data store not found in coordinator")
                }
                do {
                    os_log("Migrating persistent store to app group", log: .migration, type: .debug)
                    try coordinator.migratePersistentStore(store, to: groupStoreURL, withType: store.type)
                } catch {
                    // migrate persistent store seems to always create a store
                    try? FileManager.default.removeItem(at: groupStoreURL)
                    try? FileManager.default.removeItem(atPath: groupStoreURL.path + "-wal")
                    try? FileManager.default.removeItem(atPath: groupStoreURL.path + "-shm")
                    
                    fatalError("Could not migrate persistent store to app group: \(error.localizedDescription)")
                }
                
                // only remove the file after successful migration
                do {
                    os_log("Removing old store files", log: .migration, type: .debug)
                    try FileManager.default.removeItem(at: localStoreURL)
                    try FileManager.default.removeItem(atPath: localStoreURL.path + "-wal")
                    try FileManager.default.removeItem(atPath: localStoreURL.path + "-shm")
                } catch {
                    os_log("Could not delete old store files: %@", log: .migration, type: .fault, error.localizedDescription)
                    // this is not a fatal error, continue...
                }
                
                os_log("Successfully migrated workout data to app group", log: .migration, type: .info)
            }
        }
    }
}
