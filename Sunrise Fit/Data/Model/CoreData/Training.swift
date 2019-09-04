//
//  Training.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
import Combine

class Training: NSManagedObject {
    static var currentTrainingFetchRequest: NSFetchRequest<Training> {
        let request: NSFetchRequest<Training> = Training.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Training.isCurrentTraining)) == %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Training.start, ascending: false)]
        return request
    }

    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()

    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()
    
    var safeStart: Date {
        start ?? min(end ?? Date(), Date())
    }
    
    var safeEnd: Date {
        end ?? max(start ?? Date(), Date())
    }
    
    var numberOfCompletedExercises: Int? {
        let fetchRequest: NSFetchRequest<TrainingExercise> = TrainingExercise.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(#keyPath(TrainingExercise.training)) == %@ AND NOT (ANY trainingSets.isCompleted == %@)", self, NSNumber(booleanLiteral: false)) // ALL is not supported
        if let count = ((try? managedObjectContext?.count(for: fetchRequest)) as Int??) {
            return count
        }
        return nil
    }
    
    var isCompleted: Bool? {
        guard let completedCount = numberOfCompletedExercises, let totalCount = trainingExercises?.count else { return nil }
        return completedCount == totalCount
    }
    
    var displayTitle: String {
        if let title = title {
            return title
        }
        let muscleGroups = self.muscleGroups
        switch muscleGroups.count {
        case 0:
            return "Training"
        case 1:
            return muscleGroups[0].capitalized
        default:
            return "\(muscleGroups[0].capitalized) & \(muscleGroups[1].capitalized)"
        }
    }
    
    // no duplicate entries, sorted descending by frequency
    var muscleGroups: [String] {
        var muscleGroups = [String]()
        
        let trainingExercises = self.trainingExercises?.array as? [TrainingExercise] ?? []
        for trainingExercise in trainingExercises {
            if let exercise = trainingExercise.exercise {
                // even if there are no sets, add the muscle group at least once
                let factor = max(trainingExercise.trainingSets?.count ?? 1, 1)
                muscleGroups.append(contentsOf: Array(repeating: exercise.muscleGroup, count: factor))
            }
        }
        return muscleGroups.sortedByFrequency().uniqed().reversed()
    }
    
    var duration: TimeInterval {
        safeEnd.timeIntervalSince(safeStart)
    }
    
    var numberOfCompletedSets: Int? {
        trainingExercises?
            .map { $0 as! TrainingExercise }
            .reduce(0, { (count, trainingExercise) -> Int in
                count + (trainingExercise.numberOfCompletedSets ?? 0)
            })
    }
    
    var totalCompletedWeight: Double? {
        trainingExercises?
            .map { $0 as! TrainingExercise }
            .reduce(0, { (weight, trainingExercise) -> Double in
                weight + (trainingExercise.totalCompletedWeight ?? 0)
            })
    }
    
    func deleteAndRemoveUncompletedSets() {
        trainingExercises?
            .compactMap { $0 as? TrainingExercise }
            .compactMap { $0.trainingSets?.array as? [TrainingSet] }
            .flatMap { $0 }
            .filter { !$0.isCompleted }
            .forEach { trainingSet in
                managedObjectContext?.delete(trainingSet)
                trainingSet.trainingExercise?.removeFromTrainingSets(trainingSet)
        }
    }
    
    private var cancellable: AnyCancellable?
}

extension Training {
    override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateConsistency()
    }
    
    override func validateForInsert() throws {
        try super.validateForInsert()
        try validateConsistency()
    }
    
    func validateConsistency() throws {
        if start == nil && end != nil {
            throw error(code: 1123, message: "start is nil but end is set")
        }
        
        if let start = start, let end = end, start > end {
            throw error(code: 1124, message: "start is greater than end")
        }
        
        if isCurrentTraining, let count = try? managedObjectContext?.count(for: Self.currentTrainingFetchRequest), count > 1 {
            throw error(code: 1125, message: "more than one current training")
        }
    }
    
    private func error(code: Int, message: String) -> NSError {
        NSError(domain: "TRAINING_ERROR_DOMAIN", code: code, userInfo: [NSLocalizedFailureReasonErrorKey: message, NSValidationObjectErrorKey: self])
    }
}

extension Training {
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
                    if let trainingExercise = managedObject as? TrainingExercise {
                        return trainingExercise.training?.objectID == self.objectID
                    }
                    if let trainingSet = managedObject as? TrainingSet {
                        return trainingSet.trainingExercise?.training?.objectID == self.objectID
                    }
                    return managedObject.objectID == self.objectID
                }
        }
        .receive(on: DispatchQueue.main)
        .sink { _ in self.objectWillChange.send() }
    }
}
