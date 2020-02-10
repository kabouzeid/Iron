//
//  ExerciseGroup.swift
//  Iron
//
//  Created by Karim Abou Zeid on 10.02.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

public struct ExerciseGroup {
    public let title: String
    public let exercises: [Exercise]
    
    public init(title: String, exercises: [Exercise]) {
        self.title = title
        self.exercises = exercises
    }
}
