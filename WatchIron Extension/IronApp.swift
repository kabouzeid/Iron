//
//  IronApp.swift
//  IronWatch WatchKit Extension
//
//  Created by Karim Abou Zeid on 27.05.22.
//

import SwiftUI

@main
struct IronApp: App {
    @WKApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}

import HealthKit
import os.log

class AppDelegate: NSObject, WKApplicationDelegate {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "watch")
    
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        Self.logger.log("Checking whether active workout session can be recovered")
        handleActiveWorkoutRecovery() // somehow this isn't automatically called by the system?! last checked watchOS 8
        PhoneConnectionManager.shared.activateSession()
        _ = NotificationManager.shared
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
        Self.logger.log("Recovering active workout session")
        WorkoutSessionManager.healthStore.recoverActiveWorkoutSession { workoutSession, error in
            guard let workoutSession = workoutSession else {
                if let error = error {
                    Self.logger.error("Could not recover active workout session: \(error.localizedDescription)")
                } else {
                    Self.logger.info("No active workout session to recover")
                }
                return
            }
            Self.logger.info("Successfully recovered active workout session")
            WorkoutSessionManagerStore.shared.recoverWorkoutSession(workoutSession: workoutSession)
        }
    }
    
    /// from `HKHealthStore.startWatchApp`
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        PhoneConnectionManager.shared.handlePrepareWorkoutSession(workoutConfiguration)
    }
}
