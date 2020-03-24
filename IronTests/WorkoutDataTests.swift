//
//  WorkoutDataTests.swift
//  IronTests
//
//  Created by Karim Abou Zeid on 15.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import XCTest
import CoreData
import Combine
import WorkoutDataKit
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
    
    func testDeleteExercisesWhereAllSetsAreUncompleted() {
        testCurrentWorkout.deleteExercisesWhereAllSetsAreUncompleted()
        XCTAssertTrue(
            testCurrentWorkout.workoutExercises?
                .compactMap { $0 as? WorkoutExercise }
                .compactMap { $0.workoutSets?.array as? [WorkoutSet] }
                .filter { $0.reduce(true, { $0 && !$1.isCompleted }) }
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
    
    func testUuidRequired() {
        for workout in testWorkouts {
            workout.uuid = nil
            XCTAssertThrowsError(try persistenContainer.viewContext.save())
            workout.uuid = UUID()
            XCTAssertNoThrow(try persistenContainer.viewContext.save())
        }
        
        for workoutExercise in testWorkoutExercises {
            workoutExercise.uuid = nil
            XCTAssertThrowsError(try persistenContainer.viewContext.save())
            workoutExercise.uuid = UUID()
            XCTAssertNoThrow(try persistenContainer.viewContext.save())
        }
        
        for workoutSet in testWorkoutSets{
            workoutSet.uuid = nil
            XCTAssertThrowsError(try persistenContainer.viewContext.save())
            workoutSet.uuid = UUID()
            XCTAssertNoThrow(try persistenContainer.viewContext.save())
        }
        
        // TODO: also for workout plans
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
        let workoutExercise = WorkoutExercise.create(context: persistenContainer.viewContext)
        XCTAssertThrowsError(try persistenContainer.viewContext.save())
        workoutExercise.workout = testWorkouts.first
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
    }
    
    func testDetachedWorkoutSet() {
        let workoutSet = WorkoutSet.create(context: persistenContainer.viewContext)
        workoutSet.isCompleted = true
        XCTAssertThrowsError(try persistenContainer.viewContext.save())
        workoutSet.workoutExercise = testWorkoutExercises.first
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
    }
    
    func testUncompletedSet() {
        let workoutSet = WorkoutSet.create(context: persistenContainer.viewContext)
        workoutSet.isCompleted = false
        workoutSet.workoutExercise = testCurrentWorkout.workoutExercises?.firstObject as? WorkoutExercise
        XCTAssertNotNil(workoutSet.workoutExercise)
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
        workoutSet.workoutExercise = testWorkoutExercises.first { !$0.workout!.isCurrentWorkout }
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
        let workout = Workout.create(context: persistenContainer.viewContext)
        XCTAssertFalse(workout.hasCompletedSets!)
        
        let exercise = WorkoutExercise.create(context: persistenContainer.viewContext)
        workout.addToWorkoutExercises(exercise)
        XCTAssertFalse(workout.hasCompletedSets!)
        
        let set = WorkoutSet.create(context: persistenContainer.viewContext)
        exercise.addToWorkoutSets(set)
        XCTAssertFalse(workout.hasCompletedSets!)
        
        set.isCompleted = true
        XCTAssertTrue(workout.hasCompletedSets!)
        
        for workout in testWorkouts {
            XCTAssertTrue(workout.hasCompletedSets!)
        }
    }
    
    func testSendObjectsWillChange() {
        let workout = Workout.create(context: persistenContainer.viewContext)
        let workoutExercise1 = WorkoutExercise.create(context: persistenContainer.viewContext)
        let workoutExercise2 = WorkoutExercise.create(context: persistenContainer.viewContext)
        let workoutSet1_1 = WorkoutSet.create(context: persistenContainer.viewContext)
        let workoutSet1_2 = WorkoutSet.create(context: persistenContainer.viewContext)
        let workoutSet2_1 = WorkoutSet.create(context: persistenContainer.viewContext)
        let workoutSet2_2 = WorkoutSet.create(context: persistenContainer.viewContext)
        
        workout.start = Date()
        workout.end = Date()
        workoutSet1_1.isCompleted = true
        workoutSet1_2.isCompleted = true
        workoutSet2_1.isCompleted = true
        workoutSet2_2.isCompleted = true
        
        workoutExercise1.addToWorkoutSets([workoutSet1_1, workoutSet1_2])
        workoutExercise2.addToWorkoutSets([workoutSet2_1, workoutSet2_2])
        workout.addToWorkoutExercises([workoutExercise1, workoutExercise2])
        
        try! persistenContainer.viewContext.save()
        
        var cancellables = Set<AnyCancellable>()
        persistenContainer.viewContext.publisher.sink { WorkoutDataStorage.sendObjectsWillChange(changes: $0) }.store(in: &cancellables)
        
        var expectations = changeExpectations(reason: "increment weight", objects: [
            (workoutSet1_1.workoutExercise!.workout!, true),
            (workoutSet1_1.workoutExercise!, true),
            (workoutSet1_1, true),
            (workoutSet1_2, false),
            (workoutSet2_1, false),
            (workoutSet2_2, false)
        ], store: &cancellables)
        workoutSet1_1.weightValue += 1
        wait(for: expectations, timeout: 1)
        
        expectations = changeExpectations(reason: "set exercise uuid", objects: [
            (workoutExercise1.workout!, true),
            (workoutExercise1, true),
            (workoutExercise2, false),
            (workoutSet1_1, true),
            (workoutSet1_2, true),
            (workoutSet2_1, false),
            (workoutSet2_2, false)
        ], store: &cancellables)
        workoutExercise1.exerciseUuid = UUID()
        wait(for: expectations, timeout: 1)
        
        expectations = changeExpectations(reason: "set workout title", objects: [
            (workout, true),
            (workoutExercise1, true),
            (workoutExercise2, true),
            (workoutSet1_1, true),
            (workoutSet1_2, true),
            (workoutSet2_1, true),
            (workoutSet2_2, true)
        ], store: &cancellables)
        workout.title = "Test"
        wait(for: expectations, timeout: 1)
    }
    
    private func changeExpectations(reason: String = "", objects: [(NSManagedObject, Bool)], store: inout Set<AnyCancellable>) -> [XCTestExpectation] {
        objects.map {
            let expectation = XCTestExpectation(description: "\($0.0.entity.name ?? "object") for \(reason)")
            expectation.isInverted = !$0.1
            $0.0.objectWillChange.sink { _ in expectation.fulfill() }.store(in: &store)
            return expectation
        }
    }
}
