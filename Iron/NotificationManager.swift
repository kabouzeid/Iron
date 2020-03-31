//
//  NotificationManager.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 03.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import UserNotifications

class NotificationManager: NSObject {
    static let shared = NotificationManager(notificationCenter: UNUserNotificationCenter.current())
    
    let notificationCenter: UNUserNotificationCenter
    
    init(notificationCenter: UNUserNotificationCenter) {
        self.notificationCenter = notificationCenter
        super.init()
        self.notificationCenter.delegate = self
        
        let restTimerAdd30Action = UNNotificationAction(identifier: NotificationActionIdentifier.restTimerAdd30.rawValue, title: "+30s")
        let restTimerAdd60Action = UNNotificationAction(identifier: NotificationActionIdentifier.restTimerAdd60.rawValue, title: "+60s")
        let restTimerAdd90Action = UNNotificationAction(identifier: NotificationActionIdentifier.restTimerAdd90.rawValue, title: "+90s")
        // Define the notification type
        let restTimerUpCategory =
            UNNotificationCategory(identifier: NotificationCategoryIdentifier.restTimerUp.rawValue,
                                   actions: [restTimerAdd30Action, restTimerAdd60Action, restTimerAdd90Action],
                                   intentIdentifiers: [],
                                   hiddenPreviewsBodyPlaceholder: "",
                                   options: [.hiddenPreviewsShowTitle, .hiddenPreviewsShowSubtitle, .allowAnnouncement])
        // Register the notification type.
        notificationCenter.setNotificationCategories([restTimerUpCategory])
    }
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if let error = error {
                print(error)
            }
        }
    }
    
    func removePendingNotificationRequests(withIdentifiers: [NotificationIdentifier]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: withIdentifiers.map { $0.rawValue })
    }
    
    func removeDeliveredNotification(withIdentifiers: [NotificationIdentifier]) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: withIdentifiers.map { $0.rawValue })
    }

    func requestUnfinishedWorkoutNotification() {
        notificationCenter.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Unfinished workout"
            content.body = "You have an unfinished workout. Do you want to finish it?"
            if settings.soundSetting == .enabled {
                content.sound = UNNotificationSound.default
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15*60, repeats: true)
            
            let request = UNNotificationRequest(identifier: NotificationIdentifier.unfinishedWorkout.rawValue, content: content, trigger: trigger)
            
            self.notificationCenter.add(request) { (error) in
                if let error = error {
                    print("error \(String(describing: error))")
                }
            }
        }
    }
    
    func updateRestTimerUpNotificationRequest(remainingTime: TimeInterval?, totalTime: TimeInterval? = nil) {
        notificationCenter.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            
            guard let remainingTime = remainingTime, remainingTime > 0 else {
                self.removePendingNotificationRequests(withIdentifiers: [.restTimerUp])
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "You've rested enough!"
            if let totalTime = totalTime, let totalTimeString = restTimerDurationFormatter.string(from: totalTime) {
                content.title += " (\(totalTimeString))"
            }
            content.body = "Back to work 💪"
            if settings.soundSetting == .enabled {
                content.sound = UNNotificationSound.default
            }
            content.categoryIdentifier = NotificationCategoryIdentifier.restTimerUp.rawValue
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remainingTime, repeats: false)
            
            let request = UNNotificationRequest(identifier: NotificationIdentifier.restTimerUp.rawValue, content: content, trigger: trigger)
            
            self.notificationCenter.add(request) { (error) in
                if let error = error {
                    print("error \(String(describing: error))")
                }
            }
        }
    }
    
    func requestStartedWorkoutFromBackgroundNotification() {
        notificationCenter.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Your workout was started"
            content.body = "Open Iron to launch the Apple Watch companion."
            
            let request = UNNotificationRequest(identifier: NotificationIdentifier.startedWorkout.rawValue, content: content, trigger: nil)
            
            self.notificationCenter.add(request) { (error) in
                if let error = error {
                    print("error \(String(describing: error))")
                }
            }
        }
    }
    
    enum NotificationIdentifier: String {
        case unfinishedWorkout
        case unfinishedTraining // TODO: remove unfinishedTraining in future version
        case restTimerUp
        case startedWorkout
    }
    
    enum NotificationCategoryIdentifier: String {
        case restTimerUp
    }
    
    enum NotificationActionIdentifier: String {
        case restTimerAdd30
        case restTimerAdd60
        case restTimerAdd90
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.identifier == NotificationIdentifier.restTimerUp.rawValue {
            completionHandler([.alert, .sound])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        defer { completionHandler() }
        
        guard let duration = RestTimerStore.shared.restTimerDuration else { return}
        
        guard let actionIdentifier = NotificationActionIdentifier(rawValue: response.actionIdentifier) else { return }
        
        switch actionIdentifier {
        case .restTimerAdd30:
            RestTimerStore.shared.restTimerDuration = duration + 30
        case .restTimerAdd60:
            RestTimerStore.shared.restTimerDuration = duration + 60
        case .restTimerAdd90:
            RestTimerStore.shared.restTimerDuration = duration + 90
        }
    }
}
