//
//  NSManagedObjectContext+Publisher.swift
//  Iron
//
//  Created by Karim Abou Zeid on 08.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Combine
import CoreData

extension NSManagedObjectContext {
    private static let publisher: AnyPublisher<(Set<NSManagedObject>, NSManagedObjectContext), Never> = {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)
            .drop(while: { _ in IronBackup.restoringBackupData }) // ignore the spam while we are restoring
            .compactMap { notification -> (Set<NSManagedObject>, NSManagedObjectContext)? in
                guard let userInfo = notification.userInfo else { return nil }
                guard let managedObjectContext = notification.object as? NSManagedObjectContext else { return nil }
                
                var changed = Set<NSManagedObject>()

                if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> {
                    changed.formUnion(inserts)
                }

                if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                    changed.formUnion(updates)
                }

                if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> {
                    changed.formUnion(deletes)
                }
                return (changed, managedObjectContext)
            }
            .share()
            .eraseToAnyPublisher()
    }()
    
    var publisher: AnyPublisher<Set<NSManagedObject>, Never> {
        Self.publisher
            .filter { $0.1 === self } // only publish changes belonging to this context
            .map { $0.0 }
            .eraseToAnyPublisher()
    }
}
