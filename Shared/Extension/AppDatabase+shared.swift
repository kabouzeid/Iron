//
//  AppDatabase+shared.swift
//  Iron
//
//  Created by Karim Abou Zeid on 24.03.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import IronData

extension AppDatabase {
    static let shared = makeShared(folderURL: FileManager.default.appGroupContainerApplicationSupportURL.appendingPathComponent("appdb"))
}
