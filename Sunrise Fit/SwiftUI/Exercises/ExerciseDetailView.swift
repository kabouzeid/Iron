//
//  ExerciseDetailView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 04.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ExerciseDetailView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore // TODO: (bug in beta3?) remove in future, only needed for the presentation of the statistics view
    var exercise: Exercise
    
    private var exerciseImages: [UIImage] {
        var images = [UIImage]()
        for png in exercise.png {
            let url = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent(png)
            if let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
                images.append(image)
            }
        }
        return images
    }
    
    private func imageHeight(geometry: GeometryProxy) -> Length {
        min(geometry.size.width, (geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom) * 0.7)
    }
    
    var body: some View {
        GeometryReader { geometry in
            List {
                if !self.exercise.png.isEmpty {
                    Section {
                        AnimatedImageView(uiImages: self.exerciseImages, duration: 2)
                            .frame(height: self.imageHeight(geometry: geometry))
                    }
                }
                
                if !self.exercise.description.isEmpty {
                    Section {
                        Text(self.exercise.description)
                            .lineLimit(nil)
                    }
                }
                
                if !(self.exercise.primaryMuscleCommonName.isEmpty && self.exercise.secondaryMuscleCommonName.isEmpty) {
                    Section(header: Text("Muscles".uppercased())) {
                        ForEach(self.exercise.primaryMuscleCommonName.identified(by: \.hashValue)) { primaryMuscle in
                            HStack {
                                Text(primaryMuscle.capitalized as String)
                                Spacer()
                                Text("Primary")
                                    .color(.secondary)
                            }
                        }
                        ForEach(self.exercise.secondaryMuscleCommonName.identified(by: \.hashValue)) { secondaryMuscle in
                            HStack {
                                Text(secondaryMuscle.capitalized as String)
                                Spacer()
                                Text("Secondary")
                                    .color(.secondary)
                            }
                        }
                    }
                }
                
                if !self.exercise.steps.isEmpty {
                    Section(header: Text("Steps".uppercased())) {
                        ForEach(self.exercise.steps.identified(by: \.hashValue)) { step in
                            Text(step as String)
                                .lineLimit(nil)
                        }
                    }
                }
                
                if !self.exercise.tips.isEmpty {
                    Section(header: Text("Tips".uppercased())) {
                        ForEach(self.exercise.tips.identified(by: \.hashValue)) { tip in
                            Text(tip as String)
                                .lineLimit(nil)
                        }
                    }
                }
                
                if !self.exercise.references.isEmpty {
                    Section(header: Text("References".uppercased())) {
                        ForEach(self.exercise.references.identified(by: \.hashValue)) { reference in
                            Button(reference as String) {
                                if let url = URL(string: reference) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.grouped)
        }
        .navigationBarTitle(Text(exercise.title), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack {
                PresentationLink(destination: ExerciseHistoryView(exercise: exercise)
                    .environmentObject(trainingsDataStore)
                    .environmentObject(settingsStore)) {
                    Image(systemName: "clock")
                }
                PresentationLink(destination: ExerciseStatisticsView(exercise: exercise)
                    .environmentObject(trainingsDataStore)
                    .environmentObject(settingsStore)) {
                    Image(systemName: "waveform.path.ecg")
                }
            }
        )
    }
}

#if DEBUG
struct ExerciseDetailView_Previews : PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExerciseDetailView(exercise: EverkineticDataProvider.findExercise(id: 99)!)
                .environmentObject(mockTrainingsDataStore)
                .environmentObject(mockSettingsStoreMetric)
        }
    }
}
#endif
