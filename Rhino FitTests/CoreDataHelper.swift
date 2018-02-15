//
//  CoreDataHelper.swift
//  Rhino FitTests
//
//  Created by Karim Abou Zeid on 15.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

func setUpInMemoryNSPersistentContainer() -> NSPersistentContainer {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
    
        let container = NSPersistentContainer(name: "Rhino_Fit", managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false // Make it simpler in test env
        
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (description, error) in
            // Check if the data store is in memory
            precondition( description.type == NSInMemoryStoreType )
            
            // Check if creating container wrong
            if let error = error {
                fatalError("Create an in-mem coordinator failed \(error)")
            }
        }
        return container
}
