//
//  Rhino_FitAdvancedCoreDataTests.swift
//  Rhino FitTests
//
//  Created by Karim Abou Zeid on 17.03.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import XCTest
import CoreData
@testable import Rhino_Fit

class Rhino_FitAdvancedCoreDataTests: XCTestCase {
    let persistenContainer = setUpInMemoryNSPersistentContainer()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
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
        print(try! persistenContainer.viewContext.fetch(TrainingSet.fetchRequest() as NSFetchRequest<TrainingSet>))
        print(trainingExercise1.trainingSets?.count)
        persistenContainer.viewContext.delete(trainingSet1)
        print(try! persistenContainer.viewContext.fetch(TrainingSet.fetchRequest() as NSFetchRequest<TrainingSet>))
        print(trainingExercise1.trainingSets?.count)

        let trainingEntity = NSEntityDescription.entity(forEntityName: "Training", in: persistenContainer.viewContext)!
        let training = Training(entity: trainingEntity, insertInto: persistenContainer.viewContext)
        trainingExercise1.training = training
        
        XCTAssertNoThrow(try persistenContainer.viewContext.save())
    }
}
