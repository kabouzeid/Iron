//
//  SignpostLog.swift
//  Iron
//
//  Created by Karim Abou Zeid on 30.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import os.log

enum SignpostLog {
    private static let subsystem = "com.kabouzeid.Iron"
    
    static let workoutDataPublisher = OSLog(subsystem: subsystem, category: "workout data publisher")
}
