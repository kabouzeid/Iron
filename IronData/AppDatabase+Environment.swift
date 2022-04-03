//
//  AppDatabase+Environment.swift
//  IronData
//
//  Created by Karim Abou Zeid on 03.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import GRDB

private struct AppDatabaseKey: EnvironmentKey {
    static var defaultValue: AppDatabase { .empty() }
}

extension EnvironmentValues {
    public var database: AppDatabase {
        get { self[AppDatabaseKey.self] }
        set { self[AppDatabaseKey.self] = newValue }
    }
}
