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
    
    @State private var quote = Quotes.quotes.randomElement()

    private var plateImage: some View {
        Image("plate")
            .resizable()
            .aspectRatio(contentMode: ContentMode.fit)
            .padding([.leading, .trailing])
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Group {
                    if colorScheme == .dark {
                        plateImage.colorInvert()
                    } else {
                        plateImage
                    }
                }.layoutPriority(1)
                
                quote.map { // just to be safe, but should be never nil
                    Text($0.displayText)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    precondition((try? self.managedObjectContext.count(for: Training.currentTrainingFetchRequest)) ?? 0 == 0)
                    // create a new training
                    let training = Training(context: self.managedObjectContext)
                    training.isCurrentTraining = true
                    training.start = Date()
                    self.managedObjectContext.safeSave()
                }) {
                   Text("Start Workout")
                        .padding()
                        .foregroundColor(Color.white)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).foregroundColor(.accentColor))
                }
            }
            .padding([.leading, .trailing])
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
