//
//  EndContentView.swift
//  WatchIron Extension
//
//  Created by Karim Abou Zeid on 11.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct EndContentView: View {
        var body: some View {
            _EndContentView()
                .environmentObject(WorkoutSessionManagerStore.shared)
                .environmentObject(PhoneConnectionManager.shared)
        }
}

private struct _EndContentView: View {
    @EnvironmentObject var workoutSessionManagerStore: WorkoutSessionManagerStore
    
    var body: some View {
        ScrollView {
            VStack {
                Text("This does not affect the workout on your phone and normally there is no need to do this.")
                
                Button(action: {
                    guard let start = self.workoutSessionManagerStore.workoutSessionManager?.startDate else { return }
                    guard let uuid = self.workoutSessionManagerStore.workoutSessionManager?.uuid else { return }
                    let end = self.workoutSessionManagerStore.workoutSessionManager?.endDate ?? Date()
                    self.workoutSessionManagerStore.endWorkoutSession(start: start, end: end, uuid: uuid)
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("End Tracking")
                    }
                }
                
                Button(action: {
                    if let uuid = self.workoutSessionManagerStore.workoutSessionManager?.uuid {
                        self.workoutSessionManagerStore.discardWorkoutSession(uuid: uuid)
                    } else {
                        self.workoutSessionManagerStore.unprepareWorkoutSession(force: true)
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Cancel Tracking")
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}


struct EndContentView_Previews: PreviewProvider {
    static var previews: some View {
        EndContentView()
    }
}
