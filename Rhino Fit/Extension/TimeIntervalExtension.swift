//
//  TimeIntervalExtension.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 24.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension TimeInterval {
    func stringFormatted() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self / 60) - Int(hours * 60)
        let seconds = Int(self) - (Int(self / 60) * 60)
        
        return String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    }
    
    func stringFormattedWithLetters() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self / 60) - Int(hours * 60)
        let seconds = Int(self) - (Int(self / 60) * 60)
        
        if hours == 0 {
            if minutes == 0 {
                return String(format: "%ds", seconds)
            }
            return String(format: "%dm %ds", minutes, seconds)
        }
        return String(format: "%dh %dm", hours, minutes + (seconds >= 30 ? 1 : 0)) // round seconds
    }
}
