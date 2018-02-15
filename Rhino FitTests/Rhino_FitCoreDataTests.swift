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
        super.tearDown()
    }
    
    func testTrainingExerciseNumberOfCompletedSets() {
        let trainingExercise = try! persistenContainer.viewContext.fetch(TrainingExercise.fetchRequest() as NSFetchRequest<TrainingExercise>)[0]
        let count = trainingExercise.trainingSets?.filter({ (set) -> Bool in
            (set as! TrainingSet).repetitions != 0
        }).count
        assert(trainingExercise.numberOfCompletedSets() == count)
    }

    func initStubs() {
        if try! persistenContainer.viewContext.count(for: Training.fetchRequest() as NSFetchRequest<Training>) == 0 {
            let trainingSetEntity = NSEntityDescription.entity(forEntityName: "TrainingSet", in: persistenContainer.viewContext)!
            let Set1 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
            Set1.repetitions = 3
            let Set2 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
            Set2.repetitions = 2
            let Set3 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
            Set3.repetitions = 1
            let Set4 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
            Set4.repetitions = 0
            let Set5 = TrainingSet(entity: trainingSetEntity, insertInto: persistenContainer.viewContext)
            Set5.repetitions = 0

            let trainingExerciseEntity = NSEntityDescription.entity(forEntityName: "TrainingExercise", in: persistenContainer.viewContext)!
            let trainingExercise = TrainingExercise(entity: trainingExerciseEntity, insertInto: persistenContainer.viewContext)
            trainingExercise.addToTrainingSets([Set1,Set2,Set3,Set4,Set5])
            trainingExercise.exerciseId = 1
            
            let trainingEntity = NSEntityDescription.entity(forEntityName: "Training", in: persistenContainer.viewContext)!
            let training = Training(entity: trainingEntity, insertInto: persistenContainer.viewContext)
            training.addToTrainingExercises(trainingExercise)
            training.date = Date()
        }
    }
    
}
