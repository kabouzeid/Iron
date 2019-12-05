//
//  SessionContentView.swift
//  SwiftUI Playground
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

let NAVIGATION_BAR_SPACING: CGFloat = 16

struct ContentView : View {
    
    @State private var restoreResult: IdentifiableHolder<Result<Void, Error>>?
    @State private var restoreBackupData: IdentifiableHolder<Data>?
    
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
            guard let backupData = output.userInfo?[restoreFromBackupDataUserInfoKey] as? Data else { return }
            self.restoreBackupData = IdentifiableHolder(value: backupData)
        }
        .actionSheet(item: $restoreBackupData) { restoreBackupDataHolder in
            RestoreActionSheet.create(context: WorkoutDataStorage.shared.persistentContainer.viewContext, exerciseStore: ExerciseStore.shared, data: { restoreBackupDataHolder.value }) { result in
                self.restoreResult = IdentifiableHolder(value: result)
            }
        }
        .alert(item: $restoreResult) { restoreResultHolder in
            RestoreActionSheet.restoreResultAlert(restoreResult: restoreResultHolder.value)
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
