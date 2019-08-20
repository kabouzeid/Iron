//
//  ObservableFetchRequest.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 02.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Combine
import CoreData

// TODO: not working as of beta6, List crashes when using fetch() in onAppear()
class ObservableFetchRequest<Result>: NSObject, ObservableObject, NSFetchedResultsControllerDelegate where Result: NSFetchRequestResult {
    var objectWillChange = ObservableObjectPublisher()
    
    @Published var fetchedResults = [Result]() {
        // TODO: remove didSet in future, as of beta6 @Published doesn't seem to work
        willSet {
            self.objectWillChange.send()
        }
    }
    
    private(set) var fetchRequest: NSFetchRequest<Result>?
    private var controller: NSFetchedResultsController<Result>?

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let controller = controller as? NSFetchedResultsController<Result> {
            fetchedResults = controller.fetchedObjects ?? []
        }
    }
    
    func fetch(fetchRequest: NSFetchRequest<Result>, managedObjectContext: NSManagedObjectContext) {
        guard self.fetchRequest != fetchRequest else { return }
        
        self.fetchRequest = fetchRequest
        controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        controller?.delegate = self
        do {
            try controller?.performFetch()
            fetchedResults = controller?.fetchedObjects ?? []
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
}
