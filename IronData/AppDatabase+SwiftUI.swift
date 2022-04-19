//
//  AppDatabase+SwiftUI.swift
//  IronData
//
//  Created by Karim Abou Zeid on 18.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import GRDBQuery
import SwiftUI

// MARK: - Give SwiftUI access to the database
//
// Define a new environment key that grants access to an AppDatabase.
//
// The technique is documented at
// <https://developer.apple.com/documentation/swiftui/environmentkey>.

private struct AppDatabaseKey: EnvironmentKey {
    static var defaultValue: AppDatabase { .empty() }
}

extension EnvironmentValues {
    public var appDatabase: AppDatabase {
        get { self[AppDatabaseKey.self] }
        set { self[AppDatabaseKey.self] = newValue }
    }
}

extension Query where Request.DatabaseContext == AppDatabase {
    /// Convenience initializer for requests that feed from `AppDatabase`.
    public init(_ request: Request) {
        self.init(request, in: \.appDatabase)
    }
}
