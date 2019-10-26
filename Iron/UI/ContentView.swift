//
//  ContentView.swift
//  SwiftUI Playground
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid. All rights reserved.
//

import SwiftUI

let NAVIGATION_BAR_SPACING: CGFloat = 16

struct ContentView : View {
    
    struct DataHolder: Identifiable {
        let id = UUID()
        let data: Data
    }
    @State private var restoreBackupData: DataHolder?
    
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
        ], initialSelection: 2)
        // -----------------------------------------------
        .edgesIgnoringSafeArea([.top, .bottom])
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.RestoreFromBackup)) { output in
            guard let backupData = output.userInfo?[restoreFromBackupUserInfoBackupDataKey] as? Data else { return }
            self.restoreBackupData = DataHolder(data: backupData)
        }
        .alert(item: $restoreBackupData) { dataHolder in
            Alert(
                title: Text("Restore Backup"),
                message: Text("This cannot be undone. All your workouts and custom exercises will be replaced with the ones from the backup. Your settings are not affected."),
                primaryButton: .destructive(Text("Restore"), action: {
                    // TODO restore backup from dataHolder.data
                }), secondaryButton: .cancel())
        }
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
