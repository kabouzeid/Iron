//
//  UserDefaults+AppGroup.swift
//  Iron
//
//  Created by Karim Abou Zeid on 07.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension UserDefaults {
    static let appGroup: UserDefaults = {
        guard let userDefaults = UserDefaults(suiteName: FileManager.appGroupIdentifier) else {
            fatalError("could not create user defaults for group suite \(FileManager.appGroupIdentifier)")
        }
        return userDefaults
    }()
}
