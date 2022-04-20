//
//  ExerciseDetailView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 03.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import GRDBQuery

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Query<ExerciseRequest> private var exercise: Exercise?
    
    @State private var currentTab: Tab = .about
    
    init(exerciseID: Exercise.ID.Wrapped) {
        _exercise = Query(ExerciseRequest(exerciseID: exerciseID))
    }
    
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
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: exercise) { if $0 == nil { dismiss() } }
        .mirrorAppearanceState(to: $exercise.isAutoupdating)
    }
    
    var aboutView: some View {
        List {
            Section {
                let images = images
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
                    searchWeb()
                } label: {
                    Label("Search Web", systemImage: "magnifyingglass")
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    if let bodyPart = bodyPart {
                        Text(bodyPart)
                    }
                    Text(category)
                    if let movementType = movementType {
                        Text(movementType)
                    }
                }.padding(.vertical, 12)
            }
            
            let aliases = aliases
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

// MARK: - View Model

import IronData
import GRDB
import Combine

extension ExerciseDetailView {
    struct ExerciseRequest: Queryable {
        let exerciseID: Exercise.ID.Wrapped
        
        static var defaultValue: Exercise? { nil }
        
        func publisher(in database: AppDatabase) -> AnyPublisher<Exercise?, Error> {
            ValueObservation.tracking(Exercise.filter(id: exerciseID).fetchOne(_:))
                .publisher(in: database.databaseReader, scheduling: .immediate)
                .eraseToAnyPublisher()
        }
    }
    
    var title: String {
        exercise?.title ?? ""
    }
    
    var bodyPart: String? {
        exercise?.bodyPart?.name ?? nil
    }
    
    var category: String {
        exercise?.category.name ?? ""
    }
    
    var movementType: String? {
        exercise?.movementType?.name ?? nil
    }
    
    var images: [UIImage] {
        exercise?.images?.names.compactMap {
            pdfToUIImage(
                url: Exercise.imagesBundle.bundleURL.appendingPathComponent($0),
                fit: .init(width: 1000, height: 1000)
            )
        } ?? []
    }
    
    var aliases: [String] {
        exercise?.aliases?.split(separator: "\n").map { String($0) } ?? []
    }
    
    func searchWeb() {
        var components = URLComponents(string: "https://google.com/search")!
        components.queryItems = [URLQueryItem(name: "q", value: "How To \(title)")]
        UIApplication.shared.open(components.url!)
    }
    
    private func pdfToUIImage(url: URL, fit: CGSize) -> UIImage? {
        // TODO: move this off the UI thread
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

struct ExerciseDetailView_Previews: PreviewProvider {
    static let database = AppDatabase.random()
    static let exercise = try! database.databaseReader.read { db in try Exercise.fetchOne(db)! }
    
    static var previews: some View {
        ExerciseDetailView(exerciseID: exercise.id!)
            .environment(\.appDatabase, database)
    }
}
