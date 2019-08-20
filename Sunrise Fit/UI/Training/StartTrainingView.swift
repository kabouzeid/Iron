//
//  StartTrainingView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct StartTrainingView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    private var plateImage: some View {
        Image("plate")
            .resizable()
            .padding(48)
            .aspectRatio(contentMode: ContentMode.fit)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Group {
                    if colorScheme == .dark {
                        plateImage.colorInvert()
                    } else {
                        plateImage
                    }
                }.layoutPriority(1)
                
                Button("Start Workout") {
                    precondition((try? self.managedObjectContext.count(for: Training.currentTrainingFetchRequest)) ?? 0 == 0)
                    // create a new training
                    let training = Training(context: self.managedObjectContext)
                    training.isCurrentTraining = true
                    training.start = Date()
                    self.managedObjectContext.safeSave()
                }
                .padding()
                .foregroundColor(Color.white)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).foregroundColor(.accentColor))
                .padding()
            }
            .navigationBarTitle("Workout")
        }
    }
}

#if DEBUG
struct StartTrainingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StartTrainingView()
            
            StartTrainingView()
                .environment(\.colorScheme, .dark)
        }
        .environment(\.managedObjectContext, mockManagedObjectContext)
    }
}
#endif
