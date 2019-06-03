//
//  Training.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

class Training: NSManagedObject {
    static func fetchCurrentTraining(context: NSManagedObjectContext) -> Training? {
        let request: NSFetchRequest<Training> = Training.fetchRequest()
        request.predicate = NSPredicate(format: "isCurrentTraining == %@", NSNumber(booleanLiteral: true))
        if let res = try? context.fetch(request), !res.isEmpty {
            assert(res.count == 1, "More than one training marked as current training.")
            return res.first!
        }
        return nil
    }
    
    static func deleteCurrentTraining(context: NSManagedObjectContext) {
        if let currentTraining = fetchCurrentTraining(context: context) {
            context.delete(currentTraining)
        }
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
        get {
            let fetchRequest: NSFetchRequest<TrainingExercise> = TrainingExercise.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "training == %@ AND NOT (ANY trainingSets.isCompleted == %@)", self, NSNumber(booleanLiteral: false)) // ALL is not supported
            if let count = ((try? managedObjectContext?.count(for: fetchRequest)) as Int??) {
                return count
            }
            return nil
        }
    }
    
    var isCompleted: Bool? {
        get {
            if let completedCount = numberOfCompletedExercises {
                return completedCount == trainingExercises!.count
            }
            return nil
        }
    }
    
    var displayTitle: String {
        get {
            if title == nil {
                var muscleGroups = [String]()
                for case let trainingExercise as TrainingExercise in trainingExercises! {
                    if let exercise = trainingExercise.exercise {
                        muscleGroups.append(exercise.muscleGroup)
                    }
                }
                muscleGroups.sortByFrequency()
                
                switch muscleGroups.count {
                case 0:
                    return "Training"
                case 1:
                    return muscleGroups[0].capitalized
                default:
                    return "\(muscleGroups[0].capitalized) & \(muscleGroups[1].capitalized)"
                }
            }
            return title! // safe
        }
    }
    
    var duration: TimeInterval {
        return (end ?? Date()).timeIntervalSince(start ?? Date())
    }
    
    var numberOfCompletedSets: Int {
        // TODO: do this with a predicate
        return trainingExercises!.reduce(0, { (count, trainingExercise) -> Int in
            let trainingExercise = trainingExercise as! TrainingExercise
            return count + (trainingExercise.numberOfCompletedSets ?? 0)
        })
    }
    
    var totalCompletedWeight: Double {
        // TODO: do this with a predicate
        return trainingExercises!.reduce(0, { (weight, trainingExercise) -> Double in
            let trainingExercise = trainingExercise as! TrainingExercise
            return weight + trainingExercise.totalCompletedWeight
        })
    }
}
