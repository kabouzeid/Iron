//
//  WorkoutDataMigrationTests.swift
//  IronTests
//
//  Created by Karim Abou Zeid on 26.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import XCTest
import CoreData
@testable import WorkoutDataKit

class WorkoutDataMigrationTests: XCTestCase {
    var testFolder: URL!
    var storeURL: URL!
    var persistentContainer: NSPersistentContainer!
    let exerciseStore = ExerciseStore(customExercisesURL: nil)
    
    override func setUpWithError() throws {
        testFolder = FileManager.default.temporaryDirectory.appendingPathComponent("test", isDirectory: true)
        storeURL = testFolder.appendingPathComponent("WorkoutData").appendingPathExtension("sqlite")
        try createCleanTestFolder()
        
        persistentContainer = NSPersistentContainer(name: "WorkoutData", managedObjectModel: WorkoutDataStorage.model)
    }
    
    override func tearDownWithError() throws {
        try wipeTestFolder()
    }
    
    func testMigrateFromV1() throws {
        prepareMigrationTest(workoutData: "modelv1_ironv1.0.0", allowInferMappingModel: false)
        
        let expectation = XCTestExpectation(description: "Load persistent stores")
        persistentContainer.loadPersistentStores { (description, error) in
            XCTAssertNil(error)
            
            let workoutRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
            let workouts = try! self.persistentContainer.viewContext.fetch(workoutRequest)
            XCTAssertEqual(workouts.count, 194) // sanity check
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testMigrateFromV2() throws {
        prepareMigrationTest(workoutData: "modelv2_ironv1.0.7", allowInferMappingModel: false)
        
        let expectation = XCTestExpectation(description: "Load persistent stores")
        persistentContainer.loadPersistentStores { (description, error) in
            XCTAssertNil(error)
            
            let workoutRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
            let workouts = try! self.persistentContainer.viewContext.fetch(workoutRequest)
            XCTAssertEqual(workouts.count, 246) // sanity check
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testMigrateFromV3() throws {
        prepareMigrationTest(workoutData: "modelv3_ironv1.1.0", allowInferMappingModel: false)
        
        let expectation = XCTestExpectation(description: "Load persistent stores")
        persistentContainer.loadPersistentStores { (description, error) in
            XCTAssertNil(error)
            
            let workoutRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
            let workouts = try! self.persistentContainer.viewContext.fetch(workoutRequest)
            XCTAssertEqual(workouts.count, 246) // sanity check
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
}

extension WorkoutDataMigrationTests {
    func prepareMigrationTest(workoutData: String, allowInferMappingModel: Bool) {
        // sanity check that we have a fresh copy of the database
        precondition(!FileManager.default.fileExists(atPath: storeURL.path))
        try! copyWorkoutData(name: workoutData)
        precondition(FileManager.default.fileExists(atPath: storeURL.path))
        
        // sanity check that the store files need migration
        let metadata = try! NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
        precondition(WorkoutDataStorage.model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == false)
        
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = allowInferMappingModel
        persistentContainer.persistentStoreDescriptions = [description]
    }
}

extension WorkoutDataMigrationTests {
    func copyWorkoutData(name: String) throws {
        let url = Bundle.init(for: Self.self).bundleURL.appendingPathComponent("workout_data").appendingPathComponent(name)
        precondition(FileManager.default.fileExists(atPath: url.path), "File \(url.path) does not exist")
        let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        try contents.forEach { try FileManager.default.copyItem(at: $0, to: testFolder.appendingPathComponent($0.lastPathComponent)) }
    }
}

extension WorkoutDataMigrationTests {
    func wipeTestFolder() throws {
        if FileManager.default.fileExists(atPath: testFolder.path) {
            try FileManager.default.removeItem(at: testFolder)
        }
    }
    
    func createCleanTestFolder() throws {
        try wipeTestFolder()
        try FileManager.default.createDirectory(at: testFolder, withIntermediateDirectories: true)
    }
}
