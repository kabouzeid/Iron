//
//  Persistence.swift
//  IronData
//
//  Created by Karim Abou Zeid on 22.03.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import GRDB

extension AppDatabase {
    public static func makeShared(folderURL: URL) -> AppDatabase {
        do {
            // Folder for storing the SQLite database, as well as
            // the various temporary files created during normal database
            // operations (https://sqlite.org/tempfiles.html).
            let fileManager = FileManager()

            // Support for tests: delete the database if requested
            if CommandLine.arguments.contains("-reset") {
                try? fileManager.removeItem(at: folderURL)
            }
            
            // Create the database folder if needed
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            
            // Connect to a database on disk
            // See https://github.com/groue/GRDB.swift/blob/master/README.md#database-connections
            let dbURL = folderURL.appendingPathComponent("db.sqlite")
            let dbPool = try DatabasePool(path: dbURL.path)
            
            // Create the AppDatabase
            let appDatabase = try AppDatabase(dbPool)
            
            // Prepare the database with test fixtures if requested
            if CommandLine.arguments.contains("-fixedTestData") {
//                try appDatabase.createWorkoutsForUITests()
                fatalError()
            } else {
                // Otherwise, populate the database if it is empty, for better
                // demo purpose.
                try appDatabase.createDefaultExercisesIfEmpty()
                
                // TODO: remove this
                try appDatabase.createRandomWorkouts()
            }
            
            return appDatabase
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate.
            //
            // Typical reasons for an error here include:
            // * The parent directory cannot be created, or disallows writing.
            // * The database is not accessible, due to permissions or data protection when the device is locked.
            // * The device is out of space.
            // * The database could not be migrated to its latest schema version.
            // Check the error message to determine what the actual problem was.
            fatalError("Unresolved error \(error)")
        }
    }
    
    /// Creates an empty database for SwiftUI previews
    public static func empty() -> AppDatabase {
        // Connect to an in-memory database
        // See https://github.com/groue/GRDB.swift/blob/master/README.md#database-connections
        let dbQueue = DatabaseQueue()
        return try! AppDatabase(dbQueue)
    }
    
    /// Creates a database full of random players for SwiftUI previews
    public static func random() -> AppDatabase {
        let appDatabase = empty()
        try! appDatabase.createDefaultExercisesIfEmpty()
        try! appDatabase.createRandomWorkouts()
        return appDatabase
    }
}
