//
//  ActivityChartViewCell.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ActivityChartViewCell : View {
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    
    var body: some View {
        return VStack(alignment: .leading) {
            Text("Activity")
                .font(.body)
            Text("Workouts per week")
                .font(.caption)
                .color(.secondary)
            ActivityChartView()
                .frame(height: 200)
        }
    }
}

#if DEBUG
struct ActivityChartViewCell_Previews : PreviewProvider {
    static var previews: some View {
        ActivityChartViewCell().environmentObject(mockTrainingsDataStore)
    }
}
#endif
