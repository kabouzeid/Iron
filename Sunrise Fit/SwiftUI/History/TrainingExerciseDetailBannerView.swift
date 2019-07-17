//
//  TrainingExerciseDetailBannerView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 27.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct TrainingExerciseDetailBannerView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    let trainingExercise: TrainingExercise
    
    var body: some View {
        BannerView(entries: bannerViewEntries)
    }
    
    private var bannerViewEntries: [BannerViewEntry] {
        var entries = [BannerViewEntry]()
        
        entries.append(BannerViewEntry(id: 0, title: Text("Repetitions"), text: Text("\(trainingExercise.numberOfCompletedRepetitions)")))
        entries.append(BannerViewEntry(id: 1, title: Text("Weight"), text: Text("\(TrainingSet.weightStringFor(weightInKg: trainingExercise.totalCompletedWeight, unit: settingsStore.weightUnit))")))
        
        return entries
    }
}

#if DEBUG
struct TrainingExerciseDetailBannerView_Previews : PreviewProvider {
    static var previews: some View {
        TrainingExerciseDetailBannerView(trainingExercise: mockTrainingExercise)
            .environmentObject(mockTrainingsDataStore)
            .environmentObject(mockSettingsStoreMetric)
            .previewLayout(.sizeThatFits)
    }
}
#endif
