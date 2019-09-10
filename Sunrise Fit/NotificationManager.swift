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

    func requestUnfinishedTrainingNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Unfinished training"
        content.body = "Your current training is unfinished. Do you want to finish it?"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15*60, repeats: true)
        
        let request = UNNotificationRequest(identifier: NotificationIdentifier.unfinishedTraining.rawValue, content: content, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("error \(String(describing: error))")
            }
        }
    }
    
    func updateRestTimerUpNotificationRequest(remainingTime: TimeInterval?, totalTime: TimeInterval? = nil) {
        guard let remainingTime = remainingTime, remainingTime > 0 else {
            removePendingNotificationRequests(withIdentifiers: [.restTimerUp])
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "You've rested enough!"
        if let totalTime = totalTime, let totalTimeString = restTimerDurationFormatter.string(from: totalTime) {
            content.title += " (\(totalTimeString))"
        }
        content.body = "Back to work 💪"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remainingTime, repeats: false)
        
        let request = UNNotificationRequest(identifier: NotificationIdentifier.restTimerUp.rawValue, content: content, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("error \(String(describing: error))")
            }
        }
    }
    
    enum NotificationIdentifier: String {
        case unfinishedTraining
        case restTimerUp
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.identifier == NotificationIdentifier.restTimerUp.rawValue {
            completionHandler([.alert, .sound])
        }
    }
}
