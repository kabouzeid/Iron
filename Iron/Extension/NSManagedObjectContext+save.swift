//
//  NSManagedObjectContext+save.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 26.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import CoreData
import os.log

extension NSManagedObjectContext {
    func saveOrCrash () {
        if hasChanges {
            do {
                try save()
            } catch {
                let description = Self.descriptionWithDetailedErrors(error: error as NSError)
                os_log("Could not save context: %@", log: .workoutData, type: .error, description)
                fatalError("Could not save context: \(description)")
            }
        }
    }
}

extension NSManagedObjectContext {
    static func descriptionWithDetailedErrors(error: NSError) -> String {
        var append: String?
        if let detailedErrors = (error as NSError).userInfo[NSDetailedErrorsKey] as? [NSError] {
            let detailedString = detailedErrors
                .map { descriptionWithEntityName(error: $0) }
                .joined(separator: "\n")
            append = " Detailed Errors:\n\(detailedString)\n"
        }
        return descriptionWithEntityName(error: error) + (append ?? "")
    }
    
    private static func descriptionWithEntityName(error: NSError) -> String {
        let entityName = (error.userInfo[NSValidationObjectErrorKey] as? NSManagedObject)?.entity.name
        return "\(entityName.map { "\($0):" } ?? "") \(error.localizedDescription)"
    }
}
