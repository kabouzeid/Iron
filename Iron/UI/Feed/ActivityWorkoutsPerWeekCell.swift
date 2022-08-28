//
//  ActivityWorkoutsPerWeekCell.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ActivityWorkoutsPerWeekCell : View {
    @State private var workoutsPerWeekMean = WorkoutsPerWeekMeanKey.defaultValue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .bold()
                .font(.subheadline)
                .foregroundColor(.accentColor)
            
            HStack {
                Text("Workouts Per Week")
                    .font(.headline)
                
                Spacer()
                
                if let mean = workoutsPerWeekMean {
                    Text("Ø\(String(format: "%.1f", mean))")
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            ActivityWorkoutsPerWeekView()
                .frame(height: 200)
                .onPreferenceChange(WorkoutsPerWeekMeanKey.self, perform: { value in
                    self.workoutsPerWeekMean = value
                })
        }
        .padding([.top, .bottom], 8)
    }
}

#if DEBUG
struct ActivityWorkoutsPerWeekViewCell_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            ActivityWorkoutsPerWeekCell()
                .mockEnvironment(weightUnit: .metric)
                .previewLayout(.sizeThatFits)
            
            List {
                ActivityWorkoutsPerWeekCell()
                    .mockEnvironment(weightUnit: .metric)
                    .previewLayout(.sizeThatFits)
            }.listStyleCompat_InsetGroupedListStyle()
        }
    }
}
#endif
