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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SKPaymentQueue.default().add(StoreObserver.shared)
        refreshEntitlements()
        WatchConnectionManager.shared.activateSession()
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        SKPaymentQueue.default().remove(StoreObserver.shared)
        
        if SettingsStore.shared.autoBackup {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            BackupFileStore.create(data: { () -> Data in
                try IronBackup.createBackupData(managedObjectContext: self.persistentContainer.viewContext, exerciseStore: ExerciseStore.shared)
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

    // MARK: - Core Data stack

    private var workoutDataObserverCancellable: Cancellable?
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "WorkoutData")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        workoutDataObserverCancellable = container.viewContext.observeWorkoutDataChanges()
        
        return container
    }()
    
    // MARK: - Custom
    
    static var instance: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }
}
