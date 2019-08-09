//
//  MockTrainingsData.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

// for testing in the canvas
#if DEBUG
import CoreData
let mockManagedObjectContext: NSManagedObjectContext = {
    let persistenContainer = setUpInMemoryNSPersistentContainer()
    createMockTrainingsData(context: persistenContainer.viewContext)
    return persistenContainer.viewContext
}()

let mockCurrentTraining: Training = {
    let currentTraining = mockTraining
    currentTraining.isCurrentTraining = true
    return currentTraining
}()

let mockTraining: Training = {
    do {
        return try mockManagedObjectContext.fetch(Training.fetchRequest()).first as! Training
    } catch {
        fatalError("Fetch mock training failed")
    }
}()

let mockTrainingExercise: TrainingExercise = {
   mockTraining.trainingExercises!.firstObject as! TrainingExercise
}()

let mockTrainingSet: TrainingSet = {
    mockTrainingExercise.trainingSets!.firstObject as! TrainingSet
}()

private func setUpInMemoryNSPersistentContainer() -> NSPersistentContainer {
    let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
    
    let container = NSPersistentContainer(name: "MockTrainingsData", managedObjectModel: managedObjectModel)
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    description.shouldAddStoreAsynchronously = false // Make it simpler in test env
    
    container.persistentStoreDescriptions = [description]
    container.loadPersistentStores { (description, error) in
        // Check if the data store is in memory
        precondition( description.type == NSInMemoryStoreType )
        
        // Check if creating container wrong
        if let error = error {
            fatalError("Create an in-mem coordinator failed \(error)")
        }
    }
    return container
}

func createMockTrainingsData(context: NSManagedObjectContext) {
    for i in 1...20 {
        let training = Training(context: context)
        training.start = Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...4) * i, to: Date())!
        training.end = Calendar.current.date(byAdding: .minute, value: Int.random(in: 80...120), to: training.start!)!
        
        let exerciseIds = [
            [42, 48, 206], // bench press, cable crossover, triceps pushdown
            [122], // squat
            [9001], // overhead press
            [291, 289], // crunches, cross-body crunches
            [99], // deadlift
            [211, 206], // biceps curls, triceps pushdown
        ]
        for j in exerciseIds[Int.random(in: 0..<exerciseIds.count)] { // bench, dead, squat
            let trainingExercise = TrainingExercise(context: context)
            trainingExercise.exerciseId = Int16(j)
            trainingExercise.training = training
            
            let numberOfSets = 5 + Int.random(in: 0...4)
            for _ in 1...numberOfSets {
                let trainingSet = TrainingSet(context: context)
                trainingSet.weight = Double(Int.random(in: 20...50)) * 2.5
                trainingSet.repetitions = Int16.random(in: 1...10)
                trainingSet.isCompleted = true
                trainingSet.trainingExercise = trainingExercise
            }
        }
    }
}
#endif
