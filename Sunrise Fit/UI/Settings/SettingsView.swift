//
//  SettingsView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 11.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Combine

struct SettingsView : View {
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        NavigationView {
            Form {
                Picker("Weight Unit", selection: $settingsStore.weightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { weightUnit in
                        Text(weightUnit.title).tag(weightUnit)
                    }
                }
            }
            .navigationBarTitle(Text("Settings"))
        }
    }
}

#if DEBUG
struct SettingsView_Previews : PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(mockSettingsStoreMetric)
    }
}
#endif
