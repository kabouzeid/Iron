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
    
    @ObservedObject var trainingExercise: TrainingExercise
    
    var body: some View {
        BannerView(entries: bannerViewEntries)
    }
    
    private var bannerViewEntries: [BannerViewEntry] {
        var entries = [BannerViewEntry]()
        
        entries.append(BannerViewEntry(id: 0, title: Text("Repetitions"), text: Text("\(trainingExercise.numberOfCompletedRepetitions ?? 0)")))
        entries.append(BannerViewEntry(id: 1, title: Text("Weight"), text: Text("\(WeightUnit.format(weight: trainingExercise.totalCompletedWeight ?? 0, from: .metric, to: settingsStore.weightUnit))")))
        
        return entries
    }
}

#if DEBUG
struct TrainingExerciseDetailBannerView_Previews : PreviewProvider {
    static var previews: some View {
        TrainingExerciseDetailBannerView(trainingExercise: mockTrainingExercise)
            .environmentObject(mockSettingsStoreMetric)
            .environment(\.managedObjectContext, mockManagedObjectContext)
            .previewLayout(.sizeThatFits)
    }
}
#endif