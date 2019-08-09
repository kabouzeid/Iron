//
//  TrainingExercise.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
import Combine

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
    
    var historyFetchRequest: NSFetchRequest<TrainingExercise> {
        TrainingExercise.historyFetchRequest(of: Int(exerciseId), until: training?.start)
    }

    static func historyFetchRequest(of exerciseId: Int, until: Date?) -> NSFetchRequest<TrainingExercise> {
        let request: NSFetchRequest<TrainingExercise> = TrainingExercise.fetchRequest()
        let basePredicate = NSPredicate(format: "\(#keyPath(TrainingExercise.training.isCurrentTraining)) != %@ AND \(#keyPath(TrainingExercise.exerciseId)) == %@", NSNumber(booleanLiteral: true), NSNumber(value: exerciseId))
        if let until = until {
            let untilPredicate = NSPredicate(format: "\(#keyPath(TrainingExercise.training.start)) < %@", until as NSDate)
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, untilPredicate])
        } else {
            request.predicate = basePredicate
        }
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrainingExercise.training?.start, ascending: false)]
        return request
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

    private var cancellable: AnyCancellable?
}

extension TrainingExercise {
    override func awakeFromFetch() {
        super.awakeFromFetch() // important
        initChangeObserver()
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert() // important
        initChangeObserver()
    }
    
    private func initChangeObserver() {
        cancellable = managedObjectContext?.publisher
            .filter { changed in
                changed.contains { managedObject in
                    if let training = managedObject as? Training {
                        return training.objectID == self.training?.objectID
                    }
                    if let trainingSet = managedObject as? TrainingSet {
                        return trainingSet.trainingExercise?.objectID == self.objectID
                    }
                    return managedObject.objectID == self.objectID
                }
        }
        .sink { _ in self.objectWillChange.send() }
    }
}
