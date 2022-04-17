//
//  ExerciseList.swift
//  Iron
//
//  Created by Karim Abou Zeid on 02.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import IronData

struct ExerciseList: View {
    @StateObject var viewModel = ViewModel(database: .shared)
    
    @State private var searchQuery: String = ""
    @State private var selectedBodyPart: Exercise.BodyPart?
    @State private var selectedCategory: Exercise.Category?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Menu {
                        Picker("Body Part", selection: $selectedBodyPart) {
                            Text("Any").tag(nil as Exercise.BodyPart?)
                            ForEach(Exercise.BodyPart.allCases, id: \.self) { bodyPart in
                                Text(bodyPart.name.capitalized).tag(bodyPart as Exercise.BodyPart?)
                            }
                        }
                    } label: {
                        HStack {
                            Label(selectedBodyPart?.name.capitalized ?? "Body Part", systemImage: "line.3.horizontal.decrease.circle")
                                .animation(nil, value: selectedBodyPart?.name)
                            Spacer()
                        }
                        .foregroundColor(selectedBodyPart == nil ? .secondary : .accentColor)
                        .symbolVariant(selectedBodyPart == nil ? .none : .fill)
                    }
                    

                    Menu {
                        Picker("Category", selection: $selectedCategory) {
                            Text("Any").tag(nil as Exercise.Category?)
                            ForEach(Exercise.Category.allCases, id: \.self) { category in
                                Text(category.name.capitalized).tag(category as Exercise.Category?)
                            }
                        }
                    } label: {
                        HStack {
                            Label(selectedCategory?.name.capitalized ?? "Category", systemImage: "line.3.horizontal.decrease.circle")
                                .animation(nil, value: selectedCategory?.name)
                            Spacer()
                        }
                        .foregroundColor(selectedCategory == nil ? .secondary : .accentColor)
                        .symbolVariant(selectedCategory == nil ? .none : .fill)
                    }
                }
                .scenePadding([.bottom, .horizontal])
                .padding(.top, 4)
                
                Divider()
                
                List(viewModel.exercises(searchQuery: searchQuery, bodyPart: selectedBodyPart, category: selectedCategory)) { exercise in
                    NavigationLink {
                        ExerciseDetailView(exercise: exercise)
                    } label: {
                        Text(exercise.title)
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchQuery)
                .navigationTitle("Exercises")
            }
        }
        .task { try? await viewModel.fetchData() }
    }
}

import GRDB

extension ExerciseList {
    @MainActor
    class ViewModel: ObservableObject {
        let database: AppDatabase
        nonisolated init(database: AppDatabase) {
            self.database = database
        }
        
        @Published private var exercises = [Exercise]()
        
        func exercises(searchQuery: String, bodyPart: Exercise.BodyPart?, category: Exercise.Category?) -> [Exercise] {
            let searchQuery = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !searchQuery.isEmpty else { return exercises }

            func fuzzyMatches(title: String, searchQuery: String) -> Bool {
                for s in searchQuery.split(separator: " ") {
                    if !title.lowercased().contains(s) {
                        return false
                    }
                }
                return true
            }

            return exercises.filter { exercise in
                if let bodyPart = bodyPart {
                    guard exercise.bodyPart == bodyPart else { return false }
                }
                if let category = category {
                    guard exercise.category == category else { return false }
                }
                return fuzzyMatches(title: exercise.title, searchQuery: searchQuery) ||
                exercise.aliases.map { fuzzyMatches(title: $0, searchQuery: searchQuery) } ?? false
            }
        }
        
        func fetchData() async throws {
            for try await exercises in exerciseStream() {
                withAnimation {
                    self.exercises = exercises
                }
            }
        }
        
        func exerciseStream() -> AsyncValueObservation<[Exercise]> {
            ValueObservation.tracking(Exercise.all().orderByTitle().fetchAll)
                .values(in: database.databaseReader, scheduling: .immediate)
        }
    }
}

struct ExerciseList_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseList(viewModel: .init(database: .random()))
    }
}
