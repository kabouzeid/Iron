//
//  MainContentView.swift
//  WatchIron Extension
//
//  Created by Karim Abou Zeid on 02.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import HealthKit

struct MainContentView: View {
    var body: some View {
        _ContentView()
            .environmentObject(WorkoutSessionManagerStore.shared)
    }
}

private struct _ContentView: View {
//    @State private var showWorkoutOnPhoneNotAffectedAlert = false
    @EnvironmentObject var workoutSessionManagerStore: WorkoutSessionManagerStore
    
    @ViewBuilder
    var body: some View {
        if workoutSessionManagerStore.workoutSessionManager != nil {
            WorkoutSessionView(workoutSessionManager: workoutSessionManagerStore.workoutSessionManager!)
            // TODO: bug, not working after switching to now playing view and back (as of watchOS 6.2)
//                                    .contextMenu {
//                                        if self.workoutSessionManagerStore.workoutSessionManager != nil {
//                                            Button(action: {
//                                                guard let start = self.workoutSessionManagerStore.workoutSessionManager?.startDate else { return }
//                                                guard let uuid = self.workoutSessionManagerStore.workoutSessionManager?.uuid else { return }
//                                                let end = self.workoutSessionManagerStore.workoutSessionManager?.endDate ?? Date()
//                                                self.workoutSessionManagerStore.endWorkoutSession(start: start, end: end, title: nil, uuid: uuid)
//
//                                                self.showWorkoutOnPhoneNotAffectedAlert = true
//                                            }) {
//                                                VStack {
//                                                    Image(systemName: "checkmark")
//                                                    Text("End Tracking")
//                                                }
//                                            }
//
//                                            Button(action: {
//                                                if let uuid = self.workoutSessionManagerStore.workoutSessionManager?.uuid {
//                                                    self.workoutSessionManagerStore.discardWorkoutSession(uuid: uuid)
//                                                } else {
//                                                    self.workoutSessionManagerStore.ignoredPreparedWorkoutSession()
//                                                }
//
//                                                self.showWorkoutOnPhoneNotAffectedAlert = true
//                                            }) {
//                                                VStack {
//                                                    Image(systemName: "xmark")
//                                                    Text("Cancel Tracking")
//                                                }
//                                            }
//                                        }
//                                    }
//                                    .alert(isPresented: $showWorkoutOnPhoneNotAffectedAlert) {
//                                        Alert(title: Text("Stopped Tracking"), message: Text("The workout on your phone is not affected."))
//                                    }
        } else {
            if let s = errorMessage {
                Text(s).foregroundColor(.red)
            } else {
                Text("Start a workout on your phone.")
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
        MainContentView()
    }
}
#endif
