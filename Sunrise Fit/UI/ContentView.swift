//
//  ContentView.swift
//  SwiftUI Playground
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    @FetchRequest(fetchRequest: Training.currentTrainingFetchRequest) var fetchedResults

    var currentTraining: Training? {
        assert(fetchedResults.count <= 1)
        return fetchedResults.first
    }

    private func trainingView(training: Training?) -> some View {
        if training != nil {
            return AnyView(TrainingView(trainig: training!))
        } else {
            return AnyView(StartTrainingView())
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
            .environmentObject(mockSettingsStoreMetric)
            .environment(\.managedObjectContext, mockManagedObjectContext)
    }
}
#endif
