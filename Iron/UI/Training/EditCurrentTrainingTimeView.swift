//
//  EditTrainingStartEndView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 14.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct EditCurrentTrainingTimeView: View {
    @ObservedObject var training: Training
    
    var automaticTimeTracking: Binding<Bool> {
        Binding(
            get: {
                self.training.end == nil
            },
            set: { enabled in
                if enabled {
                    precondition(self.training.isCurrentTraining)
                    self.training.end = nil
                } else {
                    self.training.end = self.training.safeEnd
                }
            }
        )
    }

    var body: some View {
        List {
            Section {
                DatePicker(selection: $training.safeStart, in: ...min(training.safeEnd, Date())) {
                    Text("Start")
                }
                
                Toggle("Automatic Time Tracking", isOn: automaticTimeTracking)

                if !automaticTimeTracking.wrappedValue {
                    DatePicker(selection: $training.safeEnd, in: training.safeStart...Date()) {
                        Text("End")
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}

#if DEBUG
struct EditTrainingStartEndView_Previews: PreviewProvider {
    static var previews: some View {
        EditCurrentTrainingTimeView(training: mockCurrentTraining)
    }
}
#endif
