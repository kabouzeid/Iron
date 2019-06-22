//
//  TrainingsDataStore.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
import Combine
import SwiftUI

class TrainingsDataStore : BindableObject {
    var didChange = PassthroughSubject<Void, Never>()
    
    let context: NSManagedObjectContext
    private var cancellable: Cancellable?
    
    init(context: NSManagedObjectContext) {
        print("init trainings data store")
        self.context = context
        cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .sink { [weak self] (notification) in
                self?.didChange.send()
                
                print("data store changed")
//                print("notification: \(notification)")
                guard let userInfo = notification.userInfo else { return }
                
                if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
//                    print("insertions: \(inserts)")
                }
                
                if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
//                    print("updates \(updates)")
                }
                
                if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
//                    print("deletes \(deletes)")
                }
        }
    }
    
    // TODO: need to cancel on deinit?
}

var trainingsDataStore = {
   TrainingsDataStore(context: AppDelegate.instance.persistentContainer.viewContext)
}()
