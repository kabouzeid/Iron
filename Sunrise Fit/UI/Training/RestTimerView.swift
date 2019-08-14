//
//  RestTimerView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 14.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct RestTimerView: View {
    @EnvironmentObject var restTimerStore: RestTimerStore
    
    @ObservedObject private var refresher = Refresher()
    
    private let timerDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    private var timerText: String {
        guard let remainingTime = restTimerStore.restTimerRemainingTime?.rounded(.up) else { return "" }
        return timerDurationFormatter.string(from: remainingTime) ?? ""
    }
    
    private var remainingTimeInPercent: CGFloat {
        guard let duration = restTimerStore.restTimerDuration else { return 0 }
        guard let remainingTime = restTimerStore.restTimerRemainingTime else { return 0 }
        assert(duration > 0)
        return CGFloat(remainingTime / duration)
    }
    
    private var progressCircle: some View {
        ZStack {
            Circle()
                .stroke(Color(UIColor.systemFill), lineWidth: 8)
            Circle()
                .trim(from: 0, to: remainingTimeInPercent)
                .stroke(Color.accentColor, lineWidth: 8)
                .animation(.default)
        }
        .rotationEffect(.degrees(-90))
        .shadow(radius: 4)
    }
    
    private let buttonSize: CGFloat = 80
    var body: some View {
        VStack {
            ZStack {
                progressCircle
                    .frame(width: 200, height: 200)
                VStack {
                    Text(timerText)
                        .font(Font.largeTitle.monospacedDigit())
                    
                    Text(timerDurationFormatter.string(from: restTimerStore.restTimerDuration ?? 0) ?? "")
                        .font(Font.subheadline.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            HStack {
                Button(action: {
                    guard let duration = self.restTimerStore.restTimerDuration else { return }
                    let newDuration = duration - 10
                    if newDuration > 0 {
                        self.restTimerStore.restTimerDuration = newDuration
                    } else {
                        self.restTimerStore.restTimerDuration = nil
                    }
                }) {
                    Circle()
                        .foregroundColor(Color(UIColor.systemFill))
                        .frame(width: buttonSize, height: buttonSize)
                        .overlay(Text("-10s"))
                }
                .padding(4)

                Button(action: {
                    guard let duration = self.restTimerStore.restTimerDuration else { return }
                    self.restTimerStore.restTimerDuration = duration + 10
                }) {
                    Circle()
                        .foregroundColor(Color(UIColor.systemFill))
                        .frame(width: buttonSize, height: buttonSize)
                        .overlay(Text("+10s"))
                }
                .padding(4)

                Button(action: {
                    self.restTimerStore.restTimerStart = nil
                    self.restTimerStore.restTimerDuration = nil
                }) {
                    Circle()
                        .foregroundColor(Color.red.opacity(0.9))
                        .frame(width: buttonSize, height: buttonSize)
                        .overlay(Text("Cancel").fontWeight(.semibold).foregroundColor(.white))
                }
                .padding(4)
            }
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            self.refresher.refresh()
        }
    }
}

#if DEBUG
struct RestTimerView_Previews: PreviewProvider {
    static var previews: some View {
        if restTimerStore.restTimerRemainingTime == nil {
            restTimerStore.restTimerStart = Date()
            restTimerStore.restTimerDuration = 10
        }
        return RestTimerView()
            .environmentObject(restTimerStore)
//            .previewDevice(PreviewDevice(rawValue: "iPad Pro (11-inch)"))
//            .previewDevice(PreviewDevice(rawValue: "iPhone Xs Max"))
//            .previewDevice(PreviewDevice(rawValue: "iPhone SE"))
    }
}
#endif
