//
//  ExerciseGroup+Identifieable.swift
//  Iron
//
//  Created by Karim Abou Zeid on 10.02.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit

extension ExerciseGroup: Identifiable {
    public var id: String { title }
}
