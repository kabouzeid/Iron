//
//  AppDelegate.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import CoreData
import Combine
import StoreKit
import WorkoutDataKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // TODO: remove in future when every user should've been migrated
        ExerciseStore.migrateCustomExercisesToAppGroupIfNecessary()
        WorkoutDataStorage.migrateToAppGroupIfNecessary()
        SettingsStore.migrateToAppGroupIfNecessary()
        EntitlementStore.migrateToAppGroupIfNecessary()
        ExerciseStore.migrateHiddenExercisesToAppGroupIfNecessary()
        
        SKPaymentQueue.default().add(StoreObserver.shared)
        #if DEBUG
        print("Skipping license verification in DEBUG build")
        #else
        refreshEntitlements()
        #endif
        WatchConnectionManager.shared.activateSession()
        Shortcuts.addDefaultSuggestions()
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        SKPaymentQueue.default().remove(StoreObserver.shared)
        
        if SettingsStore.shared.autoBackup {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            BackupFileStore.create(data: { () -> Data in
                try IronBackup.createBackupData(managedObjectContext: WorkoutDataStorage.shared.persistentContainer.viewContext, exerciseStore: ExerciseStore.shared)
            }) { result in
                if case let .failure(error) = result {
                    print("Auto backup failed: \(error)")
                }
                dispatchGroup.leave()
            }
            
            // the app terminates after this function returns and the backup is written on another queue, therefore we have to wait() here
            dispatchGroup.wait()
        }
    }

    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: - IAP
    
    private func refreshEntitlements() {
        ReceiptFetcher.fetch { result in
            switch result {
            case .success(let data):
                ReceiptVerifier.verify(receipt: data) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let response):
                            EntitlementStore.shared.updateEntitlements(response: response)
                        case .failure(let error):
                            print(error)
                        }
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: - Custom
    
    static var instance: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }
}
