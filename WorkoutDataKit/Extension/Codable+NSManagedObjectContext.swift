//
//  Codable+NSManagedObjectContext.swift
//  Iron
//
//  Created by Karim Abou Zeid on 26.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

public extension CodingUserInfoKey {
    static let managedObjectContextKey = CodingUserInfoKey(rawValue: "managedObjectContextKey")
    static let exercisesKey = CodingUserInfoKey(rawValue: "exercisesKey")
    
    enum DecodingError: Error {
        case managedObjectContextMissing
    }
}
