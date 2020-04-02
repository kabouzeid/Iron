//
//  WatchSettingsView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 12.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct WatchSettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    private var footer: String {
        if settingsStore.watchCompanion {
            return "When you start a workout, Iron's Apple Watch companion app will automatically launch to measure your heart rate and approximate your calorie consumption during the workout."
        } else {
            return "When you start a workout, Iron's Apple Watch companion app will not automatically launch to measure your heart rate and approximate your calorie consumption during the workout."
        }
    }
    
    var body: some View {
        Form {
            Section(footer: Text(footer)) {
                Toggle(isOn: $settingsStore.watchCompanion) {
                    Text("Apple Watch Companion")
                }
            }
        }
        .navigationBarTitle("Apple Watch", displayMode: .inline)
    }
}

import WatchConnectivity
extension WatchSettingsView {
    static var isSupported: Bool {
        WCSession.isSupported()
    }
}

struct WatchSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        WatchSettingsView().environmentObject(SettingsStore.shared)
    }
}
