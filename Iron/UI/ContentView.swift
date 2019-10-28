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
    
    @State private var restoreResult: RestoreResult?
    
    private struct RestoreResult: Identifiable {
        let id = UUID()
        let success: Bool
        let error: Error?
    }
    
    private func alert(restoreResult: RestoreResult) -> Alert {
        if restoreResult.success {
            return Alert(title: Text("Restore Successful"))
        } else {
            let errorMessage: String?
            if let decodingError = restoreResult.error as? DecodingError {
                switch decodingError {
                case let .dataCorrupted(context):
                    errorMessage = "Data corrupted. \(context.debugDescription)"
                case let .keyNotFound(_, context):
                    errorMessage = "Key not found. \(context.debugDescription)"
                case let .typeMismatch(_, context):
                    errorMessage = "Type mismatch. \(context.debugDescription)"
                case let .valueNotFound(_, context):
                    errorMessage = "Value not found. \(context.debugDescription)"
                @unknown default:
                    errorMessage = "Decoding error."
                }
            } else {
                errorMessage = restoreResult.error?.localizedDescription
            }
            let text = errorMessage.map { Text($0) }
            return Alert(title: Text("Restore Failed"), message: text)
        }
    }
    
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
            guard let backupData = output.userInfo?[restoreFromBackupDataUserInfoKey] as? Data else { return }
            self.restoreBackupData = DataHolder(data: backupData)
        }
        .actionSheet(item: $restoreBackupData) { dataHolder in
            ActionSheet(
                title: Text("Restore Backup"),
                message: Text("This cannot be undone. All your workouts and custom exercises will be replaced with the ones from the backup. Your settings are not affected."),
                buttons: [
                    .destructive(Text("Restore"), action: {
                        do {
                            // For now statically use viewContext and ExerciseStore.shared because we don't want to observer their changes in this view
                            try IronBackup.restoreBackupData(data: dataHolder.data, managedObjectContext: AppDelegate.instance.persistentContainer.viewContext, exerciseStore: ExerciseStore.shared)
                            print("Restore successful")
                            self.restoreResult = RestoreResult(success: true, error: nil)
                        } catch {
                            print("Restore failed: \(error)")
                            self.restoreResult = RestoreResult(success: false, error: error)
                        }
                    }),
                    .cancel()
                ]
            )
        }
        .alert(item: $restoreResult) { restoreResult in
            self.alert(restoreResult: restoreResult)
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
