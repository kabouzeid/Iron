//
//  SceneDelegate.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    var urlContexts: Set<UIOpenURLContext>?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView:
                ContentView()
//                    .screenshotEnvironment(weightUnit: .imperial) // only enable for taking screenshots
                    .environmentObject(SettingsStore.shared)
                    .environmentObject(RestTimerStore.shared)
                    .environmentObject(ExerciseStore.shared)
                    .environmentObject(EntitlementStore.shared)
                    .environment(\.managedObjectContext, AppDelegate.instance.persistentContainer.viewContext)
            )
            self.window = window
            window.makeKeyAndVisible()
        }
        
        urlContexts = connectionOptions.urlContexts // handle later because the view is not ready to handle input yet
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return } // for now we will only ever receive one URL
        handleURLContext(urlContext: urlContext)
    }
    
    private func handleURLContext(urlContext: UIOpenURLContext) {
        guard let backupData = try? urlData(urlContext: urlContext) else { return }
        NotificationCenter.default.post(name: .RestoreFromBackup, object: nil, userInfo: [restoreFromBackupUserInfoBackupDataKey : backupData])
    }
    
    private func urlData(urlContext: UIOpenURLContext) throws -> Data? {
        let openInPlace = urlContext.options.openInPlace
        if openInPlace {
            guard urlContext.url.startAccessingSecurityScopedResource() else { return nil }
        }
        defer {
            if openInPlace {
                urlContext.url.stopAccessingSecurityScopedResource()
            }
        }
        return try Data(contentsOf: urlContext.url)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        // the urls come from scene will connect, but they are handled here
        if let urlContexts = urlContexts {
            self.urlContexts = nil // don't process them again
            if let urlContext = urlContexts.first { // for now we will only ever receive one URL
                self.handleURLContext(urlContext: urlContext)
            }
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        NotificationManager.shared.notificationCenter.removeAllDeliveredNotifications()
        NotificationManager.shared.removePendingNotificationRequests(withIdentifiers: [.unfinishedWorkout])
        
        NotificationManager.shared.removePendingNotificationRequests(withIdentifiers: [.unfinishedTraining]) // TODO: remove unfinishedTraining in future version
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
        // Save changes in the application's managed object context when the application transitions to the background.
        AppDelegate.instance.persistentContainer.viewContext.safeSave()
        
        if let currentWorkout = try? AppDelegate.instance.persistentContainer.viewContext.fetch(Workout.currentWorkoutFetchRequest).first {
            guard currentWorkout.hasCompletedSets ?? false else { return } // allows the user to prefill a workout without getting the notification
            
            // remind the user about his unfinished workout
            NotificationManager.shared.requestUnfinishedWorkoutNotification()
        }
    }
}
