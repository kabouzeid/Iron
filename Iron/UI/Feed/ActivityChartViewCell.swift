//
//  ActivityChartViewCell.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ActivityChartViewCell : View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Activity")
                .font(.body)
            Text("Workouts per week")
                .font(.caption)
                .foregroundColor(.secondary)
            ActivityChartView()
                .frame(height: 250)
        }
    }
}

#if DEBUG
struct ActivityChartViewCell_Previews : PreviewProvider {
    static var previews: some View {
        ActivityChartViewCell()
            .environment(\.managedObjectContext, mockManagedObjectContext)
            .previewLayout(.sizeThatFits)
    }
}
#endif
