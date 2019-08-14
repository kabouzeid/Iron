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

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView:
                ContentView()
                    .environmentObject(settingsStore)
                    .environmentObject(restTimerStore)
                    .environment(\.managedObjectContext, AppDelegate.instance.persistentContainer.viewContext)
            )
            self.window = window
            window.makeKeyAndVisible()
        }
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
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [NotificationID.unfinishedTraining.rawValue, NotificationID.restTimerUp.rawValue])
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.unfinishedTraining.rawValue, NotificationID.restTimerUp.rawValue])
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
        // Save changes in the application's managed object context when the application transitions to the background.
        AppDelegate.instance.persistentContainer.viewContext.safeSave()
        
        // remind the user 15 mins after closing the app if the training ist still unfinished
        if (try? AppDelegate.instance.persistentContainer.viewContext.count(for: Training.currentTrainingFetchRequest)) ?? 0 > 0 {
            requestUnfinishedTrainingNotification()
        }
        
        if let remainingTime = restTimerStore.restTimerRemainingTime {
            requestRestTimerUpNotification(remainingTime: remainingTime)
        }
    }
    
    private func requestUnfinishedTrainingNotification() {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Unfinished training"
        content.body = "Your current training is unfinished. Do you want to finish it?"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: true)
        
        let request = UNNotificationRequest(identifier: NotificationID.unfinishedTraining.rawValue, content: content, trigger: trigger)
        
        center.add(request) { (error) in
            if let error = error {
                print("error \(String(describing: error))")
            }
        }
    }
    
    private func requestRestTimerUpNotification(remainingTime: TimeInterval) {
        guard remainingTime > 0 else { return}
        
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "You've rested enough!"
        content.body = "Back to work 💪"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remainingTime, repeats: false)
        
        let request = UNNotificationRequest(identifier: NotificationID.unfinishedTraining.rawValue, content: content, trigger: trigger)
        
        center.add(request) { (error) in
            if let error = error {
                print("error \(String(describing: error))")
            }
        }
    }
    
    enum NotificationID: String {
        case unfinishedTraining
        case restTimerUp
    }
}
