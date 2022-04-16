//
//  SessionContentView.swift
//  SwiftUI Playground
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid. All rights reserved.
//

import SwiftUI
import WorkoutDataKit
import IronData

let NAVIGATION_BAR_SPACING: CGFloat = 16

struct ContentView : View {
    @EnvironmentObject private var sceneState: SceneState
    
    @State private var restoreResult: IdentifiableHolder<Result<Void, Error>>?
    @State private var restoreBackupData: IdentifiableHolder<Data>?
    
    var body: some View {
        TabView(selection: $sceneState.selectedTabNumber) {
            FeedView()
                .tag(SceneState.Tab.feed.rawValue)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            WorkoutList()
                .tag(SceneState.Tab.history.rawValue)
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            
            WorkoutTab()
                .tag(SceneState.Tab.workout.rawValue)
                .tabItem {
                    Label("Workout", systemImage: "plus.diamond")
                }
            
            ExerciseList()
                .tag(SceneState.Tab.exercises.rawValue)
                .tabItem {
                    Label("Exercises", systemImage: "tray.full")
                }
            
            SettingsView()
                .tag(SceneState.Tab.settings.rawValue)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .productionEnvironment()
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.RestoreFromBackup)) { output in
            guard let backupData = output.userInfo?[restoreFromBackupDataUserInfoKey] as? Data else { return }
            self.restoreBackupData = IdentifiableHolder(value: backupData)
        }
        .overlay(
            Color.clear.frame(width: 0, height: 0)
            // This is a hack, we need to have this in an overlay and in Color.clear so it also works on iPad, tested on iOS 13.4
                .actionSheet(item: $restoreBackupData) { restoreBackupDataHolder in
                    RestoreActionSheet.create(context: WorkoutDataStorage.shared.persistentContainer.viewContext, exerciseStore: ExerciseStore.shared, data: { restoreBackupDataHolder.value }) { result in
                        self.restoreResult = IdentifiableHolder(value: result)
                    }
                }
        )
        .alert(item: $restoreResult) { restoreResultHolder in
            RestoreActionSheet.restoreResultAlert(restoreResult: restoreResultHolder.value)
        }
    }
}

private extension View {
#if DEBUG
    func productionEnvironment() -> some View {
        self
            .modifier(if: CommandLine.arguments.contains("-FASTLANE_SNAPSHOT"), then: {
                $0.screenshotEnvironment(weightUnit: .imperial) // only enable for taking screenshots.
            }, else: {
                $0._productionEnvironment()
            })
    }
#else
    func productionEnvironment() -> some View {
        _productionEnvironment()
    }
#endif
    
    private func _productionEnvironment() -> some View {
        self
            .environmentObject(SettingsStore.shared)
            .environmentObject(RestTimerStore.shared)
            .environmentObject(ExerciseStore.shared)
            .environmentObject(EntitlementStore.shared)
            .environment(\.managedObjectContext, WorkoutDataStorage.shared.persistentContainer.viewContext)
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
