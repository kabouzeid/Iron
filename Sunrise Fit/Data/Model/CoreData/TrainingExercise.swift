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
        let fetchRequest: NSFetchRequest<TrainingSet> = TrainingSet.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "trainingExercise == %@ AND isCompleted == %@", self, NSNumber(booleanLiteral: true))
        if let count = ((try? managedObjectContext?.count(for: fetchRequest)) as Int??) {
            return count
        }
        return nil
    }
    
    var isCompleted: Bool? {
        guard let completedCount = numberOfCompletedSets, let totalCount = trainingSets?.count else { return nil }
        return completedCount == totalCount
    }
    
    var exercise: Exercise? {
        EverkineticDataProvider.findExercise(id: Int(exerciseId))
    }
    
    var history: [TrainingExercise]? {
        guard let context = managedObjectContext else { return nil }
        return TrainingExercise.fetchHistory(of: Int(exerciseId), until: (training?.start ?? Date()), context: context)
    }

    static func fetchHistory(of exerciseId: Int, until: Date, context: NSManagedObjectContext) -> [TrainingExercise]? {
        let request: NSFetchRequest<TrainingExercise> = TrainingExercise.fetchRequest()
        request.predicate = NSPredicate(format: "training.isCurrentTraining != %@ AND exerciseId == %@ AND training.start < %@", NSNumber(booleanLiteral: true), NSNumber(value: exerciseId), until as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "training.start", ascending: false)]
        return try? context.fetch(request)
    }

    var numberOfCompletedRepetitions: Int? {
        // TODO: do this with a predicate
        trainingSets?
            .map { $0 as! TrainingSet }
            .reduce(0, { (count, trainingSet) -> Int in
                count + (trainingSet.isCompleted ? Int(trainingSet.repetitions) : 0)
            })
    }

    var totalCompletedWeight: Double? {
        // TODO: do this with a predicate
        trainingSets?
            .map { $0 as! TrainingSet }
            .reduce(0, { (weight, trainingSet) -> Double in
                weight + (trainingSet.isCompleted ? trainingSet.weight * Double(trainingSet.repetitions) : 0)
            })
    }
}
