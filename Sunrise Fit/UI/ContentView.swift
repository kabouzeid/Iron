//
//  ContentView.swift
//  SwiftUI Playground
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    @FetchRequest(fetchRequest: Training.currentTrainingFetchRequest) var currentTrainings

    var currentTraining: Training? {
        assert(currentTrainings.count <= 1)
        return currentTrainings.first
    }

    private func trainingView(training: Training?) -> some View {
        Group { // is Group the appropiate choice here? (want to avoid AnyView)
            if training != nil {
                TrainingView(training: training!)
            } else {
                StartTrainingView()
            }
        }
    }
    
    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Image("today_apps")
                    Text("Feed")
                }
                .tag(0)
            HistoryView()
                .tabItem {
                    Image("clock")
                    Text("History")
                }
                .tag(1)
            trainingView(training: currentTraining)
                .tabItem {
                    Image("training")
                    Text("Workout")
                }
                .tag(2)
            ExerciseMuscleGroupsView(exerciseMuscleGroups: Exercises.exercisesGrouped)
                .tabItem {
                    Image("list")
                    Text("Exercises")
                }
                .tag(3)
            SettingsView()
                .tabItem {
                    Image("settings")
                    Text("Settings")
                }
                .tag(4)
        }
        .edgesIgnoringSafeArea([.top])
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(mockSettingsStoreMetric)
            .environmentObject(restTimerStore)
            .environment(\.managedObjectContext, mockManagedObjectContext)
    }
}
#endif
