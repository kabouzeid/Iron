//
//  OSLog+Logs.swift
//  Iron
//
//  Created by Karim Abou Zeid on 05.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import os.log

extension OSLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "-"
    
    static let main = OSLog(subsystem: subsystem, category: "main")
    static let iap = OSLog(subsystem: subsystem, category: "IAP")
    static let migration = OSLog(subsystem: subsystem, category: "migration")
    static let backup = OSLog(subsystem: subsystem, category: "backup")
    static let ubiquityContainer = OSLog(subsystem: subsystem, category: "ubiquityContainer")
    static let health = OSLog(subsystem: subsystem, category: "health")
    static let watch = OSLog(subsystem: subsystem, category: "watch")
}

extension OSLog {
    func trace(type: OSLogType = .debug, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        guard isEnabled(type: type) else { return }
        let file = URL(fileURLWithPath: String(describing: file)).lastPathComponent
        os_log("%{public}@ %{public}@:%ld", log: self, type: type, String(describing: function), file, line)
    }
}
