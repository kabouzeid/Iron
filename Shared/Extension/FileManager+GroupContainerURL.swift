//
//  FileManager+GroupContainerURL.swift
//  Iron
//
//  Created by Karim Abou Zeid on 06.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension FileManager {
    static var appGroupIdentifier = "group.com.kabouzeid.Iron"
    
    var appGroupContainerURL: URL {
        guard let containerURL = containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier) else {
            fatalError("shared container could not be created")
        }
        return containerURL
    }
    
    var appGroupContainerApplicationSupportURL: URL {
        appGroupContainerURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
    }
}
