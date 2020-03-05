//
//  OSLog+Logs.swift
//  WorkoutDataKit
//
//  Created by Karim Abou Zeid on 05.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import os.log

extension OSLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "-"
    
    static let coreDataMonitor = OSLog(subsystem: subsystem, category: "Core Data Monitor")
}
