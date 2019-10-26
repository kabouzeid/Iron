//
//  WorkoutDataTests.swift
//  IronTests
//
//  Created by Karim Abou Zeid on 15.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import XCTest
import CoreData
@testable import Iron

class WorkoutDataTests: XCTestCase {
    var persistenContainer: NSPersistentContainer!
    
    var testWorkouts: [Workout]!
    var testWorkoutExercises: [WorkoutExercise]!
    var testWorkoutSets: [WorkoutSet]!
    
    var testCurrentWorkout: Workout!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        persistenContainer = setUpInMemoryNSPersistentContainer()

        createTestWorkoutData(context: persistenContainer.viewContext)
        testCurrentWorkout = createTestCurrentWorkout(context: persistenContainer.viewContext)
        
        testWorkouts = try? persistenContainer.viewContext.fetch(Workout.fetchRequest()) as? [Workout]
        testWorkoutExercises = try? persistenContainer.viewContext.fetch(WorkoutExercise.fetchRequest()) as? [WorkoutExercise]
        testWorkoutSets = try? persistenContainer.viewContext.fetch(WorkoutSet.fetchRequest()) as? [WorkoutSet]

        XCTAssertNotNil(testWorkouts)
        XCTAssertTrue(testWorkouts.count > 0)
        XCTAssertTrue(testWorkouts.count == 2) // might change in future
        XCTAssertNotNil(testWorkoutExercises)
        XCTAssertTrue(testWorkoutExercises.count > 0)
        XCTAssertNotNil(testWorkoutSets)
        XCTAssertTrue(testWorkoutSets.count > 0)
        
        XCTAssertNotNil(testCurrentWorkout)
        
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        persistenContainer.viewContext.reset()
        persistenContainer = nil
        
        testWorkouts = nil
        testWorkoutExercises = nil
        testWorkoutSets = nil
        testCurrentWorkout = nil
        
        super.tearDown()
    }
    
    func testWorkoutExerciseNumberOfCompletedSets() {
        for workoutExercise in testWorkoutExercises {
            let count = workoutExercise.workoutSets?.filter({ (set) -> Bool in
                (set as! WorkoutSet).isCompleted == true
            }).count
            XCTAssertTrue(workoutExercise.numberOfCompletedSets == count)
        }
    }
    
    func testRelationshipDeleteRules() {
        for workout in testWorkouts {
            let workoutExercises = workout.workoutExercises!.array.map { $0 as! WorkoutExercise }
            
            let workoutExercise = workoutExercises.first!
            let workoutSets = workoutExercise.workoutSets!.array.map { $0 as! WorkoutSet }
            
            // set deletion doesn't delete exercise
            let workoutSet = workoutSets.first!
            persistenContainer.viewContext.delete(workoutSet)
            XCTAssertNoThrow(try persistenContainer.viewContext.save())
            XCTAssertNil(workoutSet.managedObjectContext)
            XCTAssertNotNil(workoutExercise.managedObjectContext)
            
            // exercise deletion doesn't delete workout, but deletes sets
            persistenContainer.viewContext.delete(workoutExercise)
            XCTAssertNoThrow(try persistenContainer.viewContext.save())
            XCTAssertNil(workoutExercise.managedObjectContext)
            XCTAssertTrue(workoutSets.reduce(true, { $0 && $1.managedObjectContext == nil }))
            XCTAssertNotNil(workout.managedObjectContext)

            // workout deletion deletes exercises
            persistenContainer.viewContext.delete(workout)
            XCTAssertNoThrow(try persistenContainer.viewContext.save())
            XCTAssertNil(workout.managedObjectContext)
            XCTAssertTrue(workoutExercises.reduce(true, { $0 && $1.managedObjectContext == nil }))
        }
    }
    
    func uncompletedSetsSwift(workout: Workout) -> [WorkoutSet]? {
        return workout.workoutExercises?
            .compactMap { $0 as? WorkoutExercise }
            .compactMap { $0.workoutSets?.array as? [WorkoutSet] }
            .flatMap { $0 }
            .filter { !$0.isCompleted }
    }
    
    func uncompletedSetsFetch(workout: Workout) -> [WorkoutSet]? {
        let fetchRequest: NSFetchRequest<WorkoutSet> = WorkoutSet.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(#keyPath(WorkoutSet.workoutExercise.workout)) == %@ AND \(#keyPath(WorkoutSet.isCompleted)) == %@", workout, NSNumber(booleanLiteral: false))
        return try? workout.managedObjectContext?.fetch(fetchRequest)
    }
    
    func testUncompletedSets() {
        for workout in testWorkouts {
            XCTAssertEqual(Set(uncompletedSetsSwift(workout: workout) ?? []), Set(uncompletedSetsFetch(workout: workout) ?? []))
        }
    }
    
    func testUncompletedSetsSwift() {
        self.measure {
            for workout in testWorkouts {
                _ = uncompletedSetsSwift(workout: workout)
            }
        }
    }
    
    func testUncompletedSetsFetch() {
        self.measure {
            for workout in testWorkouts {
                _ = uncompletedSetsFetch(workout: workout)
            }
        }
    }
    
    func testDeleteUncompletedSets() {
        testCurrentWorkout.deleteUncompletedSets()
        XCTAssertTrue(
            testCurrentWorkout.workoutExercises?
                .compactMap { $0 as? WorkoutExercise }
                .compactMap { $0.workoutSets?.array as? [WorkoutSet] }
                .flatMap { $0 }
                .filter { !$0.isCompleted }
                .isEmpty ?? true
        )
    }
    
    func testStartEndValidation() {
        for workout in testWorkouts {
            if let start = workout.start, let end = workout.end {
                workout.start = end
                workout.end = start
                XCTAssertThrowsError(try persistenContainer.viewContext.save())
                
                workout.start = nil
                workout.end = end
                XCTAssertThrowsError(try persistenContainer.viewContext.save())
                
                workout.start = start
                workout.end = nil
                if workout.isCurrentWorkout {
                    XCTAssertNoThrow(try persistenContainer.viewContext.save())
                } else {
                    XCTAssertThrowsError(try persistenContainer.viewContext.save())
                }
            }
        }
    }
    
    func testCurrentWorkoutValidation() {
        XCTAssertEqual(try persistenContainer.viewContext.count(for: Workout.currentWorkoutFetchRequest), 1)
        let workout = createTestCurrentWorkout(context: persistenContainer.viewContext)
        XCTAssertEqual(try persistenContainer.viewContext.count(for: Workout.currentWorkoutFetchRequest), 2)
        XCTAssertThrowsError(try persistenContainer.viewContext.save())
        persistenContainer.viewContext.delete(workout)
        XCTAssertEqual(try persistenContainer.viewContext.count(for: Workout.currentWorkoutFetchRequest), 1)
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
        persistenContainer.viewContext.delete(testCurrentWorkout)
        XCTAssertEqual(try persistenContainer.viewContext.count(for: Workout.currentWorkoutFetchRequest), 0)
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
        _ = createTestCurrentWorkout(context: persistenContainer.viewContext)
        XCTAssertEqual(try persistenContainer.viewContext.count(for: Workout.currentWorkoutFetchRequest), 1)
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
    }
    
    func testWorkoutIsCompletedValidation() {
        testCurrentWorkout.isCurrentWorkout = false
        XCTAssertThrowsError(try persistenContainer.viewContext.save())
        testCurrentWorkout.isCurrentWorkout = true
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
        
        for workoutSet in testWorkoutSets {
            if let workout = workoutSet.workoutExercise?.workout, !workout.isCurrentWorkout {
                workoutSet.isCompleted = false
                XCTAssertThrowsError(try persistenContainer.viewContext.save())
                workoutSet.isCompleted = true
                XCTAssertNoThrow(try persistenContainer.viewContext.save())
            }
        }
    }
    
    func testDetachedWorkoutExercise() {
        let workoutExercise = WorkoutExercise(context: persistenContainer.viewContext)
        XCTAssertThrowsError(try persistenContainer.viewContext.save())
        workoutExercise.workout = testWorkouts.first
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
    }
    
    func testDetachedWorkoutSet() {
        let workoutSet = WorkoutSet(context: persistenContainer.viewContext)
        workoutSet.isCompleted = true
        XCTAssertThrowsError(try persistenContainer.viewContext.save())
        workoutSet.workoutExercise = testWorkoutExercises.first
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
    }
    
    func testUncompletedSet() {
        let workoutSet = WorkoutSet(context: persistenContainer.viewContext)
        workoutSet.isCompleted = false
        workoutSet.workoutExercise = testCurrentWorkout.workoutExercises?.firstObject as? WorkoutExercise
        XCTAssertNotNil(workoutSet.workoutExercise)
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
        workoutSet.workoutExercise = testWorkoutExercises.first
        XCTAssertThrowsError(try persistenContainer.viewContext.save())
        workoutSet.isCompleted = true
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
    }
    
    func testWorkoutIsCompleted() {
        for workout in testWorkouts {
            if !workout.isCurrentWorkout {
                XCTAssertTrue(workout.isCompleted!)
            }
        }
    }
    
    func testWorkoutHasCompletedSets() {
        let workout = Workout(context: persistenContainer.viewContext)
        XCTAssertFalse(workout.hasCompletedSets!)
        
        let exercise = WorkoutExercise(context: persistenContainer.viewContext)
        workout.addToWorkoutExercises(exercise)
        XCTAssertFalse(workout.hasCompletedSets!)
        
        let set = WorkoutSet(context: persistenContainer.viewContext)
        exercise.addToWorkoutSets(set)
        XCTAssertFalse(workout.hasCompletedSets!)
        
        set.isCompleted = true
        XCTAssertTrue(workout.hasCompletedSets!)
        
        for workout in testWorkouts {
            XCTAssertTrue(workout.hasCompletedSets!)
        }
    }
}
