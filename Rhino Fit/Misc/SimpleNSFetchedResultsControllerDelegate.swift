//
//  SimpleNSFetchedResultsDelegate.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 10.06.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

class SimpleNSFetchedResultsControllerDelegate : NSObject, NSFetchedResultsControllerDelegate {
    var onDidChange: (() -> ())?
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        onDidChange?()
    }
}
