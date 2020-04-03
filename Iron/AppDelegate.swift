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
import Intents
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // TODO: remove in future when every user should've been migrated
        ExerciseStore.migrateCustomExercisesToAppGroupIfNecessary()
        WorkoutDataStorage.migrateToAppGroupIfNecessary()
        SettingsStore.migrateToAppGroupIfNecessary()
        EntitlementStore.migrateToAppGroupIfNecessary()
        ExerciseStore.migrateHiddenExercisesToAppGroupIfNecessary()
        
        StoreObserver.shared.addToPaymentQueue()
        #if DEBUG
        os_log("Skipping license verification in DEBUG build", log: .iap, type: .default)
        #else
        refreshEntitlements()
        #endif
        WatchConnectionManager.shared.activateSession()
        Shortcuts.setDefaultSuggestions()
        Shortcuts.setRelevantShortcuts()
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        SKPaymentQueue.default().remove(StoreObserver.shared)
        
        if SettingsStore.shared.autoBackup {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            os_log("Auto backup is enabled, creating backup", log: .backup, type: .default)
            BackupFileStore.create(data: { () -> Data in
                return try WorkoutDataStorage.shared.persistentContainer.viewContext.performAndWait { context in
                    try IronBackup.createBackupData(managedObjectContext: context, exerciseStore: ExerciseStore.shared)
                }
            }) { result in
                if case let .failure(error) = result {
                    os_log("Auto backup failed: %@", log: .backup, type: .error, error.localizedDescription)
                }
                dispatchGroup.leave()
            }
            
            // the app terminates after this function returns and the backup is written on another queue, therefore we have to wait() here
            dispatchGroup.wait()
        }
    }
    
    // MARK: Intents
    
    func application(_ application: UIApplication, handle intent: INIntent, completionHandler: @escaping (INIntentResponse) -> Void) {
        os_log("Handling intent=%@", log: .intents, type: .info, intent)
        
        if let intent = intent as? INStartWorkoutIntent {
            completionHandler(handle(intent))
        } else if let intent = intent as? INCancelWorkoutIntent {
            completionHandler(handle(intent))
        } else if let intent = intent as? INEndWorkoutIntent {
            completionHandler(handle(intent))
        } else {
            preconditionFailure("Unhandled intent type: \(intent)")
        }
    }
    
    private func handle(_ startWorkoutIntent: INStartWorkoutIntent) -> INStartWorkoutIntentResponse {
        let context = WorkoutDataStorage.shared.persistentContainer.viewContext
        do {
            let count = try context.count(for: Workout.currentWorkoutFetchRequest)
            if count == 0 {
                let workout = Workout.create(context: context)
                do {
                    os_log("Starting workout from intent", log: .workoutData)
                    try workout.start(startWatchCompanionErrorHandler: { error in
                        // the Apple Watch wasn't started, most probably because the app is in the background
                        os_log("Sending user notification to open the app because the watch app wasn't started. Probably because the app is in the background", log: .watch)
                        NotificationManager.shared.requestStartedWorkoutFromBackgroundNotification()
                    })
                    // select the workout tab
                    UITabView.viewController?.selectedIndex = 2
                    return .init(code: .success, userActivity: nil)
                } catch {
                    os_log("Could not start workout: %@", log: .workoutData, type: .error, NSManagedObjectContext.descriptionWithDetailedErrors(error: error as NSError))
                    context.delete(workout)
                    return .init(code: .failure, userActivity: nil)
                }
            } else {
                return .init(code: .failureOngoingWorkout, userActivity: nil)
            }
        } catch {
            return .init(code: .failure, userActivity: nil)
        }
    }
    
    private func handle(_ cancelWorkoutIntent: INCancelWorkoutIntent) -> INCancelWorkoutIntentResponse {
        let context = WorkoutDataStorage.shared.persistentContainer.viewContext
        do {
            guard let workout = try context.fetch(Workout.currentWorkoutFetchRequest).first else {
                return .init(code: .failureNoMatchingWorkout, userActivity: nil)
            }
            os_log("Cancelling workout from intent", log: .workoutData)
            try workout.cancel()
            return .init(code: .success, userActivity: nil)
        } catch {
            os_log("Could not cancel workout: %@", log: .workoutData, type: .error, error.localizedDescription)
            return .init(code: .failure, userActivity: nil)
        }
    }
    
    private func handle(_ endWorkoutIntent: INEndWorkoutIntent) -> INEndWorkoutIntentResponse {
        let context = WorkoutDataStorage.shared.persistentContainer.viewContext
        do {
            guard let workout = try context.fetch(Workout.currentWorkoutFetchRequest).first else {
                return .init(code: .failureNoMatchingWorkout, userActivity: nil)
            }
            os_log("Finishing workout from intent", log: .workoutData)
            try workout.finish()
            return .init(code: .success, userActivity: nil)
        } catch {
            os_log("Could not finish workout: %@", log: .workoutData, type: .error, error.localizedDescription)
            return .init(code: .failure, userActivity: nil)
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
            if let data = try? result.get() {
                ReceiptVerifier.verify(receipt: data) { result in
                    if let response = try? result.get() {
                        DispatchQueue.main.async {
                            EntitlementStore.shared.updateEntitlements(response: response)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Custom
    
    static var instance: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }
}
