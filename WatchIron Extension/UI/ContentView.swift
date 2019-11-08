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
            .environmentObject(AppState.shared)
            .environmentObject(WorkoutSessionManagerStore.shared)
    }
}

private struct _ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var workoutSessionManagerStore: WorkoutSessionManagerStore
    
    var body: some View {
        Group {
            if appState.isActivated {
                VStack {
                    Text("reachable: \(appState.isReachable.description)")
                    Text("workout state: \(workoutSessionManagerStore.workoutSessionManager?.workoutSession.state.name ?? "nil")")
                    Text("uuid: \(workoutSessionManagerStore.workoutSessionManager?.uuid?.uuidString ?? "nil")")
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
