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
    
    func populateDatabase(database: AppDatabase, dbWriter: DatabaseWriter, workouts: Int, workoutExercises: Int, workoutSets: Int) throws {
        try database.createDefaultExercisesIfEmpty()
        
        try dbWriter.write { db in
            let exercises = try Exercise.order(Exercise.Columns.title.localizedLowercased).fetchAll(db)
            
            for i in 0..<workouts {
                let start = Date(timeIntervalSince1970: 60*60*24 * Double(i))
                let workout = try Workout(start: start, end: start.addingTimeInterval(60*60*1.5), title: "Workout \(i)", comment: nil, isActive: false).inserted(db)
                for j in 0..<workoutExercises {
                    let workoutExercise = try WorkoutExercise(order: j, exerciseId: exercises[((i + j) % 20) % exercises.count].id!, workoutId: workout.id!).inserted(db)
                    for k in 0..<workoutSets {
                        let weight: Double = (sin(Double(i)) * 10 + (1 / 6) * Double(i) - Double(j) + 120).rounded() / 2
                        let repetitions: Int = max(min(workoutExercises - j, 8), 3)
                        _ = try WorkoutSet(order: k, weight: weight, repetitions: repetitions, isCompleted: true, workoutExerciseId: workoutExercise.id!).inserted(db)
                    }
                }
            }
        }
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
    
    func testAssociations() throws {
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
    
    func testPR() throws {
        let dbQueue = DatabaseQueue()
        let database = try AppDatabase(dbQueue)
        
        try populateDatabase(database: database, dbWriter: dbQueue, workouts: 200, workoutExercises: 4, workoutSets: 5)
        
        try dbQueue.write { db in
            struct WorkoutSetInfo: FetchableRecord, Decodable {
                let workoutSet: WorkoutSet
                let workoutExerciseInfo: WorkoutExerciseInfo
                struct WorkoutExerciseInfo: Decodable {
                    let workoutExercise: WorkoutExercise
                    let workout: Workout
                }
            }
            let workoutSetInfos = try WorkoutSet
                .including(required: WorkoutSet.workoutExercise
                    .including(required: WorkoutExercise.workout)
                    .forKey("workoutExerciseInfo")
                )
                .asRequest(of: WorkoutSetInfo.self)
                .fetchAll(db)
            
            for workoutSetInfo in workoutSetInfos {
                let workoutSet = workoutSetInfo.workoutSet
                let workoutExercise = workoutSetInfo.workoutExerciseInfo.workoutExercise
                let workout = workoutSetInfo.workoutExerciseInfo.workout
                
                guard try workoutSet.isPersonalRecord(db, info: (workoutExercise: workoutExercise, workout: workout)) else { continue }
                
                let workoutAlias = TableAlias()
                let workoutExerciseAlias = TableAlias()
                let count = try WorkoutSet.all()
                    .joining(required: WorkoutSet.workoutExercise.aliased(workoutExerciseAlias)
                        .joining(required: WorkoutExercise.workout.aliased(workoutAlias))
                    )
                    .filter(WorkoutSet.Columns.repetitions > workoutSet.repetitions!)
                    .filter(WorkoutSet.Columns.weight > workoutSet.weight!)
                    .filter(workoutExerciseAlias[WorkoutExercise.Columns.exerciseId] == workoutExercise.exerciseId)
                    .filter(workoutAlias[Workout.Columns.start] < workout.start)
                    .fetchCount(db)
                XCTAssertEqual(count, 0)
            }
        }
    }
    
    func testCheckPRPerformance() throws {
        let dbQueue = DatabaseQueue()
        let database = try AppDatabase(dbQueue)
        
        try populateDatabase(database: database, dbWriter: dbQueue, workouts: 1000, workoutExercises: 4, workoutSets: 5)
        
        try dbQueue.read { db in
            let workoutSet = try WorkoutSet.fetchOne(db)!
            let workoutExercise = try workoutSet.workoutExercise.fetchOne(db)!
            let workout = try workoutExercise.workout.fetchOne(db)!
            
            measure {
                _ = try! workoutSet.isPersonalRecord(db, info: (workoutExercise: workoutExercise, workout: workout))
            }
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
            for name in exercise.images?.names ?? [] {
                XCTAssertNoThrow(try Data(contentsOf: Exercise.imagesBundle.bundleURL.appendingPathComponent(name)))
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
    
    func testFetchTime() throws {
        struct WorkoutInfo: Decodable, FetchableRecord, Equatable {
            var workout: Workout
            var workoutExerciseInfos: [WorkoutExerciseInfo]
            
            struct WorkoutExerciseInfo: Decodable, FetchableRecord, Equatable {
                var workoutExercise: WorkoutExercise
                var exercise: Exercise
                var workoutSets: [WorkoutSet]
            }
            
            static func filterFinished() -> QueryInterfaceRequest<WorkoutInfo> {
                Workout
                    .filter(Workout.Columns.isActive == false)
                    .including(all: Workout.workoutExercises
                        .forKey(CodingKeys.workoutExerciseInfos)
                        .including(all: WorkoutExercise.workoutSets)
                        .including(required: WorkoutExercise.exercise)
                    )
                .orderByStart()
                .asRequest(of: WorkoutInfo.self)
            }
        }
        
        let dbQueue = DatabaseQueue()
        let database = try AppDatabase(dbQueue)
        
        try database.createDefaultExercisesIfEmpty()
        try database.createRandomWorkouts()
        
        try database.databaseReader.read { db in
            measure {
                let workoutInfos = try! WorkoutInfo.filterFinished().fetchAll(db)
                XCTAssertEqual(workoutInfos.count, 700)
            }
        }
    }
    
    func testExercisesFetchTime() throws {
        let dbQueue = DatabaseQueue()
        let database = try AppDatabase(dbQueue)
        
        try database.createDefaultExercisesIfEmpty()
        
        try database.databaseReader.read { db in
            measure {
                let exercises = try! Exercise.all().orderByTitle().fetchAll(db)
                XCTAssertEqual(exercises.count, 159)
            }
        }
    }
    
    func testHistoryFetchTime() throws {
        let dbQueue = DatabaseQueue()
        let database = try AppDatabase(dbQueue)
        
        try database.createDefaultExercisesIfEmpty()
        try database.createRandomWorkouts()
        
        struct WorkoutInfo: Decodable, FetchableRecord, Equatable {
            var workout: Workout
            var workoutExerciseInfos: [WorkoutExerciseInfo]
            
            struct WorkoutExerciseInfo: Decodable, FetchableRecord, Equatable {
                var workoutExercise: WorkoutExercise
                var workoutSets: [WorkoutSet]
            }
            
            static func filter(exerciseID: Exercise.ID.Wrapped) -> QueryInterfaceRequest<WorkoutInfo> {
                Workout
                    .including(all: Workout.workoutExercises
                        .forKey(CodingKeys.workoutExerciseInfos)
                        .filter(WorkoutExercise.Columns.exerciseId == exerciseID)
                        .including(all: WorkoutExercise.workoutSets
                            .filter(WorkoutSet.Columns.isCompleted == true)
                        )
                    )
                    .orderByStart()
                    .asRequest(of: WorkoutInfo.self)
            }
        }
        
        try database.databaseReader.read { db in
            measure {
                let history = try! WorkoutInfo
                    .filter(exerciseID: 1)
                    .fetchAll(db)
                    .filter { !$0.workoutExerciseInfos.isEmpty }
                print(history.count)
            }
        }
    }
    
    func testActiveWorkoutFetchTime() throws {
        let dbQueue = DatabaseQueue()
        let database = try AppDatabase(dbQueue)
        
        try database.createDefaultExercisesIfEmpty()
        try database.createRandomWorkouts()
        
        struct WorkoutInfo: Decodable, FetchableRecord, Equatable {
            var workout: Workout
            var workoutExerciseInfos: [WorkoutExerciseInfo]
            
            struct WorkoutExerciseInfo: Decodable, FetchableRecord, Equatable, Identifiable {
                var workoutExercise: WorkoutExercise
                var exercise: Exercise
                var workoutSets: [WorkoutSet]
                
                var id: WorkoutExercise.ID { workoutExercise.id }
            }
            
            static func allActive() -> QueryInterfaceRequest<WorkoutInfo> {
                Workout
                    .filter(Workout.Columns.isActive == true)
                    .order(Workout.Columns.id) // in case there is a bug and there are multiple active workouts
                    .including(all: Workout.workoutExercises
                        .forKey(CodingKeys.workoutExerciseInfos)
                        .including(all: WorkoutExercise.workoutSets)
                        .including(required: WorkoutExercise.exercise)
                    )
                    .orderByStart()
                    .asRequest(of: WorkoutInfo.self)
            }
        }
        
        try database.databaseReader.read { db in
            measure {
                _ = try! WorkoutInfo
                    .allActive()
                    .fetchOne(db)!
            }
        }
    }
}

struct Err: Error {}
