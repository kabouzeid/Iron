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
import WorkoutDataKit

struct MockWorkoutData {
    static let metric = MockWorkoutData(unit: .metric, random: false)
    static let imperial = MockWorkoutData(unit: .imperial, random: false)
    static let metricRandom = MockWorkoutData(unit: .metric, random: true)
    static let imperialRandom = MockWorkoutData(unit: .imperial, random: true)
    
    let persistentContainer: NSPersistentContainer
    let currentWorkout: Workout
    
    private init(unit: WeightUnit, random: Bool) {
        persistentContainer = Self.setUpInMemoryNSPersistentContainer()
        if random {
            Self.createRandomWorkoutData(context: persistentContainer.viewContext, unit: unit)
            currentWorkout = Self.createRandomCurrentWorkout(context: persistentContainer.viewContext, unit: unit)
        } else {
            Self.createWorkoutData(context: persistentContainer.viewContext, unit: unit)
            currentWorkout = Self.createCurrentWorkout(context: persistentContainer.viewContext, unit: unit)
        }
        Self.createWorkoutPlanStrongLifts(context: context, unit: unit)
    }
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
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
    
    var workoutPlan: WorkoutPlan {
        try! context.fetch(WorkoutPlan.fetchRequest()).first as! WorkoutPlan
    }
    
    var workoutRoutine: WorkoutRoutine {
        workoutPlan.workoutRoutines!.firstObject as! WorkoutRoutine
    }
    
    var workoutRoutineExercise: WorkoutRoutineExercise {
        workoutRoutine.workoutRoutineExercises!.firstObject! as! WorkoutRoutineExercise
    }
    
    var workoutRoutineSet: WorkoutRoutineSet {
        workoutRoutineExercise.workoutRoutineSets!.firstObject! as! WorkoutRoutineSet
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
        let container = NSPersistentContainer(name: "MockWorkoutData", managedObjectModel: WorkoutDataStorage.model)
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.type = NSInMemoryStoreType
        storeDescription.shouldAddStoreAsynchronously = false // Make it simpler in test env
        
        container.persistentStoreDescriptions = [storeDescription]
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("could not load persistent store \(storeDescription): \(error), \(error.userInfo)")
            }
            
            precondition(storeDescription.type == NSInMemoryStoreType)
        }
        return container
    }
}

// MARK: Data Generation

extension MockWorkoutData {
    private static func toUuid(_ id: Int) -> UUID? {
        ExerciseStore.shared.exercises.first { $0.everkineticId == id }?.uuid
    }
    
    private static func toUuid(_ ids: [Int]) -> [UUID] {
        ids.compactMap { toUuid($0) }
    }
    
    private static func toUuid(_ ids: [[Int]]) -> [[UUID]] {
        ids.map { toUuid($0) }
    }
    
    private static func createRandomWorkoutData(context: NSManagedObjectContext, unit: WeightUnit) {
        for i in 1...20 {
            let workout = Workout(context: context)
            workout.uuid = UUID()
            workout.start = Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...4) * i, to: Date())!
            workout.end = Calendar.current.date(byAdding: .minute, value: Int.random(in: 80...120), to: workout.start!)!
            
            createRandomWorkoutExercises(workout: workout, unit: unit)
        }
    }
    
    private static func createRandomWorkoutExercises(workout: Workout, unit: WeightUnit) {
        let exerciseUuids = toUuid([
            [42, 48, 206], // bench press, cable crossover, triceps pushdown
            [122], // squat
            [9001], // overhead press
            [291, 289], // crunches, cross-body crunches
            [99], // deadlift
            [218, 206], // biceps curls, triceps pushdown
        ])
        for uuid in exerciseUuids[Int.random(in: 0..<exerciseUuids.count)] {
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseUuid = uuid
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
        workout.uuid = UUID()
        workout.start = Calendar.current.date(byAdding: .minute, value: -71, to: Date())!
        workout.isCurrentWorkout = true
        
        for uuid in toUuid([42, 48, 206]) { // bench press, cable crossover, triceps pushdown
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseUuid = uuid
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
        for uuid in toUuid([291]) { // crunches
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseUuid = uuid
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
        for uuid in toUuid([289]) { // cross-body crunches
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseUuid = uuid
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
        let exerciseUuids = toUuid([
            [42, 48, 206], // bench press, cable crossover, triceps pushdown
            [122], // squat
            [9001], // overhead press
            [291, 289], // crunches, cross-body crunches
            [99], // deadlift
            [218, 206], // biceps curls, triceps pushdown
        ])
        
        var dayOffset = 0
        var indexOffset = 0
        for i in 0..<20 {
            for j in 0..<exerciseUuids.count {
                let number = i * exerciseUuids.count + j
                if (sin(Double(number)) > 0.5) {
                    indexOffset += 1
                    dayOffset -= 2
                }
                
                let workout = Workout(context: context)
                workout.uuid = UUID()
                workout.start = Calendar.current.date(byAdding: .minute, value: Int(sin(Double(number)) * 60), to: Calendar.current.date(byAdding: .day, value: -number + dayOffset, to: referenceDate)!)!
                workout.end = Calendar.current.date(byAdding: .minute, value: 70 + Int(sin(Double(number)) * 30) , to: workout.start!)!
                createWorkoutExercises(workout: workout, exerciseUuids: exerciseUuids[(j + indexOffset) % exerciseUuids.count], unit: unit)
            }
        }
    }

    private static func createWorkoutExercises(workout: Workout, exerciseUuids: [UUID], unit: WeightUnit) {
        for uuid in exerciseUuids {
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseUuid = uuid
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
        workout.uuid = UUID()
        workout.start = Calendar.current.date(byAdding: .minute, value: -71, to: referenceDate)!
        workout.isCurrentWorkout = true
        
        for uuid in toUuid([42, 48]) { // bench press, cable crossover
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseUuid = uuid
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
        for uuid in toUuid([218, 206]) { // biceps curls, triceps pushdown
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseUuid = uuid
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
        for uuid in toUuid([291]) { // crunches
            let workoutExercise = WorkoutExercise(context: workout.managedObjectContext!)
            workoutExercise.exerciseUuid = uuid
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

extension MockWorkoutData {
    private static func createWorkoutPlanStrongLifts(context: NSManagedObjectContext, unit: WeightUnit) {
        let create5x5 = { (weight: Double) -> [WorkoutRoutineSet] in
            (0..<5).map { _ -> WorkoutRoutineSet in
                let set = WorkoutRoutineSet(context: context)
                set.repetitions = 5
                set.weight = weight
                return set
            }
        }
        
        let workoutRoutineExerciseSquatA = WorkoutRoutineExercise(context: context)
        workoutRoutineExerciseSquatA.exerciseUuid = toUuid(122) // squat
        workoutRoutineExerciseSquatA.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 120, unit: unit)))
        
        let workoutRoutineExerciseBenchA = WorkoutRoutineExercise(context: context)
        workoutRoutineExerciseBenchA.exerciseUuid = toUuid(42) // bench
        workoutRoutineExerciseBenchA.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 80, unit: unit)))
        
        let workoutRoutineExerciseRowA = WorkoutRoutineExercise(context: context)
        workoutRoutineExerciseRowA.exerciseUuid = toUuid(298) // row
        workoutRoutineExerciseRowA.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 60, unit: unit)))
        
        let workoutRoutineA = WorkoutRoutine(context: context)
        workoutRoutineA.title = "Workout A"
        workoutRoutineA.workoutRoutineExercises = NSOrderedSet(arrayLiteral: workoutRoutineExerciseSquatA, workoutRoutineExerciseBenchA, workoutRoutineExerciseRowA)
        
        let workoutRoutineExerciseSquatB = WorkoutRoutineExercise(context: context)
        workoutRoutineExerciseSquatB.exerciseUuid = toUuid(122) // squat
        workoutRoutineExerciseSquatB.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 120, unit: unit)))
        
        let workoutRoutineExerciseBenchB = WorkoutRoutineExercise(context: context)
        workoutRoutineExerciseBenchB.exerciseUuid = toUuid(9001) // press
        workoutRoutineExerciseBenchB.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 65, unit: unit)))
        
        let workoutRoutineExerciseRowB = WorkoutRoutineExercise(context: context)
        workoutRoutineExerciseRowB.exerciseUuid = toUuid(99) // deadlift
        workoutRoutineExerciseRowB.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 140, unit: unit)))
        
        let workoutRoutineB = WorkoutRoutine(context: context)
        workoutRoutineB.title = "Workout B"
        workoutRoutineB.workoutRoutineExercises = NSOrderedSet(arrayLiteral: workoutRoutineExerciseSquatB, workoutRoutineExerciseBenchB, workoutRoutineExerciseRowB)
        
        let workoutPlan = WorkoutPlan(context: context)
        workoutPlan.title = "StrongLifts 5x5"
        workoutPlan.workoutRoutines = NSOrderedSet(arrayLiteral: workoutRoutineA, workoutRoutineB)
    }
}

#endif
