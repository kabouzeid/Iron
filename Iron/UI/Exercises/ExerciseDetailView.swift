//
//  ExerciseDetailView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 03.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: ViewModel
    
    @State private var currentTab: Tab = .about
    
    enum Tab {
        case about, history, charts, records
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Picker", selection: $currentTab) {
                Text("About").tag(Tab.about)
                Text("History").tag(Tab.history)
                Text("Charts").tag(Tab.charts)
                Text("Records").tag(Tab.records)
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            switch currentTab {
            case .about:
                aboutView
            default:
                ScrollView {
                    Text("TODO")
                }
            }
            
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            try? await viewModel.fetchData(dismiss: { dismiss() })
        }
    }
    
    var aboutView: some View {
        List {
            Section {
                let images = viewModel.images
                if !images.isEmpty {
                    let interval = 1.0
                    TimelineView(.animation(minimumInterval: interval, paused: false)) { context in
                        HStack {
                            Spacer()
                            Image(uiImage: images[Int(context.date.timeIntervalSince1970 / interval) % images.count])
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(1.3, contentMode: .fill)
                            Spacer()
                        }
                    }
                }
            }
            
            Section {
                Button {
                    viewModel.searchWeb()
                } label: {
                    Label("Search Web", systemImage: "magnifyingglass")
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    if let bodyPart = viewModel.bodyPart {
                        Text(bodyPart)
                    }
                    Text(viewModel.category)
                    if let movementType = viewModel.movementType {
                        Text(movementType)
                    }
                }.padding(.vertical, 12)
            }
            
            let aliases = viewModel.aliases
            if !aliases.isEmpty {
                Section("Also known as") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(aliases, id: \.self) { alias in
                            Text(alias)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

extension ExerciseDetailView {
    init(exercise: Exercise) {
        _viewModel = StateObject(wrappedValue: .init(database: .shared, exercise: exercise))
    }
}

import IronData
import GRDB

extension ExerciseDetailView {
    @MainActor
    class ViewModel: ObservableObject {
        private let database: AppDatabase
        nonisolated init(database: AppDatabase, exercise: Exercise) {
            self.database = database
            self._exercise = Published(initialValue: exercise)
        }
        
        @Published private var exercise: Exercise
        
        func fetchData(dismiss: () -> Void) async throws {
            for try await exercise in exerciseStream() {
                withAnimation {
                    if let exercise = exercise {
                        self.exercise = exercise
                    } else {
                        dismiss()
                    }
                }
            }
        }
        
        func exerciseStream() -> AsyncValueObservation<Exercise?> {
            ValueObservation.tracking(Exercise.filter(id: exercise.id!).fetchOne)
                .removeDuplicates()
                .values(in: database.databaseReader, scheduling: .immediate)
        }
        
        var title: String {
            exercise.title
        }
        
        var bodyPart: String? {
            exercise.bodyPart?.name
        }
        
        var category: String {
            exercise.category.name
        }
        
        var movementType: String? {
            exercise.movementType?.name
        }
        
        var images: [UIImage] {
            exercise.images?.names.compactMap {
                pdfToUIImage(
                    url: Exercise.imagesBundle.bundleURL.appendingPathComponent($0),
                    fit: .init(width: 1000, height: 1000)
                )
            } ?? []
        }
        
        var aliases: [String] {
            exercise.aliases?.split(separator: "\n").map { String($0) } ?? []
        }
        
        func searchWeb() {
            var components = URLComponents(string: "https://google.com/search")!
            components.queryItems = [URLQueryItem(name: "q", value: "How To \(title)")]
            UIApplication.shared.open(components.url!)
        }
        
        private func pdfToUIImage(url: URL, fit: CGSize) -> UIImage? {
            guard let document = CGPDFDocument(url as CFURL) else { return nil }
            guard let page = document.page(at: 1) else { return nil }
            
            let pageRect = page.getBoxRect(.mediaBox)
            let scale = min(fit.width / pageRect.width, fit.height / pageRect.height)
            let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
            
            let renderer = UIGraphicsImageRenderer(size: size)
            let img = renderer.image { ctx in
                // flip
                ctx.cgContext.translateBy(x: 0, y: size.height)
                ctx.cgContext.scaleBy(x: 1, y: -1)
                
                // aspect fit
                ctx.cgContext.scaleBy(x: scale, y: scale)
                
                // draw
                ctx.cgContext.drawPDFPage(page)
            }
            
            return img
        }
    }
}

struct ExerciseDetailView_Previews: PreviewProvider {
    static let database = AppDatabase.random()
    static var previews: some View {
        ExerciseDetailView(viewModel: .init(
            database: database,
            exercise: try! database.databaseReader.read { db in try Exercise.fetchOne(db)! }
        ))
    }
}
