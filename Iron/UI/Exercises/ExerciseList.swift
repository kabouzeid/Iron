//
//  ExerciseList.swift
//  Iron
//
//  Created by Karim Abou Zeid on 02.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import GRDBQuery

struct ExerciseList: View {
    @Query(ExercisesRequest()) private var exercises: [Exercise]
    
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
                
                List(filteredExercises(searchQuery: searchQuery, bodyPart: selectedBodyPart, category: selectedCategory)) { exercise in
                    NavigationLink {
                        ExerciseDetailView(exerciseID: exercise.id!)
                    } label: {
                        Text(exercise.title)
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchQuery)
                .navigationTitle("Exercises")
            }
        }
        .mirrorAppearanceState(to: $exercises.isAutoupdating)
    }
}

// MARK: - View Model

import IronData
import GRDB
import Combine

extension ExerciseList {
    struct ExercisesRequest: Queryable {
        static var defaultValue: [Exercise] { [] }
        
        func publisher(in database: AppDatabase) -> AnyPublisher<[Exercise], Error> {
            ValueObservation.tracking(Exercise.fetchAll(_:))
                .publisher(in: database.databaseReader, scheduling: .immediate)
                .eraseToAnyPublisher()
        }
    }
    
    func filteredExercises(searchQuery: String, bodyPart: Exercise.BodyPart?, category: Exercise.Category?) -> [Exercise] {
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
}

struct ExerciseList_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseList()
            .environment(\.appDatabase, .random())
    }
}
