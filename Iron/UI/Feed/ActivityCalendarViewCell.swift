//
//  ActivityCalendarViewCell.swift
//  Iron
//
//  Created by Karim Abou Zeid on 05.10.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ActivityCalendarViewCell: View {
    @State private var workoutsLast28Days = WorkoutsLast28DaysKey.defaultValue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .bold()
                .font(.subheadline)
                .foregroundColor(.accentColor)
            
            HStack {
                Text("Workouts Last 28 Days")
                    .font(.headline)
                
                Spacer()
                
                if let workoutsLast28Days = workoutsLast28Days {
                    Text("\(workoutsLast28Days) workouts")
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            ActivityCalendarHeaderView()
                .padding([.top, .bottom], 4)
            
            Divider()
            
            ActivityCalendarView()
                .frame(height: 250)
                .onPreferenceChange(WorkoutsLast28DaysKey.self, perform: { value in
                    workoutsLast28Days = value
                })
        }
        .padding([.top, .bottom], 8)
    }
}

#if DEBUG
struct ActivityCalendarViewCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActivityCalendarViewCell()
                .mockEnvironment(weightUnit: .metric)
                .previewLayout(.sizeThatFits)
            
            List {
                ActivityCalendarViewCell()
                    .mockEnvironment(weightUnit: .metric)
            }.listStyleCompat_InsetGroupedListStyle()
        }
    }
}
#endif
