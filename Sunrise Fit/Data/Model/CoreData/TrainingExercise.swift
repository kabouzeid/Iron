//
//  TrainingExercise.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

class TrainingExercise: NSManagedObject {
    var numberOfCompletedSets: Int? {
        get {
            let fetchRequest: NSFetchRequest<TrainingSet> = TrainingSet.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "trainingExercise == %@ AND isCompleted == %@", self, NSNumber(booleanLiteral: true))
            if let count = try? managedObjectContext?.count(for: fetchRequest) {
                return count
            }
            return nil
        }
    }
    
    var isCompleted: Bool? {
        get {
            if let completedCount = numberOfCompletedSets {
                return completedCount == trainingSets!.count
            }
            return nil
        }
    }
    
    var exercise: Exercise? {
        get {
            return EverkineticDataProvider.findExercise(id: Int(exerciseId))
        }
    }
    
    var history: [TrainingExercise]? {
        get {
            if let context = managedObjectContext {
                return TrainingExercise.fetchHistory(of: Int(exerciseId), until: (training!.start ?? Date()), context: context)
            }
            return nil
        }
    }

    static func fetchHistory(of exerciseId: Int, until: Date, context: NSManagedObjectContext) -> [TrainingExercise]? {
        let request: NSFetchRequest<TrainingExercise> = TrainingExercise.fetchRequest()
        request.predicate = NSPredicate(format: "training.isCurrentTraining != %@ AND exerciseId == %@ AND training.start < %@", NSNumber(booleanLiteral: true), NSNumber(value: exerciseId), until as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "training.start", ascending: false)]
        return try? context.fetch(request)
    }

    var numberOfCompletedRepetitions: Int {
        // TODO: do this with a predicate
        return trainingSets!.reduce(0, { (count, trainingSet) -> Int in
            let trainingSet = trainingSet as! TrainingSet
            return count + (trainingSet.isCompleted ? Int(trainingSet.repetitions) : 0)
        })
    }

    var totalCompletedWeight: Float {
        // TODO: do this with a predicate
        return trainingSets!.reduce(0, { (weight, trainingSet) -> Float in
            let trainingSet = trainingSet as! TrainingSet
            return weight + (trainingSet.isCompleted ? trainingSet.weight * Float(trainingSet.repetitions) : 0)
        })
    }
}
