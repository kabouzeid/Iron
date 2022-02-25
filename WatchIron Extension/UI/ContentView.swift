//
//  MainContentView.swift
//  WatchIron Extension
//
//  Created by Karim Abou Zeid on 02.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WatchKit
import HealthKit

struct ContentView: View {
    var body: some View {
        _ContentView()
            .environmentObject(WorkoutSessionManagerStore.shared)
    }
}

private struct _ContentView: View {
    @EnvironmentObject var workoutSessionManagerStore: WorkoutSessionManagerStore
    
    @State private var selectedTab = "workout"
    
    @ViewBuilder
    var body: some View {
        if workoutSessionManagerStore.workoutSessionManager != nil {
            TabView(selection: $selectedTab) {
                OptionsView()
                    .tag("options")
                
                WorkoutSessionView(workoutSessionManager: workoutSessionManagerStore.workoutSessionManager!)
                    .tag("workout")
                
                NowPlayingView()
                    .tag("now playing")
            }
        } else {
            Group {
                if let s = errorMessage {
                    Text(s).foregroundColor(.red)
                } else {
                    Text("Start a workout on your iPhone.")
                }
            }.onAppear {
                self.selectedTab = "workout"
            }
        }
    }
    
    private var errorMessage: String? {
        guard HKHealthStore.isHealthDataAvailable() else {
            return "HealthKit is not available on this device."
        }
        
        switch WorkoutSessionManager.healthStore.authorizationStatus(for: .workoutType()) {
        case .notDetermined:
            return nil
        case .sharingAuthorized:
            return nil
        case .sharingDenied:
            return "Not authorized for Apple Health. You can authorize Iron in the settings app."
        @unknown default:
            return nil
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
