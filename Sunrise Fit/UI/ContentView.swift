//
//  ContentView.swift
//  SwiftUI Playground
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    
    private func trainingView(training: Training?) -> some View {
        ZStack {
            if training != nil {
                TrainingView(trainig: training!)
                    .animation(.default)
                    .transition(.scale)
                
            } else {
                StartTrainingView()
                    .animation(.default)
                    .transition(.scale)
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
            trainingView(training: Training.currentTraining(context: trainingsDataStore.context))
                .tabItem {
                    Image("training")
                    Text("Training")
                }
                .tag(2)
            ExerciseMuscleGroupsView(exerciseMuscleGroups: EverkineticDataProvider.exercisesGrouped)
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
            .environmentObject(mockTrainingsDataStore)
            .environmentObject(mockSettingsStoreMetric)
    }
}
#endif
