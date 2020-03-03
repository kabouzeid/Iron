//
//  TimerBannerView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 14.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct TimerBannerView: View {
    @EnvironmentObject var restTimerStore: RestTimerStore
    
    @ObservedObject var workout: Workout

    @ObservedObject private var refresher = Refresher()
    
    @State private var activeSheet: SheetType?

    private enum SheetType: Identifiable {
        case restTimer
        case editTime
        
        var id: Self { self }
    }

    private let workoutTimerDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    private var closeSheetButton: some View {
        Button("Close") {
            self.activeSheet = nil
        }
    }
    
    private var editTimeSheet: some View {
        NavigationView {
            EditCurrentWorkoutTimeView(workout: workout)
                .navigationBarTitle("Workout Duration", displayMode: .inline)
                .navigationBarItems(leading: closeSheetButton)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var restTimerSheet: some View {
        NavigationView {
            RestTimerView().environmentObject(self.restTimerStore)
                .navigationBarTitle("Rest Timer", displayMode: .inline)
                .navigationBarItems(leading: closeSheetButton)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var body: some View {
        HStack {
            Button(action: {
                self.activeSheet = .editTime
            }) {
                HStack {
                    Image(systemName: "clock")
                    Text(workoutTimerDurationFormatter.string(from: workout.safeDuration) ?? "")
                        .font(Font.body.monospacedDigit())
                }
                .padding()
            }

            Spacer()

            Button(action: {
                self.activeSheet = .restTimer
            }) {
                HStack {
                    Image(systemName: "timer")
                    restTimerStore.restTimerRemainingTime.map({
                        Text(restTimerDurationFormatter.string(from: $0.rounded(.up)) ?? "")
                            .font(Font.body.monospacedDigit())
                    })
                }
                .padding()
            }
        }
        .background(Color(.systemFill).opacity(0.5))
//        .background(VisualEffectView(effect: UIBlurEffect(style: .systemMaterial)))
        .sheet(item: $activeSheet) { sheet in
            if sheet == .editTime {
                self.editTimeSheet
            } else if sheet == .restTimer {
                self.restTimerSheet
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in self.refresher.refresh() }
    }
}

#if DEBUG
struct TimerBannerView_Previews: PreviewProvider {
    static var previews: some View {
        if RestTimerStore.shared.restTimerRemainingTime == nil {
            RestTimerStore.shared.restTimerStart = Date()
            RestTimerStore.shared.restTimerDuration = 10
        }
        return TimerBannerView(workout: MockWorkoutData.metricRandom.currentWorkout)
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
