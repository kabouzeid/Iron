//
//  WorkoutMigrationPolicyV2_V3.swift
//  Iron
//
//  Created by Karim Abou Zeid on 08.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import CoreData

class WorkoutMigrationPolicyV2_V3: NSEntityMigrationPolicy {
    @objc
    func uuid() -> NSUUID {
        UUID() as NSUUID
    }
}
