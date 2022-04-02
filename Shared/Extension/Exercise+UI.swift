//
//  Exercise+UI.swift
//  Iron
//
//  Created by Karim Abou Zeid on 02.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import IronData
import SwiftUI

extension Exercise.BodyPart {
    var color: Color {
        switch self {
        case .core:
            return .teal
        case .arms:
            return .purple
        case .shoulders:
            return .orange
        case .back:
            return .blue
        case .legs:
            return .green
        case .chest:
            return .red
        }
    }
    
    var letter: String? {
        self.name.first?.lowercased()
    }
}
