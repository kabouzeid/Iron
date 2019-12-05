//
//  WorkoutDataStorage+GroupStoreURL.swift
//  Iron
//
//  Created by Karim Abou Zeid on 06.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit

extension WorkoutDataStorage {
    static var groupStoreURL: URL {
        let directory = FileManager.default.appGroupContainerApplicationSupportURL
        
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            fatalError("could not create \(directory)")
        }
            
        return directory.appendingPathComponent("WorkoutData").appendingPathExtension("sqlite")
    }
}
