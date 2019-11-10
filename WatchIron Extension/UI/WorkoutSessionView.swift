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
    
    var labelSize: CGFloat {
        let width = WKInterfaceDevice.current().screenBounds.width
        if width >= 184 { // Series 5 - 44mm
            return 24
        } else if width >= 162 { // Series 5 - 40mm
            return 20 // 21 works too, but lets play it safe
        } else if width >= 156 { // Series 3 - 40mm
            return 20
        } else /* width >= 136 */ { // Series 3 - 38mm
            return 16
        }
    }
    
    var burnedCalories: Double? {
        workoutSessionManager.burnedCalories
    }
    
    var burnedCaloriesString: String {
        burnedCalories.map { String(format: "%.0f", $0) } ?? "--"
    }
    
    var mostRecentHeartRate: Double? {
        workoutSessionManager.mostRecentHeartRate
    }
    
    var mostRecentHeartRateString: String {
        mostRecentHeartRate.map { String(format: "%.0f", $0) } ?? "--"
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center) {
                ElapsedTimeView(start: workoutSessionManager.startDate, end: workoutSessionManager.endDate).font(Font.title.monospacedDigit())
                Spacer()
                Image(systemName: "stopwatch.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: labelSize, weight: .bold, design: .rounded))
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(burnedCaloriesString).font(.title)
                Spacer()
                HStack(alignment: .center) {
                    Text("kcal".uppercased())
                    Image(systemName: "flame.fill")
                }
                .foregroundColor(.orange)
                .font(.system(size: labelSize, weight: .bold, design: .rounded))
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(mostRecentHeartRateString).font(.title)
                
                Spacer()
                
                HStack(alignment: .center) {
                    Text("bpm".uppercased())
                    PulsatingHeartView(bpm: mostRecentHeartRate)
                }
                .foregroundColor(.red)
                .font(.system(size: labelSize, weight: .bold, design: .rounded))
            }
        }
    }
}

private struct ElapsedTimeView: View {
    @ObservedObject private var refresher = Refresher()
    
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
        Text(Self.durationFormatter.string(from: start ?? Date(), to: end ?? Date()) ?? "")
            .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in self.refresher.refresh() } // refreshing only every second is choppy
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
