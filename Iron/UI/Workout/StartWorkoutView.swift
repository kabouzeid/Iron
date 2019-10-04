//
//  StartWorkoutView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct StartWorkoutView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @EnvironmentObject var settingsStore: SettingsStore
    
    @State private var quote = Quotes.quotes.randomElement()
//    let quote: Quote? = Quotes.quotes[4] // for the preview

    private var plateImage: some View {
        Image(settingsStore.weightUnit == .imperial ? "plate_lbs" : "plate_kg")
            .resizable()
            .aspectRatio(contentMode: ContentMode.fit)
//            .frame(maxWidth: 500, maxHeight: 500)
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
                    precondition((try? self.managedObjectContext.count(for: Workout.currentWorkoutFetchRequest)) ?? 0 == 0)
                    // create a new workout
                    let workout = Workout(context: self.managedObjectContext)
                    workout.isCurrentWorkout = true
                    workout.start = Date()
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
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#if DEBUG
struct StartWorkoutView_Previews: PreviewProvider {
    struct StartWorkoutViewDemo: View {
        var body: some View {
            TabView {
                StartWorkoutView()
            }
        }
    }

    static var previews: some View {
        Group {
            StartWorkoutViewDemo()
                .previewDevice(.init("iPhone SE"))
            
            StartWorkoutViewDemo()
                .previewDevice(.init("iPhone 8"))
            
            StartWorkoutViewDemo()
                .previewDevice(.init("iPhone Xs"))
            
            StartWorkoutViewDemo()
                .previewDevice(.init("iPhone Xs Max"))
            
            StartWorkoutViewDemo()
                .environment(\.colorScheme, .dark)
        }
        .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
