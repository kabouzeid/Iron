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
//    let quote: Quote? = Quotes.quotes[4] // for the preview

    private var plateImage: some View {
        Image("plate")
            .resizable()
            .aspectRatio(contentMode: ContentMode.fit)
            .padding([.leading, .trailing], 40)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer()
                
                Group {
                    if colorScheme == .dark {
                        plateImage.colorInvert()
                    } else {
                        plateImage
                    }
                }.layoutPriority(1)
                
                Spacer()
                
                quote.map { // just to be safe, but should be never nil
                    Text($0.displayText)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
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
                
                Spacer()
            }
            .padding([.leading, .trailing])
            .navigationBarTitle("Workout")
        }
    }
}

#if DEBUG
struct StartTrainingView_Previews: PreviewProvider {
    struct StartTrainingViewDemo: View {
        var body: some View {
            TabView {
                StartTrainingView()
            }
        }
    }

    static var previews: some View {
        Group {
            StartTrainingViewDemo()
                .previewDevice(.init("iPhone SE"))
            
            StartTrainingViewDemo()
                .previewDevice(.init("iPhone 8"))
            
            StartTrainingViewDemo()
                .previewDevice(.init("iPhone Xs"))
            
            StartTrainingViewDemo()
                .previewDevice(.init("iPhone Xs Max"))
            
            StartTrainingViewDemo()
                .environment(\.colorScheme, .dark)
        }
        .environment(\.managedObjectContext, mockManagedObjectContext)
    }
}
#endif
