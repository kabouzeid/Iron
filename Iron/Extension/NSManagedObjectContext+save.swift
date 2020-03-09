//
//  NSManagedObjectContext+save.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 26.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    func safeSave () {
        if hasChanges {
            do {
                try save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                fatalError("Unresolved error \(error.localizedDescription)")
            }
        }
    }
}
