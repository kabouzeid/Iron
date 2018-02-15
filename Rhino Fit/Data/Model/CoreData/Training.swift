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
            return res[0]
        }
        return nil
    }
}
