//
//  ExportImportWorkoutDataTests.swift
//  IronTests
//
//  Created by Karim Abou Zeid on 26.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import XCTest
import CoreData
@testable import Iron

class ExportImportWorkoutDataTests: XCTestCase {

    var persistenContainer: NSPersistentContainer!
    
    var encoder: JSONEncoder {
        guard let contextKey = CodingUserInfoKey.managedObjectContextKey else { fatalError() }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        encoder.userInfo[contextKey] = persistenContainer.viewContext
        return encoder
    }
    
    var decoder: JSONDecoder {
        guard let contextKey = CodingUserInfoKey.managedObjectContextKey else { fatalError() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.userInfo[contextKey] = persistenContainer.viewContext
        return decoder
    }

    override func setUp() {
        super.setUp()
        persistenContainer = setUpInMemoryNSPersistentContainer()
    }

    override func tearDown() {
        persistenContainer.viewContext.reset()
        persistenContainer = nil
        super.tearDown()
    }

    func testReadWorkoutData() {
        let workoutDataUrl = Bundle.init(for: Self.self).bundleURL.appendingPathComponent("workout_data.json")
        precondition(FileManager.default.fileExists(atPath: workoutDataUrl.path))
        
        // check that start and end is not nil
        let workouts = try! decoder.decode([Workout].self, from: Data(contentsOf: workoutDataUrl))
        XCTAssertFalse(workouts.isEmpty)
        for workout in workouts {
            XCTAssertNotNil(workout.start)
            XCTAssertNotNil(workout.end)
            XCTAssertFalse(workout.isCurrentWorkout)
        }
        
        // check that workout is set
        let exercises = workouts.compactMap { $0.workoutExercises?.array.compactMap { $0 as? WorkoutExercise } }.flatMap { $0 }
        XCTAssertFalse(exercises.isEmpty)
        for exercise in exercises {
            XCTAssertNotNil(exercise.workout)
        }
        
        // check that workoutExercise is set
        let sets = exercises.compactMap { $0.workoutSets?.array.compactMap { $0 as? WorkoutSet } }.flatMap { $0 }
        XCTAssertFalse(sets.isEmpty)
        for set in sets {
            XCTAssertNotNil(set.workoutExercise)
            XCTAssert(set.isCompleted)
        }
        
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
    }
    
    func testReadWorkoutDataStartEndMissing() {
        let workoutDataUrl = Bundle.init(for: Self.self).bundleURL.appendingPathComponent("workout_data_start_end_missing.json")
        precondition(FileManager.default.fileExists(atPath: workoutDataUrl.path))
        
        // cannot read if a workout doesn't have a start / end value
        XCTAssertThrowsError(try decoder.decode([Workout].self, from: Data(contentsOf: workoutDataUrl)))
    }
    
    func testExportWorkoutWithoutStartEnd() {
        let workout = Workout(context: persistenContainer.viewContext)
        // no start / end is set
        // encoding shouldn't crash but set safeStart and safeEnd
        let data = try! encoder.encode([workout])
        
        XCTAssertThrowsError(try persistenContainer.viewContext.save())
        persistenContainer.viewContext.delete(workout)
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
        
        let workouts = try! decoder.decode([Workout].self, from: data)
        for workout in workouts {
            // decoded workouts must always have start end assigned
            XCTAssertNotNil(workout.start)
            XCTAssertNotNil(workout.end)
        }
        
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
    }
}
