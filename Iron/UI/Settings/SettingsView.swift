//
//  SettingsView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 11.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import StoreKit

struct SettingsView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    private var ironProSection: some View {
        Section {
            NavigationLink(destination: PurchaseView()) {
                Text("Iron Pro")
            }
        }
    }
    
    private var weightPickerSection: some View {
        Section {
            Picker("Weight Unit", selection: $settingsStore.weightUnit) {
                ForEach(WeightUnit.allCases, id: \.self) { weightUnit in
                    Text(weightUnit.title).tag(weightUnit)
                }
            }
        }
    }
    
    private var oneRmSection: some View {
        Section(footer: Text("Maximum number of repetitions for a set to be considered in the one rep max (1RM) calculation. Keep in mind that higher values are less accurate.")) {
            Picker("Max Repetitions for 1RM", selection: $settingsStore.maxRepetitionsOneRepMax) {
                ForEach(maxRepetitionsOneRepMaxValues, id: \.self) { i in
                    Text("\(i)").tag(i)
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
            Picker("Default Rest Time (Barbell)", selection: $settingsStore.defaultRestTimeBarbellBased) {
                ForEach(restTimerCustomTimes, id: \.self) { time in
                    Text(restTimerDurationFormatter.string(from: time) ?? "").tag(time)
                }
            }
        }
    }
    
    private var exportImportSection: some View {
        Section {
            NavigationLink(destination: ExportImportSettingsView()) {
                Text("Export / Import Workout Data")
            }
        }
    }
    
    private var ratingSection: some View {
        Section(footer: Text("If you like Iron, consider leaving a review, it helps a lot!")) {
            Button(action: {
                SKStoreReviewController.requestReview()
                
                // TODO: replace with the below once app is in app store
                // Note: Replace the XXXXXXXXXX below with the App Store ID for your app
                //       You can find the App Store ID in your app's product URL
//                guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/idXXXXXXXXXX?action=write-review") else { return }
//                UIApplication.shared.open(writeReviewURL)
            }) {
                HStack {
                    Text("Rate Iron")
                    Spacer()
                    Image(systemName: "heart.fill").foregroundColor(.red)
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                ironProSection
                
                weightPickerSection
                
                oneRmSection
                
                restTimerSection
                
                exportImportSection
                
                ratingSection
            }
            .navigationBarTitle(Text("Settings"))
        }
        .navigationViewStyle(StackNavigationViewStyle()) // TODO: remove, currently needed for iPad as of 13.1.1
    }
}

#if DEBUG
struct SettingsView_Previews : PreviewProvider {
    static var previews: some View {
        SettingsView()
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
