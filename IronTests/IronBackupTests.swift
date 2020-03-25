//
//  IronBackupTests.swift
//  IronTests
//
//  Created by Karim Abou Zeid on 25.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import XCTest
import CoreData
import WorkoutDataKit
@testable import Iron

class IronBackupTests: XCTestCase {
    var persistenContainer: NSPersistentContainer!
    var userDefaults: UserDefaults!
    var exerciseStore: ExerciseStore!

    override func setUpWithError() throws {
        // reset test folder
        let testFolder = FileManager.default.temporaryDirectory.appendingPathComponent("test", isDirectory: true)
        if FileManager.default.fileExists(atPath: testFolder.path) {
            try! FileManager.default.removeItem(at: testFolder)
        }
        try! FileManager.default.createDirectory(at: testFolder, withIntermediateDirectories: true)
        
        // reset user defaults
        UserDefaults().removePersistentDomain(forName: "test")
        userDefaults = UserDefaults(suiteName: "test")
        
        // in memory persistent container
        persistenContainer = setUpInMemoryNSPersistentContainer()
        
        // exercise store in test folder
        exerciseStore = ExerciseStore(customExercisesURL: testFolder.appendingPathComponent("custom_exercises.json"))
    }

    override func tearDownWithError() throws {
        persistenContainer.viewContext.reset()
        persistenContainer = nil
    }
    
    func testImportIronBackupV1() {
        let context = persistenContainer.viewContext
        
        let data = backupData(name: "v1")
        XCTAssertNoThrow(try IronBackup.restoreBackupData(data: data, managedObjectContext: context, exerciseStore: exerciseStore))
        
        let workoutRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        let workouts = try! context.fetch(workoutRequest)
        XCTAssertEqual(workouts.count, 209) // sanity check
        
        XCTAssertEqual(exerciseStore.customExercises.count, 4) // sanity check
    }

    func testImportIronBackupV2() {
        let context = persistenContainer.viewContext
        
        let data = backupData(name: "v2")
        XCTAssertNoThrow(try IronBackup.restoreBackupData(data: data, managedObjectContext: context, exerciseStore: exerciseStore))
        
        let workoutRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        let workouts = try! context.fetch(workoutRequest)
        XCTAssertEqual(workouts.count, 246) // sanity check
        
        XCTAssertEqual(exerciseStore.customExercises.count, 5) // sanity check
    }
    
    func testImportIronBackupV3() {
        let context = persistenContainer.viewContext

        let data = backupData(name: "v3")
        XCTAssertNoThrow(try IronBackup.restoreBackupData(data: data, managedObjectContext: context, exerciseStore: exerciseStore))

        let workoutRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        let workouts = try! context.fetch(workoutRequest)
        XCTAssertEqual(workouts.count, 246) // sanity check
        
        let workoutPlanRequest: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
        let workoutPlans = try! context.fetch(workoutPlanRequest)
        XCTAssertEqual(workoutPlans.count, 1) // sanity check
        
        XCTAssertEqual(exerciseStore.customExercises.count, 5) // sanity check
    }
    
    func testExportIronBackup() {
        let context = persistenContainer.viewContext
        createTestWorkoutData(context: context)
        try! context.save()
        
        XCTAssertNoThrow(try IronBackup.createBackupData(managedObjectContext: context, exerciseStore: exerciseStore))
    }
}

extension IronBackupTests {
    private func backupData(name: String) -> Data {
        let url = Bundle.init(for: Self.self).bundleURL.appendingPathComponent("iron_backups").appendingPathComponent(name).appendingPathExtension("ironbackup")
        precondition(FileManager.default.fileExists(atPath: url.path), "File \(url.path) does not exist")
        return try! Data(contentsOf: url)
    }
}
