//
//  WorkoutRoutineSetCell.swift
//  Iron
//
//  Created by Karim Abou Zeid on 21.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct WorkoutRoutineSetCell: View {
    @ObservedObject var workoutRoutineSet: WorkoutRoutineSet
    let index: Int
    
    var isSelected = false
    
    private var titleView: some View {
        HStack {
            if workoutRoutineSet.displayTitle != nil {
                workoutRoutineSet.displayTitle.map {
                    Text($0)
                }
            } else {
                Text("Set")
            }
        }.foregroundColor(isSelected ? .accentColor : .primary)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                titleView
                
                workoutRoutineSet.comment.map {
                    Text($0.enquoted)
                        .lineLimit(1)
                        .font(Font.caption.italic())
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()

            Text("\(index)")
                .font(Font.body.monospacedDigit())
                .foregroundColor(workoutRoutineSet.tagValue != nil ? .clear : .secondary)
                .background(
                    Group {
                        workoutRoutineSet.tagValue.map {
                            Text($0.title.first!.uppercased())
                                .fontWeight(.semibold)
                                .foregroundColor($0.color)
                                .fixedSize()
                        }
                    }
                )
        }
    }
}

#if DEBUG
struct WorkoutRoutineSetCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            WorkoutRoutineSetCell(workoutRoutineSet: MockWorkoutData.metric.workoutRoutineSet, index: 1, isSelected: false)
                .mockEnvironment(weightUnit: .metric, isPro: true)
                .previewLayout(.sizeThatFits)
            
            WorkoutRoutineSetCell(workoutRoutineSet: MockWorkoutData.metric.workoutRoutineSet, index: 1, isSelected: true)
                .mockEnvironment(weightUnit: .metric, isPro: true)
                .previewLayout(.sizeThatFits)
        }.listStyle(GroupedListStyle())
    }
}
#endif
