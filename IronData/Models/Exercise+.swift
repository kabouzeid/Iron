//
//  Exercise+.swift
//  IronData
//
//  Created by Karim Abou Zeid on 02.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension Exercise {
    public static var imagesBundle: Bundle { _Bundle.bundle }
    
    private class _Bundle {
        static var bundle: Bundle {
            Bundle(for: Self.self)
        }
    }
}

extension Exercise.BodyPart {
    public var name: String {
        switch self {
        case .core:
            return "Core"
        case .arms:
            return "Arms"
        case .shoulders:
            return "Shoulders"
        case .back:
            return "Back"
        case .legs:
            return "Legs"
        case .chest:
            return "Chest"
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

extension Exercise.MovementType {
    public var name: String {
        switch self {
        case .compound:
            return "Compound"
        case .isolation:
            return "Isolation"
        }
    }
}
