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
    
    private let timeRefresher = Refresher()
    
    var labelSize: CGFloat {
        let width = WKInterfaceDevice.current().screenBounds.width
        if width >= 184 { // Series 5 - 44mm
            return 21 // max 21
        } else if width >= 162 { // Series 5 - 40mm
            return 18 // max 18
        } else if width >= 156 { // Series 3 - 40mm
            return 18
        } else /* width >= 136 */ { // Series 3 - 38mm
            return 16
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center) {
                ElapsedTimeView(refresher: timeRefresher, start: workoutSessionManager.startDate, end: workoutSessionManager.endDate)
                    .font(Font.system(size: labelSize * 1.5).monospacedDigit())
                Spacer()
                Image(systemName: "stopwatch.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: labelSize, weight: .bold, design: .rounded))
            }
            
            HStack(alignment: .firstTextBaseline) {
                RestTimerView(refresher: timeRefresher, end: workoutSessionManager.restTimerEnd, keepRunning: workoutSessionManager.keepRestTimerRunning)
                    .font(Font.system(size: labelSize * 1.5).monospacedDigit())
                Spacer()
                Image(systemName: "timer")
                    .foregroundColor(.blue)
                    .font(.system(size: labelSize, weight: .bold, design: .rounded))
            }
            
            HStack(alignment: .firstTextBaseline) {
                Group {
                    if let burnedCalories = workoutSessionManager.burnedCalories {
                        Text(String(format: "%.0f", burnedCalories))
                    } else {
                        Text("0").foregroundColor(.clear)
                    }
                }.font(.system(size: labelSize * 1.5))
                Spacer()
                HStack(alignment: .center) {
                    Text("kcal".uppercased())
                    Image(systemName: "flame.fill")
                }
                .foregroundColor(.orange)
                .font(.system(size: labelSize, weight: .bold, design: .rounded))
            }
            
            HStack(alignment: .firstTextBaseline) {
                Group {
                    if let mostRecentHeartRate = workoutSessionManager.mostRecentHeartRate {
                        Text(String(format: "%.0f", mostRecentHeartRate))
                    } else {
                        Text("0").foregroundColor(.clear)
                    }
                }.font(.system(size: labelSize * 1.5))
                
                Spacer()
                
                HStack(alignment: .center) {
                    Text("bpm".uppercased())
                    PulsatingHeartView(bpm: workoutSessionManager.mostRecentHeartRate)
                }
                .foregroundColor(.red)
                .font(.system(size: labelSize, weight: .bold, design: .rounded))
            }
            
            Divider().padding([.top, .bottom], 2)
            
            Text(workoutSessionManager.selectedSetText ?? "No set selected")
        }
        .lineLimit(1)
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in self.timeRefresher.refresh() } // refreshing only every second is too choppy
    }
}

private struct ElapsedTimeView: View {
    @ObservedObject var refresher: Refresher
    
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
        if let start = start {
            Text(Self.durationFormatter.string(from: start, to: end ?? Date()) ?? "")
        } else {
            Text("00:00").foregroundColor(.clear)
        }
    }
}

private struct RestTimerView: View {
    @ObservedObject var refresher: Refresher
    
    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    let end: Date?
    let keepRunning: Bool
    
    private var remainingTime: TimeInterval? {
        guard let end = end else { return nil }
        let remainingTime = end.timeIntervalSince(Date())
        guard remainingTime >= 0 || keepRunning else { return nil }
        return remainingTime
    }
    
    // i.e. 8.1 and 8.9 should be displayed as 9
    private var roundedRemainingTime: TimeInterval? {
        remainingTime?.rounded(.up)
    }
    
    var body: some View {
        if let remainingTime = roundedRemainingTime {
            Text(Self.durationFormatter.string(from: abs(remainingTime)) ?? "00:00")
                .foregroundColor(remainingTime < 0 ? .red : .primary)
        } else {
            Text("00:00").foregroundColor(.clear)
        }
    }
}

private struct PulsatingHeartView: View {
    @State private var heartScale: CGFloat = 1
    
    let bpm: Double?
    
    var body: some View {
        Image(systemName: "heart.fill")
            .scaleEffect(bpm != nil ? heartScale : 1)
            .animation(Animation.easeInOut(duration: 60 / (bpm ?? 1) / 2).repeatForever()) // bpm = 1 is arbitrary, but we want to avoid 0
            .onAppear { self.heartScale = 0.8 }
    }
}

private class Refresher: ObservableObject {
    var objectWillChange = ObservableObjectPublisher()
    func refresh() {
        self.objectWillChange.send()
    }
}
