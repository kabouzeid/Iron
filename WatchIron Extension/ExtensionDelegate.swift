//
//  ExtensionDelegate.swift
//  WatchIron Extension
//
//  Created by Karim Abou Zeid on 02.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import WatchKit
import HealthKit
import Foundation
import Combine

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func applicationDidFinishLaunching() {
        print(#function)
        // Perform any final initialization of your application.
        reloadRootPageControllers(workoutSessionManagerStore: WorkoutSessionManagerStore.shared)
        cancellable = WorkoutSessionManagerStore.shared.objectWillChange.sink {
            self.reloadRootPageControllers(workoutSessionManagerStore: WorkoutSessionManagerStore.shared)
        }
        handleActiveWorkoutRecovery() // somehow this isn't automatically called by the system?!
        PhoneConnectionManager.shared.activateSession()
    }
    
    private var cancellable: AnyCancellable?
    private func reloadRootPageControllers(workoutSessionManagerStore: WorkoutSessionManagerStore) {
        if workoutSessionManagerStore.workoutSessionManager == nil {
            WKInterfaceController.reloadRootPageControllers(withNames: ["workout"], contexts: nil, orientation: .horizontal, pageIndex: 0)
        } else {
            WKInterfaceController.reloadRootPageControllers(withNames: ["options", "workout", "music"], contexts: nil, orientation: .horizontal, pageIndex: 1)
        }
    }

    func applicationDidBecomeActive() {
        print(#function)
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    func handleActiveWorkoutRecovery() {
        print(#function)
        WorkoutSessionManager.healthStore.recoverActiveWorkoutSession { workoutSession, error in
            guard let workoutSession = workoutSession else {
                print("could not recover active workout session: \(error?.localizedDescription ?? "nil")")
                return
            }
            
            print("successfully recovered workout session")
        
            WorkoutSessionManagerStore.shared.recoverWorkoutSession(workoutSession: workoutSession)
        }
    }
    
    /**
     prepares the current workout session so that the startWorkout message can be received
     */
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        print(#function)
        
        WorkoutSessionManagerStore.shared.ensurePreparedWorkoutSession(configuration: workoutConfiguration) { result in
            switch result {
            case .success:
                PhoneConnectionManager.shared.sendPreparedWorkoutSession()
            case .failure(let error):
                print("could not prepare workout session: \(error)")
            }
        }
    }
}
