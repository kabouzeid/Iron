//
//  UuidMigrationPolicy.swift
//  WorkoutDataKit
//
//  Created by Karim Abou Zeid on 27.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import CoreData

class UuidMigrationPolicy: NSEntityMigrationPolicy {
    @objc
    func createUuid() -> NSUUID {
        UUID() as NSUUID
    }
}
