//
//  WorkoutSessionView.swift
//  WatchIron Extension
//
//  Created by Karim Abou Zeid on 09.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Combine

struct WorkoutSessionView: View {
    @ObservedObject var workoutSessionManager: WorkoutSessionManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                TimelineView(.periodic(from: Date(), by: 1)) { context in
                    VStack(alignment: .leading, spacing: 0) {
                        ElapsedTimeView(start: workoutSessionManager.startDate, end: workoutSessionManager.endDate ?? context.date)
                            .font(.system(.title, design: .rounded).bold().monospacedDigit())
                            .foregroundColor(.yellow)
                        
                        HStack(alignment: .firstTextBaseline) {
                            RestTimerView(date: context.date, end: workoutSessionManager.restTimerEnd, keepRunning: workoutSessionManager.keepRestTimerRunning)
                                .font(.system(.title, design: .rounded).monospacedDigit())
                            Image(systemName: "timer")
                                .font(.system(.title3, design: .rounded))
                        }
                        .opacity(workoutSessionManager.restTimerEnd != nil ? 1 : 0)
                    }
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text(workoutSessionManager.burnedCalories.map {String(format: "%.0f", $0)} ?? "-")
                        .font(.system(.title, design: .rounded).monospacedDigit())
                    Text("kcal".uppercased())
                        .font(.system(.title3, design: .rounded))
                }
                
                HeartRateView(mostRecentHeartRate: workoutSessionManager.mostRecentHeartRate, mostRecentHeartRateDate: workoutSessionManager.mostRecentHeartRateDate)
            }
            .lineLimit(1)
            Spacer()
        }
        .scenePadding()
    }
}

private struct ElapsedTimeView: View {
    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    let start: Date?
    let end: Date?
    
    var body: some View {
        Text(start.map { Self.durationFormatter.string(from: $0, to: end ?? Date()) ?? "--:--:--" } ?? "--:--:--")
    }
}

private struct RestTimerView: View {
    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    let date: Date
    let end: Date?
    let keepRunning: Bool
    
    private var remainingTime: TimeInterval? {
        guard let end = end else { return nil }
        let remainingTime = end.timeIntervalSince(date)
        guard remainingTime >= 0 || keepRunning else { return nil }
        return remainingTime
    }
    
    // i.e. 8.1 and 8.9 should be displayed as 9
    private var roundedRemainingTime: TimeInterval? {
        remainingTime?.rounded(.up)
    }
    
    var body: some View {
        let remainingTime = roundedRemainingTime
        Text(remainingTime.map{ Self.durationFormatter.string(from: abs($0)) ?? "--:--" } ?? "--:--" )
            .foregroundColor((remainingTime ?? 0) < 0 ? .red : .primary)
    }
}

private struct HeartRateView: View {
    private static let MAX_HEART_RATE_AGE: Double = 10
    
    let mostRecentHeartRate: Double?
    let mostRecentHeartRateDate: Date?
    
    var body: some View {
        TimelineView(.periodic(from: mostRecentHeartRateDate ?? Date(), by: Self.MAX_HEART_RATE_AGE)) { context in
            HStack(alignment: .firstTextBaseline) {
                Text(mostRecentHeartRate.map { String(format: "%.0f", $0) } ?? "--")
                    .font(.system(.title, design: .rounded).monospacedDigit())
                
                HStack(alignment: .center) {
                    Text("bpm".uppercased())
                    PulsatingHeartView(bpm: measurementWasRecent(date: context.date) ? mostRecentHeartRate : nil)
                        .foregroundColor(measurementWasRecent(date: context.date) ? .red : .secondary)
                }
                .font(.system(.title3, design: .rounded))
            }
            .foregroundColor(measurementWasRecent(date: context.date) ? .primary : .secondary)
        }
    }
    
    func measurementWasRecent(date: Date) -> Bool {
        guard let mostRecentHeartRateDate = mostRecentHeartRateDate else {
            return false
        }
        return date.timeIntervalSince(mostRecentHeartRateDate) < Self.MAX_HEART_RATE_AGE
    }
}

private struct PulsatingHeartView: View {
    let bpm: Double?
    
    var body: some View {
        TimelineView(.animation) { context in
            Image(systemName: bpm != nil ? "heart.fill" : "heart")
                .scaleEffect(context.cadence == .live && bpm != nil ? scale(offset: context.date.timeIntervalSince1970) : 1)
        }
    }
    
    func scale(offset: Double) -> Double {
        return max(sin(2 * .pi * offset * (bpm ?? 0) / 60) * 0.15, 0) + 1
    }
}
