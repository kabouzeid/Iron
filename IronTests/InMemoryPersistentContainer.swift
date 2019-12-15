//
//  InMemoryPersistentContainer.swift
//  IronTests
//
//  Created by Karim Abou Zeid on 15.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
import WorkoutDataKit

func setUpInMemoryNSPersistentContainer() -> NSPersistentContainer {
    let container = NSPersistentContainer(name: "MockWorkoutData", managedObjectModel: WorkoutDataStorage.model)
    let storeDescription = NSPersistentStoreDescription()
    storeDescription.type = NSInMemoryStoreType
    storeDescription.shouldAddStoreAsynchronously = false // Make it simpler in test env
    
    container.persistentStoreDescriptions = [storeDescription]
    container.loadPersistentStores { storeDescription, error in
        if let error = error as NSError? {
            fatalError("could not load persistent store \(storeDescription): \(error), \(error.userInfo)")
        }
        
        precondition(storeDescription.type == NSInMemoryStoreType)
    }
    return container
}
