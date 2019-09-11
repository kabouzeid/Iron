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
    
    func testRelationshipDeleteRules() {
        for training in testTrainings {
            let trainingExercises = training.trainingExercises!.array.map { $0 as! TrainingExercise }
            
            let trainingExercise = trainingExercises.first!
            let trainingSets = trainingExercise.trainingSets!.array.map { $0 as! TrainingSet }
            
            // set deletion doesn't delete exercise
            let trainingSet = trainingSets.first!
            persistenContainer.viewContext.delete(trainingSet)
            XCTAssertNoThrow(try persistenContainer.viewContext.save())
            XCTAssertNil(trainingSet.managedObjectContext)
            XCTAssertNotNil(trainingExercise.managedObjectContext)
            
            // exercise deletion doesn't delete training, but deletes sets
            persistenContainer.viewContext.delete(trainingExercise)
            XCTAssertNoThrow(try persistenContainer.viewContext.save())
            XCTAssertNil(trainingExercise.managedObjectContext)
            XCTAssertTrue(trainingSets.reduce(true, { $0 && $1.managedObjectContext == nil }))
            XCTAssertNotNil(training.managedObjectContext)

            // training deletion deletes exercises
            persistenContainer.viewContext.delete(training)
            XCTAssertNoThrow(try persistenContainer.viewContext.save())
            XCTAssertNil(training.managedObjectContext)
            XCTAssertTrue(trainingExercises.reduce(true, { $0 && $1.managedObjectContext == nil }))
        }
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
        testCurrentTraining.deleteUncompletedSets()
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
                if training.isCurrentTraining {
                    XCTAssertNoThrow(try persistenContainer.viewContext.save())
                } else {
                    XCTAssertThrowsError(try persistenContainer.viewContext.save())
                }
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
    
    func testTrainingIsCompletedValidation() {
        testCurrentTraining.isCurrentTraining = false
        XCTAssertThrowsError(try persistenContainer.viewContext.save())
        testCurrentTraining.isCurrentTraining = true
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
        
        for trainingSet in testTrainingSets {
            if let training = trainingSet.trainingExercise?.training, !training.isCurrentTraining {
                trainingSet.isCompleted = false
                XCTAssertThrowsError(try persistenContainer.viewContext.save())
                trainingSet.isCompleted = true
                XCTAssertNoThrow(try persistenContainer.viewContext.save())
            }
        }
    }
}
