//
//  AppDatabase.swift
//  IronData
//
//  Created by Karim Abou Zeid on 22.03.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import GRDB

/// AppDatabase lets the application access the database.
///
/// It applies the pratices recommended at
/// <https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md>
struct AppDatabase {
    /// Creates an `AppDatabase`, and make sure the database schema is ready.
    init(_ dbWriter: DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    /// Provides access to the database.
    ///
    /// Application can use a `DatabasePool`, while SwiftUI previews and tests
    /// can use a fast in-memory `DatabaseQueue`.
    ///
    /// See <https://github.com/groue/GRDB.swift/blob/master/README.md#database-connections>
    private let dbWriter: DatabaseWriter
    
    /// The DatabaseMigrator that defines the database schema.
    ///
    /// See <https://github.com/groue/GRDB.swift/blob/master/Documentation/Migrations.md>
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        // Speed up development by nuking the database when migrations change
        // See https://github.com/groue/GRDB.swift/blob/master/Documentation/Migrations.md#the-erasedatabaseonschemachange-option
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        // See https://github.com/groue/GRDB.swift#create-tables
        
        migrator.registerMigration("createWorkoutData") { db in
            try db.create(table: "exercise") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("uuid", .blob).notNull().unique()
                t.column("title", .text).indexed().notNull()
                t.column("aliases", .text).indexed() // \n separated for filtering in query
                t.column("images", .text) // {urls: [URL]}
                t.column("movementType", .text) // enum -- isolation, compound
                t.column("bodyPart", .text) // enum -- chest, arms, ...
                t.column("category", .text).notNull() // enum -- barbell, dumbbell, machine, cardio, ...
            }

            try db.create(table: "workout") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("uuid", .blob).notNull().unique()
                t.column("start", .datetime).notNull()
                t.column("end", .datetime)
                t.column("title", .text)
                t.column("comment", .text)
                t.column("isActive", .boolean)
                    .notNull()
                    .defaults(to: false)
            }
            
            try db.create(table: "workoutexercise") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("uuid", .blob).notNull().unique()
                t.column("order", .integer).notNull()
                t.column("comment", .text)
                t.column("exerciseId", .integer)
                    .notNull()
                    .indexed()
                    .references("exercise", onDelete: .cascade)
                t.column("workoutId", .integer)
                    .notNull()
                    .indexed()
                    .references("workout", onDelete: .cascade)
            }
            
            try db.create(table: "workoutset") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("uuid", .blob).notNull().unique()
                t.column("order", .integer).notNull()
                t.column("weight", .double)
                t.column("repetitions", .integer)
                t.column("targetRepetitionsLower", .integer)
                t.column("targetRepetitionsUpper", .integer)
                t.column("rpe", .numeric)
                t.column("comment", .text)
                t.column("tag", .text)
                t.column("isCompleted", .boolean)
                    .notNull()
                    .defaults(to: false)
                t.column("workoutExerciseId", .integer)
                    .notNull()
                    .indexed()
                    .references("workoutExercise", onDelete: .cascade)
            }
        }
        
        // Migrations for future application versions will be inserted here:
        // migrator.registerMigration(...) { db in
        //     ...
        // }
        
        return migrator
    }
}

// MARK: - Database Access: Writes

extension AppDatabase {
    func saveWorkout(_ workout: inout Workout) async throws {
        workout = try await dbWriter.write { [workout] db in
            try workout.saved(db)
        }
    }
    
    /// Delete the specified workouts
    func deleteWorkouts(ids: [Int64]) async throws {
        try await dbWriter.write { db in
            _ = try Workout.deleteAll(db, ids: ids)
        }
    }
    
    /// Create random workouts if the database is empty.
    func createRandomWorkoutsIfEmpty() throws {
        try dbWriter.write { db in
            if try Workout.all().isEmpty(db) {
                try createRandomWorkouts(db)
            }
        }
    }

    /// Support for `createRandomworkoutsIfEmpty()` and `refreshworkouts()`.
    private func createRandomWorkouts(_ db: Database) throws {
        for _ in 0..<8 {
            _ = try Workout.makeRandom().inserted(db) // insert but ignore inserted id
        }
    }
    
    func createDefaultExercisesIfEmpty() throws {
        try dbWriter.write { db in
            if try Workout.all().isEmpty(db) {
                try createDefaultExercises(db)
            }
        }
    }
    
    private func createDefaultExercises(_ db: Database) throws {
        let data = try Data(contentsOf: Everkinetic.resourcesURL.appendingPathComponent("exercises.json"))
        try dbWriter.write { db in
            for var exercise in try Exercise.fromJSON(data: data) {
                try exercise.insert(db)
            }
        }
    }
}

// MARK: - Database Access: Reads

// This demo app does not provide any specific reading method, and instead
// gives an unrestricted read-only access to the rest of the application.
// In your app, you are free to choose another path, and define focused
// reading methods.
extension AppDatabase {
    /// Provides a read-only access to the database
    var databaseReader: DatabaseReader {
        dbWriter
    }
}
