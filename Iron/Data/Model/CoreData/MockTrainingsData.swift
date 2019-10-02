//
//  MockTrainingsData.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

// for testing in the canvas, tests and screenshots
#if DEBUG
import CoreData

struct MockTrainingsData {
    static let metric = MockTrainingsData(unit: .metric, random: false)
    static let imperial = MockTrainingsData(unit: .imperial, random: false)
    static let metricRandom = MockTrainingsData(unit: .metric, random: true)
    static let imperialRandom = MockTrainingsData(unit: .imperial, random: true)
    
    let persistenContainer: NSPersistentContainer
    let currentTraining: Training
    
    private init(unit: WeightUnit, random: Bool) {
        persistenContainer = Self.setUpInMemoryNSPersistentContainer()
        if random {
            Self.createRandomTrainingsData(context: persistenContainer.viewContext, unit: unit)
            currentTraining = Self.createRandomCurrentTraining(context: persistenContainer.viewContext, unit: unit)
        } else {
            Self.createTrainingsData(context: persistenContainer.viewContext, unit: unit)
            currentTraining = Self.createCurrentTraining(context: persistenContainer.viewContext, unit: unit)
        }
    }
    
    var context: NSManagedObjectContext {
        persistenContainer.viewContext
    }
    
    var training: Training {
        try! context.fetch(Training.fetchRequest()).first as! Training
    }
    
    var trainingExercise: TrainingExercise {
       training.trainingExercises!.firstObject as! TrainingExercise
    }

    var trainingSet: TrainingSet {
        trainingExercise.trainingSets!.firstObject as! TrainingSet
    }
}

extension MockTrainingsData {
    // returns a metric weight that translates to a nice value in the given unit
    private static func niceWeight(weight: Double, unit: WeightUnit) -> Double {
        let weightInUnit = WeightUnit.convert(weight: weight, from: .metric, to: unit)
        let nice = weightInUnit - weightInUnit.truncatingRemainder(dividingBy: unit.barbellIncrement)
        return WeightUnit.convert(weight: nice, from: unit, to: .metric)
    }
}

// MARK: In Memory Context

extension MockTrainingsData {
    private static func setUpInMemoryNSPersistentContainer() -> NSPersistentContainer {
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
}

// MARK: Data Generation

extension MockTrainingsData {
    private static func createRandomTrainingsData(context: NSManagedObjectContext, unit: WeightUnit) {
        for i in 1...20 {
            let training = Training(context: context)
            training.start = Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...4) * i, to: Date())!
            training.end = Calendar.current.date(byAdding: .minute, value: Int.random(in: 80...120), to: training.start!)!
            
            createRandomTrainingExercises(training: training, unit: unit)
        }
    }
    
    private static func createRandomTrainingExercises(training: Training, unit: WeightUnit) {
        let exerciseIds = [
            [42, 48, 206], // bench press, cable crossover, triceps pushdown
            [122], // squat
            [9001], // overhead press
            [291, 289], // crunches, cross-body crunches
            [99], // deadlift
            [218, 206], // biceps curls, triceps pushdown
        ]
        for j in exerciseIds[Int.random(in: 0..<exerciseIds.count)] {
            let trainingExercise = TrainingExercise(context: training.managedObjectContext!)
            trainingExercise.exerciseId = Int16(j)
            trainingExercise.training = training
            
            let numberOfSets = 5 + Int.random(in: 0...4)
            for _ in 1...numberOfSets {
                let trainingSet = TrainingSet(context: training.managedObjectContext!)
                trainingSet.weight = niceWeight(weight: Double(Int.random(in: 20...50)) * 2.5, unit: unit)
                trainingSet.repetitions = Int16.random(in: 1...10)
                trainingSet.comment = Int.random(in: 1...5) == 1 ? "This is a comment" : nil
                trainingSet.displayRpe = Int.random(in: 1...5) == 1 ? (Double(Int.random(in: 0..<7)) * 0.5 + 7) : nil
                switch Int.random(in: 1...15) {
    //            case 1:
    //                trainingSet.displayTag = .warmUp
                case 2:
                    trainingSet.displayTag = .dropSet
                case 3:
                    trainingSet.displayTag = .failure
                default:
                    break
                }
                trainingSet.isCompleted = true
                trainingSet.trainingExercise = trainingExercise
            }
        }
    }
    
    private static func createRandomCurrentTraining(context: NSManagedObjectContext, unit: WeightUnit) -> Training {
        let training = Training(context: context)
        training.start = Calendar.current.date(byAdding: .minute, value: -71, to: Date())!
        training.isCurrentTraining = true
        
        for j in [42, 48, 206] { // bench press, cable crossover, triceps pushdown
            let trainingExercise = TrainingExercise(context: training.managedObjectContext!)
            trainingExercise.exerciseId = Int16(j)
            trainingExercise.training = training
            
            let numberOfSets = 5 + Int.random(in: 0...4)
            for _ in 1...numberOfSets {
                let trainingSet = TrainingSet(context: training.managedObjectContext!)
                trainingSet.weight = niceWeight(weight: Double(Int.random(in: 20...50)) * 2.5, unit: unit)
                trainingSet.repetitions = Int16.random(in: 1...10)
                trainingSet.isCompleted = true
                trainingSet.trainingExercise = trainingExercise
            }
        }
        for j in [291] { // crunches
            let trainingExercise = TrainingExercise(context: training.managedObjectContext!)
            trainingExercise.exerciseId = Int16(j)
            trainingExercise.training = training
            
            let numberOfSets = 5 + Int.random(in: 0...4)
            for setNumber in 1...numberOfSets {
                let trainingSet = TrainingSet(context: training.managedObjectContext!)
                trainingSet.trainingExercise = trainingExercise
                switch setNumber {
                case 1:
                    trainingSet.weight = niceWeight(weight: Double(Int.random(in: 20...50)) * 2.5, unit: unit)
                    trainingSet.repetitions = Int16.random(in: 1...10)
                    trainingSet.isCompleted = true
                default:
                    trainingSet.isCompleted = false
                }
            }
        }
        for j in [289] { // cross-body crunches
            let trainingExercise = TrainingExercise(context: training.managedObjectContext!)
            trainingExercise.exerciseId = Int16(j)
            trainingExercise.training = training
            
            let numberOfSets = 5 + Int.random(in: 0...4)
            for _ in 1...numberOfSets {
                let trainingSet = TrainingSet(context: training.managedObjectContext!)
                trainingSet.trainingExercise = trainingExercise
                trainingSet.isCompleted = false
            }
        }
        return training
    }
}

extension MockTrainingsData {
    private static func createTrainingsData(context: NSManagedObjectContext, unit: WeightUnit, referenceDate: Date = Date()) {
        let exerciseIds = [
            [42, 48, 206], // bench press, cable crossover, triceps pushdown
            [122], // squat
            [9001], // overhead press
            [291, 289], // crunches, cross-body crunches
            [99], // deadlift
            [218, 206], // biceps curls, triceps pushdown
        ]
        
        var dayOffset = 0
        var indexOffset = 0
        for i in 0..<20 {
            for j in 0..<exerciseIds.count {
                let number = i * exerciseIds.count + j
                if (sin(Double(number)) > 0.5) {
                    indexOffset += 1
                    dayOffset -= 2
                }
                
                let training = Training(context: context)
                training.start = Calendar.current.date(byAdding: .minute, value: Int(sin(Double(number)) * 60), to: Calendar.current.date(byAdding: .day, value: -number + dayOffset, to: referenceDate)!)!
                training.end = Calendar.current.date(byAdding: .minute, value: 70 + Int(sin(Double(number)) * 30) , to: training.start!)!
                createTrainingExercises(training: training, exerciseIds: exerciseIds[(j + indexOffset) % exerciseIds.count], unit: unit)
            }
        }
    }

    private static func createTrainingExercises(training: Training, exerciseIds: [Int], unit: WeightUnit) {
        for j in exerciseIds {
            let trainingExercise = TrainingExercise(context: training.managedObjectContext!)
            trainingExercise.exerciseId = Int16(j)
            trainingExercise.training = training
            
            let numberOfSets = 5
            for setNumber in 1...numberOfSets {
                let trainingSet = TrainingSet(context: training.managedObjectContext!)
                trainingSet.weight = niceWeight(weight: 50 + Double(setNumber) * 2.5, unit: unit)
                trainingSet.repetitions = Int16(3 + setNumber)
                trainingSet.isCompleted = true
                trainingSet.trainingExercise = trainingExercise
            }
        }
    }

    private static func createCurrentTraining(context: NSManagedObjectContext, unit: WeightUnit, referenceDate: Date = Date()) -> Training {
        let training = Training(context: context)
        training.start = Calendar.current.date(byAdding: .minute, value: -71, to: referenceDate)!
        training.isCurrentTraining = true
        
        for j in [42, 48] { // bench press, cable crossover
            let trainingExercise = TrainingExercise(context: training.managedObjectContext!)
            trainingExercise.exerciseId = Int16(j)
            trainingExercise.training = training
            
            let numberOfSets = 5
            for setNumber in 1...numberOfSets {
                let trainingSet = TrainingSet(context: training.managedObjectContext!)
                trainingSet.weight = niceWeight(weight: 50 + Double(setNumber) * 2.5, unit: unit)
                trainingSet.repetitions = Int16(3 + setNumber)
                trainingSet.isCompleted = true
                trainingSet.trainingExercise = trainingExercise
            }
        }
        for j in [218, 206] { // biceps curls, triceps pushdown
            let trainingExercise = TrainingExercise(context: training.managedObjectContext!)
            trainingExercise.exerciseId = Int16(j)
            trainingExercise.training = training
            
            let numberOfSets = 6
            for setNumber in 1...numberOfSets {
                let trainingSet = TrainingSet(context: training.managedObjectContext!)
                trainingSet.trainingExercise = trainingExercise
                switch setNumber {
                case 1:
                    trainingSet.weight = niceWeight(weight: 20 + Double(setNumber) * 2.5, unit: unit)
                    trainingSet.repetitions = Int16(3 + setNumber)
                    trainingSet.isCompleted = true
                case 2:
                    trainingSet.weight = niceWeight(weight: 20 + Double(setNumber) * 2.5, unit: unit)
                    trainingSet.repetitions = Int16(3 + setNumber)
                    trainingSet.isCompleted = false
                default:
                    trainingSet.isCompleted = false
                }
            }
        }
        for j in [291] { // crunches
            let trainingExercise = TrainingExercise(context: training.managedObjectContext!)
            trainingExercise.exerciseId = Int16(j)
            trainingExercise.training = training
            
            let numberOfSets = 3
            for _ in 1...numberOfSets {
                let trainingSet = TrainingSet(context: training.managedObjectContext!)
                trainingSet.trainingExercise = trainingExercise
                trainingSet.isCompleted = false
            }
        }
        return training
    }
}

#endif
