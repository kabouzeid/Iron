//
//  ContentView.swift
//  SwiftUI Playground
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    var body: some View {
        TabbedView {
            FeedView()
                .tabItemLabel(
                    VStack {
                        Image("today_apps")
                        Text("Feed")
                    }
                )
                .tag(0)
            HistoryView()
                .tabItemLabel(
                    VStack {
                        // TODO: replace with systemName when it becomes available
//                        Image(systemName: "clock.fill")
                        Image("clock")
                        Text("History")
                    }
                )
                .tag(1)
            Text("Training")
                .tabItemLabel(
                    VStack {
                        Image("training")
                        Text("Training")
                    }
                )
                .tag(2)
            Text("Exercises")
                .tabItemLabel(
                    VStack {
                        Image("list")
                        Text("Exercises")
                    }
                )
                .tag(3)
//            Text("Settings")
            TextSizeDemo()
                .tabItemLabel(
                    VStack {
                        Image("settings")
                        Text("Settings")
                    }
                )
                .tag(4)
        }
        .edgesIgnoringSafeArea([.top])
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(mockTrainingsDataStore)
    }
}
#endif
