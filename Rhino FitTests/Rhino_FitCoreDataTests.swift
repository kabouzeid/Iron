//
//  Rhino_FitCoreDataTests.swift
//  Rhino FitTests
//
//  Created by Karim Abou Zeid on 15.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import XCTest
import CoreData
@testable import Rhino_Fit

class Rhino_FitCoreDataTests: XCTestCase {
    let persistenContainer = setUpInMemoryNSPersistentContainer()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        initStubs()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        persistenContainer.viewContext.rollback()
        super.tearDown()
    }
    
    func testTrainingExerciseNumberOfCompletedSets() {
        let trainingExercise = try! persistenContainer.viewContext.fetch(TrainingExercise.fetchRequest() as NSFetchRequest<TrainingExercise>)[0]
        let count = trainingExercise.trainingSets?.filter({ (set) -> Bool in
            (set as! TrainingSet).isCompleted == true
        }).count
        XCTAssertTrue(trainingExercise.numberOfCompletedSets == count)
    }
    
    func testTrainingNumberOfCompletedExercises() {
        let training = try! persistenContainer.viewContext.fetch(Training.fetchRequest() as NSFetchRequest<Training>)[0]
        let count = training.trainingExercises?.filter({ (exercise) -> Bool in
            let exercise = exercise as! TrainingExercise
            return exercise.numberOfCompletedSets == exercise.trainingSets?.count
        }).count
        XCTAssertTrue(training.numberOfCompletedExercises == count)
    }

    func initStubs() {
        if try! persistenContainer.viewContext.count(for: Training.fetchRequest() as NSFetchRequest<Training>) == 0 {
            let trainingSetEntity = NSEntityDescription.entity(forEntityName: "TrainingSet", in: persistenContainer.viewContext)!
            let Set1 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
            Set1.repetitions = 3
            Set1.isCompleted = true
            let Set2 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
            Set2.repetitions = 2
            Set2.isCompleted = true
            let Set3 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
            Set3.repetitions = 1
            let Set4 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
            Set4.repetitions = 0
            let Set5 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
            Set5.repetitions = 0
            let Set6 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
            Set6.repetitions = 3
            Set6.isCompleted = true

            let trainingExerciseEntity = NSEntityDescription.entity(forEntityName: "TrainingExercise", in: persistenContainer.viewContext)!
            let trainingExercise = TrainingExercise(entity: trainingExerciseEntity, insertInto: persistenContainer.viewContext)
            trainingExercise.addToTrainingSets([Set1,Set2,Set3,Set4,Set5])
            trainingExercise.exerciseId = 1
            let trainingExercise2 = TrainingExercise(entity: trainingExerciseEntity, insertInto: persistenContainer.viewContext)
            trainingExercise2.addToTrainingSets([Set6])
            trainingExercise2.exerciseId = 2
            
            let trainingEntity = NSEntityDescription.entity(forEntityName: "Training", in: persistenContainer.viewContext)!
            let training = Training(entity: trainingEntity, insertInto: persistenContainer.viewContext)
            training.addToTrainingExercises([trainingExercise, trainingExercise2])
            training.start = Date()
            
            XCTAssertNoThrow(try persistenContainer.viewContext.save())
        }
    }
}
