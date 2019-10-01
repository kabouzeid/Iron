//
//  MockEnvironment.swift
//  Iron
//
//  Created by Karim Abou Zeid on 01.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

extension View {
    func mockEnvironment(weightUnit: WeightUnit, isPro: Bool) -> some View {
        self
            .environmentObject(weightUnit == .metric ? SettingsStore.mockMetric : SettingsStore.mockImperial)
            .environmentObject(RestTimerStore.shared)
            .environmentObject(ExerciseStore.shared)
            .environmentObject(isPro ? EntitlementStore.mockPro : EntitlementStore.mockNoPro)
            .environment(\.managedObjectContext, weightUnit == .metric ? MockTrainingsData.metricRandom.context : MockTrainingsData.imperialRandom.context)
    }
    
    func screenshotEnvironment(weightUnit: WeightUnit) -> some View {
        self
            .environment(\.managedObjectContext, weightUnit == .metric ? MockTrainingsData.metric.context : MockTrainingsData.imperial.context)
            .mockEnvironment(weightUnit: weightUnit, isPro: true)
    }
}
