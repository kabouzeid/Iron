//
//  OSLog+trace.swift
//  Iron
//
//  Created by Karim Abou Zeid on 28.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import os.log

extension OSLog {
    func trace(type: OSLogType = .debug, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        guard isEnabled(type: type) else { return }
        let file = URL(fileURLWithPath: String(describing: file)).lastPathComponent
        os_log("%{public}@ %{public}@:%ld", log: self, type: type, String(describing: function), file, line)
    }
}
