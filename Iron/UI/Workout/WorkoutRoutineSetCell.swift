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
    
    private var repetitionIntervalString: String? {
       return Self.repetitionIntervalString(
                minRepetitions: workoutRoutineSet.minRepetitions?.intValue,
                maxRepetitions: workoutRoutineSet.maxRepetitions?.intValue
       )
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Set")
                    
                    Text(repetitionIntervalString ?? " ")
                        .background(
                            Group {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .stroke(Color.accentColor)
                                        .padding(-4)
                                }
                            }
                        )
                }
                
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

extension WorkoutRoutineSetCell {
    static func repetitionIntervalString(minRepetitions: Int?, maxRepetitions: Int?) -> String? {
        if let minRepetitions = minRepetitions {
            if let maxRepetitions = maxRepetitions {
                // NOTE: this is an en-dash and not a hyphen
                return "\(minRepetitions == maxRepetitions ? "\(maxRepetitions)" : "\(minRepetitions)–\(maxRepetitions)")"
            } else {
                return "\(minRepetitions)+"
            }
        } else if let maxRepetitions = maxRepetitions {
            return "\(maxRepetitions)-"
        } else {
            return nil
        }
    }
}

#if DEBUG
struct WorkoutRoutineSetCell_Previews: PreviewProvider {
    static var workoutRoutineSet1: WorkoutRoutineSet = {
        let set = WorkoutRoutineSet(context: MockWorkoutData.metric.context)
        set.minRepetitionsValue = 5
        set.maxRepetitionsValue = 5
        return set
    }()
    
    static var workoutRoutineSet2: WorkoutRoutineSet = {
        let set = WorkoutRoutineSet(context: MockWorkoutData.metric.context)
        set.minRepetitionsValue = 8
        set.maxRepetitionsValue = 12
        return set
    }()
    
    static var workoutRoutineSet3: WorkoutRoutineSet = {
        let set = WorkoutRoutineSet(context: MockWorkoutData.metric.context)
        set.minRepetitionsValue = 5
        return set
    }()
    
    static var workoutRoutineSet4: WorkoutRoutineSet = {
        let set = WorkoutRoutineSet(context: MockWorkoutData.metric.context)
        set.maxRepetitionsValue = 5
        return set
    }()
    
    static var workoutRoutineSet5: WorkoutRoutineSet = {
        let set = WorkoutRoutineSet(context: MockWorkoutData.metric.context)
        return set
    }()
    
    static var workoutRoutineSet6: WorkoutRoutineSet = {
        let set = WorkoutRoutineSet(context: MockWorkoutData.metric.context)
        set.tagValue = .dropSet
        set.comment = "This is a comment"
        return set
    }()
    
    static var previews: some View {
        List {
            WorkoutRoutineSetCell(workoutRoutineSet: workoutRoutineSet1, index: 1, isSelected: false)
            
            WorkoutRoutineSetCell(workoutRoutineSet: workoutRoutineSet2, index: 2, isSelected: true)
            
            WorkoutRoutineSetCell(workoutRoutineSet: workoutRoutineSet3, index: 3, isSelected: false)
            
            WorkoutRoutineSetCell(workoutRoutineSet: workoutRoutineSet4, index: 4, isSelected: false)
            
            WorkoutRoutineSetCell(workoutRoutineSet: workoutRoutineSet5, index: 5, isSelected: false)
                
            WorkoutRoutineSetCell(workoutRoutineSet: workoutRoutineSet6, index: 6, isSelected: true)
        }
        .listStyle(GroupedListStyle())
        .mockEnvironment(weightUnit: .metric)
    }
}
#endif
