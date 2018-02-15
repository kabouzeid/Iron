//
//  TrainingExercise.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

class TrainingExercise: NSManagedObject {
    func numberOfCompletedSets() -> Int? {
        let fetchRequest: NSFetchRequest<TrainingSet> = TrainingSet.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "trainingExercise == %@ AND repetitions != 0", self)
        if let count = try? managedObjectContext?.count(for: fetchRequest) {
            return count
        }
        return nil
    }
}
