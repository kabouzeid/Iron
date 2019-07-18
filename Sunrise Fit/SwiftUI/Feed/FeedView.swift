//
//  FeedView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData

struct FeedView : View {
    let pinnedCharts = UserDefaults.standard.pinnedCharts() // TODO: create bindable object for refresh
    
    @State private var showingWidgetSelector = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    ActivityChartViewCell()
                    FeedBannerView()
                }
                
                Section {
                    ForEach(pinnedCharts) { chart in
                        ExerciseChartViewCell(exercise: EverkineticDataProvider.findExercise(id: chart.exerciseId)!, measurementType: chart.measurementType)
                    }
                    Button(action: {
                        self.showingWidgetSelector = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Widget")
                        }
                    }
                }
            }
            .listStyle(.grouped)
            .navigationBarTitle(Text("Feed"))
            .sheet(isPresented: $showingWidgetSelector) {
                // TODO: present actual view to choose exercise
                Text("Placeholder")
            }
        }
    }
}

#if DEBUG
struct FeedView_Previews : PreviewProvider {
    static var previews: some View {
        FeedView()
            .environmentObject(mockTrainingsDataStore)
            .environmentObject(mockSettingsStoreMetric)
    }
}
#endif
