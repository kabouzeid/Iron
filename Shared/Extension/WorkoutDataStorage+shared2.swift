//
//  WorkoutDataStorage+shared.swift
//  Iron
//
//  Created by Karim Abou Zeid on 05.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit
import CoreData
import Combine

extension WorkoutDataStorage {
    static let shared: WorkoutDataStorage = WorkoutDataStorage(storeDescription: .init(url: groupStoreURL))
    
    static var cancellable: Cancellable?
}
