//
//  TrainingExercise.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

class TrainingExercise: NSManagedObject {
    var completedSets: Int? {
        get {
            let fetchRequest: NSFetchRequest<TrainingSet> = TrainingSet.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "trainingExercise == %@ AND isCompleted == %@", self, NSNumber(booleanLiteral: true))
            if let count = try? managedObjectContext?.count(for: fetchRequest) {
                return count
            }
            return nil
        }
    }
    
    var exercise: Exercise? {
        get {
            return EverkineticDataProvider.findExercise(id: Int(exerciseId))
        }
    }
}
