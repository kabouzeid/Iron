//
//  ContentView.swift
//  WatchIron Extension
//
//  Created by Karim Abou Zeid on 02.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        _ContentView()
            .environmentObject(WorkoutSessionManagerStore.shared)
            .environmentObject(PhoneConnectionManager.shared)
    }
}

private struct _ContentView: View {
    @State private var showWorkoutOnPhoneNotAffectedAlert = false
    @EnvironmentObject var phoneConnectionManager: PhoneConnectionManager
    @EnvironmentObject var workoutSessionManagerStore: WorkoutSessionManagerStore
    
    var body: some View {
        Group {
            if phoneConnectionManager.isActivated {
                if workoutSessionManagerStore.workoutSessionManager != nil {
                    WorkoutSessionView(workoutSessionManager: workoutSessionManagerStore.workoutSessionManager!)
                        .contextMenu {
                            Button(action: {
                                guard let start = self.workoutSessionManagerStore.workoutSessionManager?.startDate else { return }
                                guard let uuid = self.workoutSessionManagerStore.workoutSessionManager?.uuid else { return }
                                let end = self.workoutSessionManagerStore.workoutSessionManager?.endDate ?? Date()
                                self.workoutSessionManagerStore.endWorkoutSession(start: start, end: end, uuid: uuid)
                                
                                self.showWorkoutOnPhoneNotAffectedAlert = true
                            }) {
                                VStack {
                                    Image(systemName: "checkmark")
                                    Text("End Tracking")
                                }
                            }
                            
                            Button(action: {
                                if let uuid = self.workoutSessionManagerStore.workoutSessionManager?.uuid {
                                    self.workoutSessionManagerStore.discardWorkoutSession(uuid: uuid)
                                } else {
                                    self.workoutSessionManagerStore.unprepareWorkoutSession()
                                }
                                
                                self.showWorkoutOnPhoneNotAffectedAlert = true
                            }) {
                                VStack {
                                    Image(systemName: "xmark")
                                    Text("Cancel Tracking")
                                }
                            }
                        }
                    .alert(isPresented: $showWorkoutOnPhoneNotAffectedAlert) {
                        Alert(title: Text("Stopped Tracking"), message: Text("The workout on your phone is not affected."))
                    }
                } else {
                    Text("Start a workout on your phone.")
                }
            } else {
                Text("Waiting for connection...")
            }
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