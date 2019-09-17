//
//  SettingsView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 11.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

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
                
                Section {
                    Picker("Default Rest Time", selection: $settingsStore.defaultRestTime) {
                        ForEach(restTimerCustomTimes, id: \.self) { time in
                            Text(restTimerDurationFormatter.string(from: time) ?? "").tag(time)
                        }
                    }
                    Picker("Default Rest Time (Barbell)", selection: $settingsStore.defaultRestTimeBarbellBased) {
                        ForEach(restTimerCustomTimes, id: \.self) { time in
                            Text(restTimerDurationFormatter.string(from: time) ?? "").tag(time)
                        }
                    }
                }
                
                Section(footer: Text("Maximum number of repetitions for a set to be considered in the one rep max (1RM) calculation. Keep in mind that higher values are less accurate.")) {
                    Picker("Max Repetitions for 1RM", selection: $settingsStore.maxRepetitionsOneRepMax) {
                        ForEach(maxRepetitionsOneRepMaxValues, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: ExportImportSettingsView()) {
                        Text("Export / Import Workout Data")
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
