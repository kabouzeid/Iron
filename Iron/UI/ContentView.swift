//
//  ContentView.swift
//  SwiftUI Playground
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid. All rights reserved.
//

import SwiftUI

let NAVIGATION_BAR_SPACING: CGFloat = 12

struct ContentView : View {
    var body: some View {
//        TabView {
//            FeedView()
//                .tabItem {
//                    Image("today_apps")
//                    Text("Feed")
//                }
//                .tag(0)
//            HistoryView()
//                .tabItem {
//                    Image("clock")
//                    Text("History")
//                }
//                .tag(1)
//            workoutView(workout: currentWorkout)
//                .tabItem {
//                    Image("workout")
//                    Text("Workout")
//                }
//                .tag(2)
//            ExerciseMuscleGroupsView(exerciseMuscleGroups: Exercises.exercisesGrouped)
//                .tabItem {
//                    Image("list")
//                    Text("Exercises")
//                }
//                .tag(3)
//            SettingsView()
//                .tabItem {
//                    Image("settings")
//                    Text("Settings")
//                }
//                .tag(4)
//        }
        // TODO: replace with native SwiftUI TabView above
        // -----------------------------------------------
        UITabView(viewControllers: [
            FeedView()
                .hostingController()
                .tabItem(title: "Feed", image: UIImage(named: "today_apps"), tag: 0),
            
            HistoryView()
                .hostingController()
                .tabItem(title: "History", image: UIImage(named: "clock"), tag: 1),
            
            WorkoutTab()
                .hostingController()
                .tabItem(title: "Workout", image: UIImage(named: "workout"), tag: 2),
            
            ExerciseMuscleGroupsView()
                .hostingController()
                .tabItem(title: "Exercises", image: UIImage(named: "list"), tag: 3),
            
            SettingsView()
                .hostingController()
                .tabItem(title: "Settings", image: UIImage(named: "settings"), tag: 4),
        ])
        // -----------------------------------------------
        .edgesIgnoringSafeArea([.top, .bottom])
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
