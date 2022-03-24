//
//  IronDataTests.swift
//  IronDataTests
//
//  Created by Karim Abou Zeid on 22.03.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import XCTest
import GRDB
@testable import IronData

class IronDataTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func insertedWorkoutSet(_ db: Database) throws -> WorkoutSet {
        try WorkoutSet(
            workoutExerciseId: try WorkoutExercise(
                exerciseId: try Exercise(title: "Text Exercise", category: .machine).inserted(db).id!,
                workoutId: try Workout(start: Date()).inserted(db).id!
            ).inserted(db).id!
        ).inserted(db)
    }
    
    func testCascadeDelete() throws {
        let dbQueue = DatabaseQueue()
        _ = try AppDatabase(dbQueue)
        
        try dbQueue.write { db in
            _ = try insertedWorkoutSet(db)
            XCTAssertEqual(try WorkoutSet.fetchCount(db), 1)
            try Workout.deleteAll(db)
            XCTAssertEqual(try WorkoutSet.fetchCount(db), 0)
        }
    }
    
    func testFetch() throws {
        let dbQueue = DatabaseQueue()
        _ = try AppDatabase(dbQueue)
        
        try dbQueue.write { db in
            _ = try insertedWorkoutSet(db)
            
            struct WorkoutSetInfo: Decodable, FetchableRecord {
                var workoutSet: WorkoutSet
                var workoutExercise: WorkoutExerciseInfo
                
                struct WorkoutExerciseInfo: Decodable {
                    var workoutExercise: WorkoutExercise
                    var workout: Workout
                }
            }
            
            let workoutSetInfo = try WorkoutSet
                .including(required: WorkoutSet.workoutExercise.including(required: WorkoutExercise.workout))
                .asRequest(of: WorkoutSetInfo.self)
                .fetchOne(db)
            
            XCTAssertNotNil(workoutSetInfo)
        }
    }
    
    func testabc() throws {
        let dbQueue = DatabaseQueue()
        _ = try AppDatabase(dbQueue)
        
        try dbQueue.write { db in
            let workoutSet = try insertedWorkoutSet(db)
            let workoutExercise = try workoutSet.workoutExercise.fetchOne(db)
            XCTAssertNotNil(workoutExercise)
            let workout = try workoutExercise?.workout.fetchOne(db)
            XCTAssertNotNil(workout)
        }
    }
    
    func testEverkineticParsing() throws {
        let dbQueue = DatabaseQueue()
        _ = try AppDatabase(dbQueue)
        
        let data = try Data(contentsOf: Everkinetic.resourcesURL.appendingPathComponent("exercises.json"))
        let exercises = try Exercise.fromJSON(data: data)
        
        XCTAssertGreaterThan(exercises.count, 1)
        
        for exercise in exercises {
            print(exercise)
            for url in exercise.images?.urls ?? [] {
                XCTAssertNoThrow(try Data(contentsOf: url))
            }
        }
        
        try dbQueue.write { db in
            for var exercise in exercises {
                XCTAssertNoThrow(try exercise.insert(db))
            }
        }
        
        try dbQueue.read { db in
            XCTAssertEqual(try Exercise.filter(Exercise.Columns.title == "Bench Press: Barbell").fetchCount(db), 1)
        }
    }
}

struct Err: Error {}
