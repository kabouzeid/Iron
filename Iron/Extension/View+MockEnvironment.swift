//
//  View+MockEnvironment.swift
//  Iron
//
//  Created by Karim Abou Zeid on 01.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

#if DEBUG
import SwiftUI
import WorkoutDataKit

extension View {
    func mockEnvironment(weightUnit: WeightUnit, isPro: Bool) -> some View {
        self
            .environmentObject(weightUnit == .metric ? SettingsStore.mockMetric : SettingsStore.mockImperial)
            .environmentObject(RestTimerStore.shared)
            .environmentObject(ExerciseStore.shared)
            .environmentObject(isPro ? EntitlementStore.mockPro : EntitlementStore.mockNoPro)
            .environment(\.managedObjectContext, weightUnit == .metric ? MockWorkoutData.metricRandom.context : MockWorkoutData.imperialRandom.context)
    }
    
    func screenshotEnvironment(weightUnit: WeightUnit) -> some View {
        self
            .environment(\.managedObjectContext, weightUnit == .metric ? MockWorkoutData.metric.context : MockWorkoutData.imperial.context)
            .mockEnvironment(weightUnit: weightUnit, isPro: true)
    }
}
#endif
