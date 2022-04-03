//
//  Exercise+.swift
//  IronData
//
//  Created by Karim Abou Zeid on 02.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension Exercise.BodyPart {
    public var name: String {
        switch self {
        case .core:
            return "core"
        case .arms:
            return "arm"
        case .shoulders:
            return "shoulders"
        case .back:
            return "back"
        case .legs:
            return "legs"
        case .chest:
            return "chest"
        }
    }
}

extension Exercise.Category {
    public var name: String {
        switch self {
        case .barbell:
            return "Barbell"
        case .bodyweight:
            return "Bodyweight"
        case .cardio:
            return "Cardio"
        case .dumbbell:
            return "Dumbbell"
        case .duration:
            return "Duration"
        case .machine:
            return "Machine"
        }
    }
}
