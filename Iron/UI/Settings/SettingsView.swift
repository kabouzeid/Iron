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
    
    private var mainSection: some View {
        Section {
            NavigationLink(destination: GeneralSettingsView()) {
                Text("General")
            }
            
            NavigationLink(destination: HealthSettingsView()) {
                Text("Apple Health")
            }
            
            NavigationLink(destination: WatchSettingsView()) {
                Text("Apple Watch")
            }
            
            NavigationLink(destination: BackupAndExportView()) {
                Text("Backup & Export")
            }
        }
    }
    
    @State private var showSupportMailAlert = false // if mail client is not configured
    private var ratingAndSupportSection: some View {
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
                guard MFMailComposeViewController.canSendMail() else {
                    self.showSupportMailAlert = true // fallback
                    return
                }
                
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
            .alert(isPresented: $showSupportMailAlert) {
                Alert(title: Text("Support E-Mail"), message: Text("support@ironapp.io"))
            }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                ironProSection
                
                mainSection
                
                ratingAndSupportSection
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
