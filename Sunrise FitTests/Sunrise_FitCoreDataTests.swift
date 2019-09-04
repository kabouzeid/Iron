//
//  Rhino_FitCoreDataTests.swift
//  Rhino FitTests
//
//  Created by Karim Abou Zeid on 15.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import XCTest
import CoreData
@testable import Sunrise_Fit

class Sunrise_FitCoreDataTests: XCTestCase {
    var persistenContainer: NSPersistentContainer!
    
    var testTrainings: [Training]!
    var testTrainingExercises: [TrainingExercise]!
    var testTrainingSets: [TrainingSet]!
    
    var testCurrentTraining: Training!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        persistenContainer = setUpInMemoryNSPersistentContainer()

        createTestTrainingsData(context: persistenContainer.viewContext)
        testCurrentTraining = createTestCurrentTraining(context: persistenContainer.viewContext)
        
        testTrainings = try? persistenContainer.viewContext.fetch(Training.fetchRequest()) as? [Training]
        testTrainingExercises = try? persistenContainer.viewContext.fetch(TrainingExercise.fetchRequest()) as? [TrainingExercise]
        testTrainingSets = try? persistenContainer.viewContext.fetch(TrainingSet.fetchRequest()) as? [TrainingSet]

        XCTAssertNotNil(testTrainings)
        XCTAssertTrue(testTrainings.count > 0)
        XCTAssertTrue(testTrainings.count == 2) // might change in future
        XCTAssertNotNil(testTrainingExercises)
        XCTAssertTrue(testTrainingExercises.count > 0)
        XCTAssertNotNil(testTrainingSets)
        XCTAssertTrue(testTrainingSets.count > 0)
        
        XCTAssertNotNil(testCurrentTraining)
        
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        persistenContainer.viewContext.reset()
        persistenContainer = nil
        
        testTrainings = nil
        testTrainingExercises = nil
        testTrainingSets = nil
        testCurrentTraining = nil
        
        super.tearDown()
    }
    
    func testTrainingExerciseNumberOfCompletedSets() {
        for trainingExercise in testTrainingExercises {
            let count = trainingExercise.trainingSets?.filter({ (set) -> Bool in
                (set as! TrainingSet).isCompleted == true
            }).count
            XCTAssertTrue(trainingExercise.numberOfCompletedSets == count)
        }
    }
    
    func testTrainingNumberOfCompletedExercises() {
        for training in testTrainings {
            let count = training.trainingExercises?.filter({ (exercise) -> Bool in
                let exercise = exercise as! TrainingExercise
                return exercise.numberOfCompletedSets == exercise.trainingSets?.count
            }).count
            XCTAssertTrue(training.numberOfCompletedExercises == count)
        }
    }
    
    func testRelationshipDeleteRules() {
        // create some sets
        let trainingSetEntity = NSEntityDescription.entity(forEntityName: "TrainingSet", in: persistenContainer.viewContext)!
        let trainingSet1 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
        let trainingSet2 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
        let trainingSet3 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
        let trainingSet4 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
        XCTAssertThrowsError(try persistenContainer.viewContext.save()) // trainingExercise not set
        
        // create some exercises
        let trainingExerciseEntity = NSEntityDescription.entity(forEntityName: "TrainingExercise", in: persistenContainer.viewContext)!
        let trainingExercise1 = TrainingExercise(entity: trainingExerciseEntity, insertInto: persistenContainer.viewContext)
        let trainingExercise2 = TrainingExercise(entity: trainingExerciseEntity, insertInto: persistenContainer.viewContext)
        trainingSet1.trainingExercise = trainingExercise1
        trainingSet2.trainingExercise = trainingExercise1
        trainingSet3.trainingExercise = trainingExercise2
        trainingSet4.trainingExercise = trainingExercise2
        XCTAssertThrowsError(try persistenContainer.viewContext.save()) // training not set
        XCTAssertTrue(trainingExercise1.trainingSets!.count == 2)
        XCTAssertTrue(trainingExercise2.trainingSets!.count == 2)
        
        // create a training
        let trainingEntity = NSEntityDescription.entity(forEntityName: "Training", in: persistenContainer.viewContext)!
        let training = Training(entity: trainingEntity, insertInto: persistenContainer.viewContext)
        training.isCurrentTraining = true
        trainingExercise1.training = training
        trainingExercise2.training = training
        XCTAssertNoThrow(try persistenContainer.viewContext.save()) //everything set
        
        // deleting a set
        XCTAssertTrue(trainingExercise1.trainingSets!.count == 2)
        persistenContainer.viewContext.delete(trainingSet1)
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
        XCTAssertNil(trainingSet1.managedObjectContext)
        // didn't delete the exercise
        XCTAssertNotNil(trainingExercise1.managedObjectContext)
        // got removed from the exercise list
        XCTAssertTrue(trainingExercise1.trainingSets!.count == 1)
        
        // deleting an exercise
        XCTAssertTrue(training.trainingExercises!.count == 2)
        persistenContainer.viewContext.delete(trainingExercise1)
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
        XCTAssertNil(trainingExercise1.managedObjectContext)
        // didn't delete the training
        XCTAssertNotNil(training.managedObjectContext)
        // got removed from the exercise list
        XCTAssertTrue(training.trainingExercises!.count == 1)
        // deleted its sets
        XCTAssertNil(trainingSet2.managedObjectContext)
        
        // deleting a training
        persistenContainer.viewContext.delete(training)
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
        XCTAssertNil(training.managedObjectContext)
        // deleted its exercises
        XCTAssertNil(trainingExercise2.managedObjectContext)
        // exercises deleted their sets
        XCTAssertNil(trainingSet3.managedObjectContext)
        XCTAssertNil(trainingSet4.managedObjectContext)
    }
    
    func testSaveTrainingWithNoSets() {
        let trainingSetEntity = NSEntityDescription.entity(forEntityName: "TrainingSet", in: persistenContainer.viewContext)!
        let trainingSet1 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
        
        let trainingExerciseEntity = NSEntityDescription.entity(forEntityName: "TrainingExercise", in: persistenContainer.viewContext)!
        let trainingExercise1 = TrainingExercise(entity: trainingExerciseEntity, insertInto: persistenContainer.viewContext)
        trainingSet1.trainingExercise = trainingExercise1
        persistenContainer.viewContext.delete(trainingSet1)

        let trainingEntity = NSEntityDescription.entity(forEntityName: "Training", in: persistenContainer.viewContext)!
        let training = Training(entity: trainingEntity, insertInto: persistenContainer.viewContext)
        trainingExercise1.training = training
        
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
    }
    
    func uncompletedSetsSwift(training: Training) -> [TrainingSet]? {
        return training.trainingExercises?
            .compactMap { $0 as? TrainingExercise }
            .compactMap { $0.trainingSets?.array as? [TrainingSet] }
            .flatMap { $0 }
            .filter { !$0.isCompleted }
    }
    
    func uncompletedSetsFetch(training: Training) -> [TrainingSet]? {
        let fetchRequest: NSFetchRequest<TrainingSet> = TrainingSet.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(#keyPath(TrainingSet.trainingExercise.training)) == %@ AND \(#keyPath(TrainingSet.isCompleted)) == %@", training, NSNumber(booleanLiteral: false))
        return try? training.managedObjectContext?.fetch(fetchRequest)
    }
    
    func testUncompletedSets() {
        for training in testTrainings {
            XCTAssertEqual(Set(uncompletedSetsSwift(training: training) ?? []), Set(uncompletedSetsFetch(training: training) ?? []))
        }
    }
    
    func testUncompletedSetsSwift() {
        self.measure {
            for training in testTrainings {
                _ = uncompletedSetsSwift(training: training)
            }
        }
    }
    
    func testUncompletedSetsFetch() {
        self.measure {
            for training in testTrainings {
                _ = uncompletedSetsFetch(training: training)
            }
        }
    }
    
    func testDeleteUncompletedSets() {
        testCurrentTraining.deleteAndRemoveUncompletedSets()
        XCTAssertTrue(
            testCurrentTraining.trainingExercises?
                .compactMap { $0 as? TrainingExercise }
                .compactMap { $0.trainingSets?.array as? [TrainingSet] }
                .flatMap { $0 }
                .filter { !$0.isCompleted }
                .isEmpty ?? true
        )
    }
    
    func testStartEndValidation() {
        for training in testTrainings {
            if let start = training.start, let end = training.end {
                training.start = end
                training.end = start
                XCTAssertThrowsError(try persistenContainer.viewContext.save())
                
                training.start = nil
                training.end = end
                XCTAssertThrowsError(try persistenContainer.viewContext.save())
                
                training.start = start
                training.end = nil
                XCTAssertNoThrow(try persistenContainer.viewContext.save())
            }
        }
    }
    
    func testCurrentTrainingValidation() {
        XCTAssertEqual(try persistenContainer.viewContext.count(for: Training.currentTrainingFetchRequest), 1)
        let training = createTestCurrentTraining(context: persistenContainer.viewContext)
        XCTAssertEqual(try persistenContainer.viewContext.count(for: Training.currentTrainingFetchRequest), 2)
        XCTAssertThrowsError(try persistenContainer.viewContext.save())
        persistenContainer.viewContext.delete(training)
        XCTAssertEqual(try persistenContainer.viewContext.count(for: Training.currentTrainingFetchRequest), 1)
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
        persistenContainer.viewContext.delete(testCurrentTraining)
        XCTAssertEqual(try persistenContainer.viewContext.count(for: Training.currentTrainingFetchRequest), 0)
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
        _ = createTestCurrentTraining(context: persistenContainer.viewContext)
        XCTAssertEqual(try persistenContainer.viewContext.count(for: Training.currentTrainingFetchRequest), 1)
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
    }
}
