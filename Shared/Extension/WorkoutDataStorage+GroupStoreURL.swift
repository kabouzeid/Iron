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
        FileManager.default.appGroupContainerApplicationSupportURL
            .appendingPathComponent("WorkoutData").appendingPathExtension("sqlite")
    }
}
