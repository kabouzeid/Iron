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
    
    var historyFetchRequest: NSFetchRequest<TrainingExercise> {
        TrainingExercise.historyFetchRequest(of: Int(exerciseId), until: training?.start)
    }
    
    // MARK: Derived properties
    
    func exercise(in exercises: [Exercise]) -> Exercise? {
        ExerciseStore.find(in: exercises, with: Int(exerciseId))
    }
    
    var isCompleted: Bool? {
        guard let trainingSets = trainingSets else { return nil }
        return !trainingSets
            .compactMap { $0 as? TrainingSet }
            .contains { !$0.isCompleted }
    }

    var numberOfCompletedSets: Int? {
        trainingSets?
            .compactMap { $0 as? TrainingSet }
            .filter { $0.isCompleted }
            .count
    }

    var numberOfCompletedRepetitions: Int? {
        trainingSets?
            .compactMap { $0 as? TrainingSet }
            .reduce(0, { (count, trainingSet) -> Int in
                count + (trainingSet.isCompleted ? Int(trainingSet.repetitions) : 0)
            })
    }

    var totalCompletedWeight: Double? {
        trainingSets?
            .compactMap { $0 as? TrainingSet }
            .reduce(0, { (weight, trainingSet) -> Double in
                weight + (trainingSet.isCompleted ? trainingSet.weight * Double(trainingSet.repetitions) : 0)
            })
    }

    private var cancellable: AnyCancellable?
}

// MARK: Observable
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
        .receive(on: DispatchQueue.main)
        .sink { _ in self.objectWillChange.send() }
    }
}

// MARK: Encodable
extension TrainingExercise: Encodable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case sets
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exerciseId, forKey: .id)
        try container.encodeIfPresent(exercise(in: appExerciseStore.exercises)?.title, forKey: .name)
        try container.encodeIfPresent(trainingSets?.array.compactMap { $0 as? TrainingSet }, forKey: .sets)
    }
}
