//
//  RestTimerStore.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 12.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Combine

// to be used in other places
let restTimerDurationFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = .pad
    return formatter
}()

let restTimerCustomTimes: [TimeInterval] = {
    stride(from: 30 as TimeInterval, through: 10*60, by: 5).map { $0 }
}()

final class RestTimerStore: ObservableObject {
    static let shared = RestTimerStore() // singleton

    let objectWillChange = ObservableObjectPublisher()
    
    private var userDefaults: UserDefaults
    
    private init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    private convenience init() {
        self.init(userDefaults: UserDefaults.standard)
    }
    
    var restTimerStart: Date? {
        get {
            userDefaults.restTimerStart
        }
        set {
            self.objectWillChange.send()
            userDefaults.restTimerStart = newValue
            updateNotification()
            updateWatch()
        }
    }
    
    var restTimerDuration: TimeInterval? {
        get {
            userDefaults.restTimerDuration
        }
        set {
            self.objectWillChange.send()
            userDefaults.restTimerDuration = newValue
            updateNotification()
            updateWatch()
        }
    }
    
    var recentRestTimes: [TimeInterval] {
        get {
            userDefaults.recentRestTimes
        }
        set {
            self.objectWillChange.send()
            userDefaults.recentRestTimes = newValue
        }
    }
    
    private func updateNotification() {
        NotificationManager.shared.updateRestTimerUpNotificationRequest(remainingTime: self.restTimerRemainingTime, totalTime: self.restTimerDuration)
    }
    
    private func updateWatch() {
        if let uuid = WatchConnectionManager.shared.currentWatchWorkoutUuid {
            WatchConnectionManager.shared.updateWatchWorkoutRestTimerEnd(end: restTimerEnd, uuid: uuid)
        }
    }
}

extension RestTimerStore {
    var restTimerEnd: Date? {
        guard let duration = restTimerDuration else { return nil }
        return restTimerStart?.addingTimeInterval(duration)
    }
    
    var restTimerRemainingTime: TimeInterval? {
        guard let restTimerEnd = restTimerEnd else { return nil }
        let remainingTime = restTimerEnd.timeIntervalSince(Date())
        guard remainingTime >= 0 else { return nil }
        return remainingTime
    }
}
