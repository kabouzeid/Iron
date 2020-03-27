//
//  NSManagedObjectContext+performAndWait.swift
//  Iron
//
//  Created by Karim Abou Zeid on 27.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    func performAndWait<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) throws -> T {
        var result: Result<T, Error>?
        performAndWait {
            result = Result { try block(self) }
        }
        return try result!.get()
    }
    
    func performAndWait<T>(_ block: @escaping (NSManagedObjectContext) -> T) -> T {
        var result: T?
        performAndWait {
            result = block(self)
        }
        return result!
    }
    
    func performAndWait<T>(_ block: @escaping () throws -> T) throws -> T {
        var result: Result<T, Error>?
        performAndWait {
            result = Result { try block() }
        }
        return try result!.get()
    }
    
    func performAndWait<T>(_ block: @escaping () -> T) -> T {
        var result: T?
        performAndWait {
            result = block()
        }
        return result!
    }
}
