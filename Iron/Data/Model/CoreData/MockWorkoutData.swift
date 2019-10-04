//
//  MockWorkoutData.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

// for testing in the canvas, tests and screenshots
#if DEBUG
import CoreData

struct MockWorkoutData {
    static let metric = MockWorkoutData(unit: .metric, random: false)
    static let imperial = MockWorkoutData(unit: .imperial, random: false)
    static let metricRandom = MockWorkoutData(unit: .metric, random: true)
    static let imperialRandom = MockWorkoutData(unit: .imperial, random: true)
    
    let persistenContainer: NSPersistentContainer
    let currentWorkout: Workout
    
    private init(unit: WeightUnit, random: Bool) {
        persistenContainer = Self.setUpInMemoryNSPersistentContainer()
        if random {
            Self.createRandomWorkoutData(context: persistenContainer.viewContext, unit: unit)
            currentWorkout = Self.createRandomCurrentWorkout(context: persistenContainer.viewContext, unit: unit)
        } else {
            Self.createWorkoutData(context: persistenContainer.viewContext, unit: unit)
            currentWorkout = Self.createCurrentWorkout(context: persistenContainer.viewContext, unit: unit)
        }
    }
    
    var context: NSManagedObjectContext {
        persistenContainer.viewContext
    }
    
    var workout: Workout {
        try! context.fetch(Workout.fetchRequest()).first as! Workout
    }
    
    var workoutExercise: WorkoutExercise {
       workout.workoutExercises!.firstObject as! WorkoutExercise
    }

    var workoutSet: WorkoutSet {
        workoutExercise.workoutSets!.firstObject as! WorkoutSet
    }
}

extension MockWorkoutData {
    // returns a metric weight that translates to a nice value in the given unit
    private static func niceWeight(weight: Double, unit: WeightUnit) -> Double {
        let weightInUnit = WeightUnit.convert(weight: weight, from: .metric, to: unit)
        let nice = weightInUnit - weightInUnit.truncatingRemainder(dividingBy: unit.barbellIncrement)
        return WeightUnit.convert(weight: nice, from: unit, to: .metric)
    }
}

// MARK: In Memory Context

extension MockWorkoutData {
    private static func setUpInMemoryNSPersistentContainer() -> NSPersistentContainer {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        
        let container = NSPersistentContainer(name: "MockWorkoutData", managedObjectModel: managedObjectModel)
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

extension MockWorkoutData {
    private static func createRandomWorkoutData(context: NSManagedObjectContext, unit: WeightUnit) {
        for i in 1...20 {
            let workout = Workout(context: context)
            workout.start = Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...4) * i, to: Date())!
            workout.end = Calendar.current.date(byAdding: .minute, value: Int.random(in: 80...120), to: workout.start!)!
            
            createRandomWorkoutExercises(workout: workout, unit: unit)
        }
    }
    
    private static func createRandomWorkoutExercises(workout: Workout, unit: WeightUnit) {
        let exerciseIds = [
            [42, 48, 206], // bench press, cable crossover, triceps pushdown
            [122], // squat
            [9001], // overhead press
            [291, 289], // crunches, cross-body crunches
            [99], // deadlift
            [218, 206], // biceps curls, triceps pushdown
        ]
        for j in exerciseIds[Int.random(in: 0..<exerciseIds.count)] {
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseId = Int16(j)
            workoutExercise.workout = workout
            
            let numberOfSets = 5 + Int.random(in: 0...4)
            for _ in 1...numberOfSets {
                let workoutSet = WorkoutSet(context: workout.managedObjectContext!)
                workoutSet.weight = niceWeight(weight: Double(Int.random(in: 20...50)) * 2.5, unit: unit)
                workoutSet.repetitions = Int16.random(in: 1...10)
                workoutSet.comment = Int.random(in: 1...5) == 1 ? "This is a comment" : nil
                workoutSet.displayRpe = Int.random(in: 1...5) == 1 ? (Double(Int.random(in: 0..<7)) * 0.5 + 7) : nil
                switch Int.random(in: 1...15) {
    //            case 1:
    //                workoutSet.displayTag = .warmUp
                case 2:
                    workoutSet.displayTag = .dropSet
                case 3:
                    workoutSet.displayTag = .failure
                default:
                    break
                }
                workoutSet.isCompleted = true
                workoutSet.workoutExercise = workoutExercise
            }
        }
    }
    
    private static func createRandomCurrentWorkout(context: NSManagedObjectContext, unit: WeightUnit) -> Workout {
        let workout = Workout(context: context)
        workout.start = Calendar.current.date(byAdding: .minute, value: -71, to: Date())!
        workout.isCurrentWorkout = true
        
        for j in [42, 48, 206] { // bench press, cable crossover, triceps pushdown
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseId = Int16(j)
            workoutExercise.workout = workout
            
            let numberOfSets = 5 + Int.random(in: 0...4)
            for _ in 1...numberOfSets {
                let workoutSet = WorkoutSet(context: workout.managedObjectContext!)
                workoutSet.weight = niceWeight(weight: Double(Int.random(in: 20...50)) * 2.5, unit: unit)
                workoutSet.repetitions = Int16.random(in: 1...10)
                workoutSet.isCompleted = true
                workoutSet.workoutExercise = workoutExercise
            }
        }
        for j in [291] { // crunches
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseId = Int16(j)
            workoutExercise.workout = workout
            
            let numberOfSets = 5 + Int.random(in: 0...4)
            for setNumber in 1...numberOfSets {
                let workoutSet = WorkoutSet(context: workout.managedObjectContext!)
                workoutSet.workoutExercise = workoutExercise
                switch setNumber {
                case 1:
                    workoutSet.weight = niceWeight(weight: Double(Int.random(in: 20...50)) * 2.5, unit: unit)
                    workoutSet.repetitions = Int16.random(in: 1...10)
                    workoutSet.isCompleted = true
                default:
                    workoutSet.isCompleted = false
                }
            }
        }
        for j in [289] { // cross-body crunches
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseId = Int16(j)
            workoutExercise.workout = workout
            
            let numberOfSets = 5 + Int.random(in: 0...4)
            for _ in 1...numberOfSets {
                let workoutSet = WorkoutSet(context: workout.managedObjectContext!)
                workoutSet.workoutExercise = workoutExercise
                workoutSet.isCompleted = false
            }
        }
        return workout
    }
}

extension MockWorkoutData {
    private static func createWorkoutData(context: NSManagedObjectContext, unit: WeightUnit, referenceDate: Date = Date()) {
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
                
                let workout = Workout(context: context)
                workout.start = Calendar.current.date(byAdding: .minute, value: Int(sin(Double(number)) * 60), to: Calendar.current.date(byAdding: .day, value: -number + dayOffset, to: referenceDate)!)!
                workout.end = Calendar.current.date(byAdding: .minute, value: 70 + Int(sin(Double(number)) * 30) , to: workout.start!)!
                createWorkoutExercises(workout: workout, exerciseIds: exerciseIds[(j + indexOffset) % exerciseIds.count], unit: unit)
            }
        }
    }

    private static func createWorkoutExercises(workout: Workout, exerciseIds: [Int], unit: WeightUnit) {
        for j in exerciseIds {
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseId = Int16(j)
            workoutExercise.workout = workout
            
            let numberOfSets = 5
            for setNumber in 1...numberOfSets {
                let workoutSet = WorkoutSet(context: workout.managedObjectContext!)
                workoutSet.weight = niceWeight(weight: 50 + Double(setNumber) * 2.5, unit: unit)
                workoutSet.repetitions = Int16(3 + setNumber)
                workoutSet.isCompleted = true
                workoutSet.workoutExercise = workoutExercise
            }
        }
    }

    private static func createCurrentWorkout(context: NSManagedObjectContext, unit: WeightUnit, referenceDate: Date = Date()) -> Workout {
        let workout = Workout(context: context)
        workout.start = Calendar.current.date(byAdding: .minute, value: -71, to: referenceDate)!
        workout.isCurrentWorkout = true
        
        for j in [42, 48] { // bench press, cable crossover
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseId = Int16(j)
            workoutExercise.workout = workout
            
            let numberOfSets = 5
            for setNumber in 1...numberOfSets {
                let workoutSet = WorkoutSet(context: workout.managedObjectContext!)
                workoutSet.weight = niceWeight(weight: 50 + Double(setNumber) * 2.5, unit: unit)
                workoutSet.repetitions = Int16(3 + setNumber)
                workoutSet.isCompleted = true
                workoutSet.workoutExercise = workoutExercise
            }
        }
        for j in [218, 206] { // biceps curls, triceps pushdown
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseId = Int16(j)
            workoutExercise.workout = workout
            
            let numberOfSets = 6
            for setNumber in 1...numberOfSets {
                let workoutSet = WorkoutSet(context: workout.managedObjectContext!)
                workoutSet.workoutExercise = workoutExercise
                switch setNumber {
                case 1:
                    workoutSet.weight = niceWeight(weight: 20 + Double(setNumber) * 2.5, unit: unit)
                    workoutSet.repetitions = Int16(3 + setNumber)
                    workoutSet.isCompleted = true
                case 2:
                    workoutSet.weight = niceWeight(weight: 20 + Double(setNumber) * 2.5, unit: unit)
                    workoutSet.repetitions = Int16(3 + setNumber)
                    workoutSet.isCompleted = false
                default:
                    workoutSet.isCompleted = false
                }
            }
        }
        for j in [291] { // crunches
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseId = Int16(j)
            workoutExercise.workout = workout
            
            let numberOfSets = 3
            for _ in 1...numberOfSets {
                let workoutSet = WorkoutSet(context: workout.managedObjectContext!)
                workoutSet.workoutExercise = workoutExercise
                workoutSet.isCompleted = false
            }
        }
        return workout
    }
}

#endif
