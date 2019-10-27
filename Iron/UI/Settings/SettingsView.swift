//
//  SettingsView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 11.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import StoreKit
import MessageUI

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
    
    private var exportImportSection: some View {
        Section {
            NavigationLink(destination: BackupAndExportView()) {
                Text("Backup & Export Workout Data")
            }
        }
    }
    
    private var ratingSection: some View {
        Section {
            Button(action: {
                guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1479893244?action=write-review") else { return }
                UIApplication.shared.open(writeReviewURL)
            }) {
                HStack {
                    Text("Rate Iron")
                    Spacer()
                    Image(systemName: "star")
                }
            }
            
            Button(action: {
                guard MFMailComposeViewController.canSendMail() else { return }
                
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = MailCloseDelegate.shared
                mail.setToRecipients(["support@ironapp.io"])
                
                // TODO: replace this hack with a proper way to retreive the rootViewController
                guard let rootVC = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else { return }
                rootVC.present(mail, animated: true)
            }) {
                HStack {
                    Text("Send Feedback")
                    Spacer()
                    Image(systemName: "paperplane")
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

// hack because we can't store it in the View
private class MailCloseDelegate: NSObject, MFMailComposeViewControllerDelegate {
    static let shared = MailCloseDelegate()
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
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
