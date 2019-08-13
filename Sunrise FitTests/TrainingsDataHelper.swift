//
//  TrainingsDataHelper.swift
//  Sunrise FitTests
//
//  Created by Karim Abou Zeid on 13.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
@testable import Sunrise_Fit

private let testDate = Date(timeIntervalSince1970: 1565692122) // approx 13. August 2019

func createTestTrainingsData(context: NSManagedObjectContext) {
    let training = Training(context: context)
    training.start = Calendar.current.date(byAdding: .day, value: -2, to: testDate)!
    training.end = Calendar.current.date(byAdding: .minute, value: 110, to: training.start!)!
    
    createTestTrainingExercises(training: training)
}

private func createTestTrainingExercises(training: Training) {
    let exerciseIds = [
        [42, 48, 206], // bench press, cable crossover, triceps pushdown
        [122], // squat
        [9001], // overhead press
        [291, 289], // crunches, cross-body crunches
        [99], // deadlift
        [211, 206], // biceps curls, triceps pushdown
    ]
    for ids in exerciseIds {
        for j in ids {
            let trainingExercise = TrainingExercise(context: training.managedObjectContext!)
            trainingExercise.exerciseId = Int16(j)
            trainingExercise.training = training
            
            let numberOfSets = 5
            for setNumber in 1...numberOfSets {
                let trainingSet = TrainingSet(context: training.managedObjectContext!)
                trainingSet.weight = 50 + Double(setNumber) * 2.5
                trainingSet.repetitions = Int16(3 + setNumber)
                trainingSet.isCompleted = true
                trainingSet.trainingExercise = trainingExercise
            }
        }
    }
}

func createTestCurrentTraining(context: NSManagedObjectContext) -> Training {
    let training = Training(context: context)
    training.start = Calendar.current.date(byAdding: .minute, value: -71, to: testDate)!
    training.isCurrentTraining = true
    
    for j in [42, 48, 206] { // bench press, cable crossover, triceps pushdown
        let trainingExercise = TrainingExercise(context: training.managedObjectContext!)
        trainingExercise.exerciseId = Int16(j)
        trainingExercise.training = training
        
        let numberOfSets = 5
        for setNumber in 1...numberOfSets {
            let trainingSet = TrainingSet(context: training.managedObjectContext!)
            trainingSet.weight = 50 + Double(setNumber) * 2.5
            trainingSet.repetitions = Int16(3 + setNumber)
            trainingSet.isCompleted = true
            trainingSet.trainingExercise = trainingExercise
        }
    }
    for j in [291, 289] { // crunches, cross-body crunches
        let trainingExercise = TrainingExercise(context: training.managedObjectContext!)
        trainingExercise.exerciseId = Int16(j)
        trainingExercise.training = training
        
        let numberOfSets = 6
        for setNumber in 1...numberOfSets {
            let trainingSet = TrainingSet(context: training.managedObjectContext!)
            trainingSet.trainingExercise = trainingExercise
            switch setNumber {
            case 1:
                trainingSet.weight = 50 + Double(setNumber) * 2.5
                trainingSet.repetitions = Int16(3 + setNumber)
                trainingSet.isCompleted = true
            case 2:
                trainingSet.weight = 50 + Double(setNumber) * 2.5
                trainingSet.repetitions = Int16(3 + setNumber)
                trainingSet.isCompleted = false
            default:
                trainingSet.isCompleted = false
            }
        }
    }
    for j in [211, 206] { // crunches, cross-body crunches
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
