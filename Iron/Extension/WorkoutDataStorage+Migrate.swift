//
//  WorkoutDataStorage+Migrate.swift
//  Iron
//
//  Created by Karim Abou Zeid on 06.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit

extension WorkoutDataStorage {
    static func migrateToAppGroupIfNecessary() {
        // check if we need to migrate the stores location
        if let localStoreURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("WorkoutData").appendingPathExtension("sqlite") {
            if FileManager.default.fileExists(atPath: localStoreURL.path) && !FileManager.default.fileExists(atPath: groupStoreURL.path) {
                print("attempt to migrate \(localStoreURL) ---> \(groupStoreURL)")
                
                let coordinator = WorkoutDataStorage(storeDescription: .init(url: localStoreURL)).persistentContainer.persistentStoreCoordinator
                guard let store = coordinator.persistentStore(for: localStoreURL) else {
                    fatalError("local store not found in coordinator")
                }
                do {
                    print("migrating (moving) store file...")
                    try coordinator.migratePersistentStore(store, to: groupStoreURL, withType: store.type)
                } catch {
                    // migrate persistent store seems to always create a store
                    try? FileManager.default.removeItem(at: groupStoreURL)
                    try? FileManager.default.removeItem(atPath: groupStoreURL.path + "-wal")
                    try? FileManager.default.removeItem(atPath: groupStoreURL.path + "-shm")
                    
                    fatalError("could not migrate (move) store file: \(error)")
                }
                
                // only remove the file after successful migration
                do {
                    print("removing old store files...")
                    try FileManager.default.removeItem(at: localStoreURL)
                    try FileManager.default.removeItem(atPath: localStoreURL.path + "-wal")
                    try FileManager.default.removeItem(atPath: localStoreURL.path + "-shm")
                } catch {
                    print("could not delete old store files: \(error)")
                    // this is not a fatal error, continue...
                }
            }
        }
    }
}
