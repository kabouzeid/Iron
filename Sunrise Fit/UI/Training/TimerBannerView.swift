//
//  TimerBannerView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 14.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct TimerBannerView: View {
    @EnvironmentObject var restTimerStore: RestTimerStore
    
    @ObservedObject var training: Training
    
    @State private var showingRestTimerSheet = false
    
    @ObservedObject private var refresher = Refresher()
    
    private let trainingTimerDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    private let restTimerDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    private var restTimerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Close") {
                    self.showingRestTimerSheet = false
                }
                Spacer()
            }.padding()
            Spacer()
            RestTimerView().environmentObject(self.restTimerStore)
            Spacer()
        }
    }
    
    var body: some View {
        HStack {
            Button(action: {
                // TODO: open start/end time editor
            }) {
                HStack {
                    Image(systemName: "clock")
                    Text(trainingTimerDurationFormatter.string(from: training.duration) ?? "")
                        .font(Font.body.monospacedDigit())
                }
            }
            
            Spacer()
            
            Button(action: {
                self.showingRestTimerSheet = true
            }) {
                HStack {
                    Image(systemName: "timer")
                    restTimerStore.restTimerRemainingTime.map({
                        Text(restTimerDurationFormatter.string(from: $0.rounded(.up)) ?? "")
                            .font(Font.body.monospacedDigit())
                    })
                }
            }
        }
        .padding()
        .background(VisualEffectView(effect: UIBlurEffect(style: .systemMaterial)))
        .sheet(isPresented: $showingRestTimerSheet) { self.restTimerSheet }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            self.refresher.refresh()
        }
    }
}

#if DEBUG
struct TimerBannerView_Previews: PreviewProvider {
    static var previews: some View {
        if restTimerStore.restTimerRemainingTime == nil {
            restTimerStore.restTimerStart = Date()
            restTimerStore.restTimerDuration = 10
        }
        return TimerBannerView(training: mockCurrentTraining)
            .environmentObject(restTimerStore)
    }
}
#endif
