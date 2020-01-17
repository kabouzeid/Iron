//
//  GeneralSettingsView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 31.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    private var weightPickerSection: some View {
        Section {
            Picker("Weight Unit", selection: $settingsStore.weightUnit) {
                ForEach(WeightUnit.allCases, id: \.self) { weightUnit in
                    Text(weightUnit.title).tag(weightUnit)
                }
            }
        }
    }
    
    private var restTimerSection: some View {
        Section {
            Picker("Default Rest Time", selection: $settingsStore.defaultRestTime) {
                ForEach(restTimerCustomTimes, id: \.self) { time in
                    Text(restTimerDurationFormatter.string(from: time) ?? "").tag(time)
                }
            }
            
            Picker("Default Rest Time (Dumbbell)", selection: $settingsStore.defaultRestTimeDumbbellBased) {
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
    }
    
    private var oneRmSection: some View {
        Section(footer: Text("Maximum number of repetitions that a set can have for it to be considered in the one rep max (1RM) calculation. Keep in mind that higher values are less accurate.")) {
            Picker("Max Repetitions for 1RM", selection: $settingsStore.maxRepetitionsOneRepMax) {
                ForEach(maxRepetitionsOneRepMaxValues, id: \.self) { i in
                    Text("\(i)").tag(i)
                }
            }
        }
    }
    
    var body: some View {
        Form {
            weightPickerSection
            restTimerSection
            oneRmSection
        }
        .navigationBarTitle("General", displayMode: .inline)
    }
}

#if DEBUG
struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView()
    }
}
#endif
