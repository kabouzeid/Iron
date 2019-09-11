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
    @Environment(\.managedObjectContext) var managedObjectContext
    var exercise: Exercise
    
    @State private var showingStatisticsSheet = false
    @State private var showingHistorySheet = false
    
    private func pdfToImage(url: URL, fit: CGSize) -> UIImage? {
        guard let document = CGPDFDocument(url as CFURL) else { return nil }
        guard let page = document.page(at: 1) else { return nil }
        
        let pageRect = page.getBoxRect(.mediaBox)
        let scale = min(fit.width / pageRect.width, fit.height / pageRect.height)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pageRect.width * scale, height: pageRect.height * scale))
        let img = renderer.image { ctx in
            // flip
            ctx.cgContext.translateBy(x: 0, y: fit.height)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            // aspect fit
            ctx.cgContext.scaleBy(x: scale, y: scale)
            // draw
            ctx.cgContext.setFillColor(UIColor.red.cgColor)
            ctx.cgContext.setStrokeColor(UIColor.green.cgColor)
            ctx.cgContext.drawPDFPage(page)
        }
        
        return img
    }

    private func exerciseImages(width: CGFloat, height: CGFloat) -> [UIImage] {
        exercise.pdfPaths
            .map { Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent($0) }
            .compactMap { pdfToImage(url: $0, fit: CGSize(width: width, height: height)) }
            .compactMap { $0.tinted(with: .label) }
    }
    
    private func imageHeight(geometry: GeometryProxy) -> CGFloat {
        min(geometry.size.width, (geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom) * 0.7)
    }
    
    private var exerciseHistorySheet: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("History")
                    .font(.headline)
                HStack {
                    Button("Close") {
                        self.showingHistorySheet = false
                    }
                    Spacer()
                }
            }
            .padding()
            Divider()
            ExerciseHistoryView(exercise: self.exercise)
                // TODO: as of beta6 the environment is not shared with the sheets
                .environmentObject(self.settingsStore)
                .environment(\.managedObjectContext, self.managedObjectContext)
        }
    }
    
    private var exerciseStatisticsSheet: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Statistics")
                    .font(.headline)
                HStack {
                    Button("Close") {
                        self.showingStatisticsSheet = false
                    }
                    Spacer()
                }
            }
            .padding()
            Divider()
            ExerciseStatisticsView(exercise: self.exercise)
                // TODO: as of beta6 the environment is not shared with the sheets
                .environmentObject(self.settingsStore)
                .environment(\.managedObjectContext, self.managedObjectContext)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            List {
                if !self.exercise.pdfPaths.isEmpty {
                    Section {
                        AnimatedImageView(uiImages: self.exerciseImages(width: geometry.size.width, height: self.imageHeight(geometry: geometry)), duration: 2)
                            .frame(height: self.imageHeight(geometry: geometry))
                    }
                }
                
                if self.exercise.description != nil {
                    Section {
                        Text(self.exercise.description!)
                            .lineLimit(nil)
                    }
                }
                
                if !(self.exercise.primaryMuscleCommonName.isEmpty && self.exercise.secondaryMuscleCommonName.isEmpty) {
                    Section(header: Text("Muscles".uppercased())) {
                        ForEach(self.exercise.primaryMuscleCommonName, id: \.hashValue) { primaryMuscle in
                            HStack {
                                Text(primaryMuscle.capitalized as String)
                                Spacer()
                                Text("Primary")
                                    .foregroundColor(.secondary)
                            }
                        }
                        ForEach(self.exercise.secondaryMuscleCommonName, id: \.hashValue) { secondaryMuscle in
                            HStack {
                                Text(secondaryMuscle.capitalized as String)
                                Spacer()
                                Text("Secondary")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if !self.exercise.steps.isEmpty {
                    Section(header: Text("Steps".uppercased())) {
                        ForEach(self.exercise.steps, id: \.hashValue) { step in
                            Text(step as String)
                                .lineLimit(nil)
                        }
                    }
                }
                
                if !self.exercise.tips.isEmpty {
                    Section(header: Text("Tips".uppercased())) {
                        ForEach(self.exercise.tips, id: \.hashValue) { tip in
                            Text(tip as String)
                                .lineLimit(nil)
                        }
                    }
                }
                
                if !self.exercise.references.isEmpty {
                    Section(header: Text("References".uppercased())) {
                        ForEach(self.exercise.references, id: \.hashValue) { reference in
                            Button(reference as String) {
                                if let url = URL(string: reference) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
        }
        .navigationBarTitle(Text(exercise.title), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack {
                Button(action: { self.showingHistorySheet = true }) {
                    Image(systemName: "clock")
                }
                .sheet(isPresented: $showingHistorySheet) { self.exerciseHistorySheet }
                Button(action: { self.showingStatisticsSheet = true }) {
                    Image(systemName: "waveform.path.ecg")
                }
                .sheet(isPresented: $showingStatisticsSheet) { self.exerciseStatisticsSheet }
            }
        )
    }
}

#if DEBUG
struct ExerciseDetailView_Previews : PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExerciseDetailView(exercise: Exercises.findExercise(id: 99)!)
                .environmentObject(mockSettingsStoreMetric)
                .environment(\.managedObjectContext, mockManagedObjectContext)
        }
    }
}
#endif
