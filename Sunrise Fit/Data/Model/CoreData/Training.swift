//
//  Training.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

class Training: NSManagedObject {
    static func currentTraining(context: NSManagedObjectContext) -> Training? {
        let request: NSFetchRequest<Training> = Training.fetchRequest()
        request.predicate = NSPredicate(format: "isCurrentTraining == %@", NSNumber(booleanLiteral: true))
        if let res = try? context.fetch(request), let training = res.first {
            assert(res.count == 1, "More than one training marked as current training.")
            return training
        }
        return nil
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
    
    var numberOfCompletedExercises: Int? {
        let fetchRequest: NSFetchRequest<TrainingExercise> = TrainingExercise.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "training == %@ AND NOT (ANY trainingSets.isCompleted == %@)", self, NSNumber(booleanLiteral: false)) // ALL is not supported
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
        for case let trainingExercise as TrainingExercise in trainingExercises ?? [] {
            if let exercise = trainingExercise.exercise {
                // even if there are no sets, add the muscle group at least once
                for _ in 0..<(max(trainingExercise.trainingSets?.count ?? 1, 1)) {
                    muscleGroups.append(exercise.muscleGroup)
                }
            }
        }
        muscleGroups.sortByFrequency()
        return muscleGroups
    }
    
    var duration: TimeInterval {
        (end ?? Date()).timeIntervalSince(start ?? Date())
    }
    
    var numberOfCompletedSets: Int? {
        // TODO: do this with a predicate
        trainingExercises?
            .map { $0 as! TrainingExercise }
            .reduce(0, { (count, trainingExercise) -> Int in
                count + (trainingExercise.numberOfCompletedSets ?? 0)
            })
    }
    
    var totalCompletedWeight: Double? {
        // TODO: do this with a predicate
        trainingExercises?
            .map { $0 as! TrainingExercise }
            .reduce(0, { (weight, trainingExercise) -> Double in
                weight + (trainingExercise.totalCompletedWeight ?? 0)
            })
    }
}
