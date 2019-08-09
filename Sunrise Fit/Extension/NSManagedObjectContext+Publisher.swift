//
//  TrainingsDataChangePublisher.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 08.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Combine
import CoreData

extension NSManagedObjectContext {
    var publisher: AnyPublisher<Set<NSManagedObject>, Never> {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: self)
            .compactMap { notification in
                return notification.userInfo
            }
            .map { (userInfo) -> Set<NSManagedObject> in
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
                return changed
            }
            .eraseToAnyPublisher()
    }
}
