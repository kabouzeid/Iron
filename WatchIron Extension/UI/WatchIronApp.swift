//
//  WatchIronApp.swift
//  WatchIron Extension
//
//  Created by Karim Abou Zeid on 02.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

@main
struct WatchIronApp: App {
    @WKExtensionDelegateAdaptor var extensionDelegate: ExtensionDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
