//
//  ExerciseStore.swift
//  Iron
//
//  Created by Karim Abou Zeid on 17.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

final class ExerciseStore: ObservableObject {
    let builtInExercises: [Exercise]
    @Published private(set) var customExercises: [Exercise]
    
    var exercises: [Exercise] {
        builtInExercises + customExercises
    }
    
    private let customExercisesURL: URL?
    
    fileprivate init(builtInExercisesURL: URL, customExercisesURL: URL?) {
        do {
            self.builtInExercises = try Self.loadExercises(from: builtInExercisesURL)
        } catch {
            print(error)
            fatalError("Could not load built in exercises")
        }
        self.customExercisesURL = customExercisesURL
        if let url = customExercisesURL {
            self.customExercises = (try? Self.loadExercises(from: url)) ?? []
        } else {
            self.customExercises = []
        }
    }
    
    private static func loadExercises(from url: URL) throws -> [Exercise] {
        try JSONDecoder().decode([Exercise].self, from: Data(contentsOf: url))
    }
}

extension ExerciseStore {
    func createCustomExercise(title: String, description: String?, primaryMuscle: [String], secondaryMuscle: [String], barbellBased: Bool) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        var description = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let d = description, d.isEmpty {
            description = nil
        }
        
        guard let url = customExercisesURL else { return }
        var customExercises = (try? Self.loadExercises(from: url)) ?? []
        guard let newId = getNewId(in: customExercises) else { return }
        
        customExercises.append(Exercise(id: newId, title: title, alias: [], description: description, primaryMuscle: primaryMuscle, secondaryMuscle: secondaryMuscle, equipment: barbellBased ? ["barbell"] : [], steps: [], tips: [], references: [], pdfPaths: []))
        do { try JSONEncoder().encode(customExercises).write(to: url, options: .atomic) } catch { return }
        
        self.customExercises = (try? Self.loadExercises(from: url)) ?? []
    }
    
    func deleteCustomExercise(with id: Int) {
        guard let url = customExercisesURL else { return }
        guard var customExercises = try? Self.loadExercises(from: url) else { return }
        customExercises.removeAll { $0.id == id }
        do { try JSONEncoder().encode(customExercises).write(to: url, options: .atomic) } catch { return }
        self.customExercises = (try? Self.loadExercises(from: url)) ?? []
    }
    
    private func getNewId(in customExercises: [Exercise]) -> Int? {
        guard !customExercises.isEmpty else { return Exercise.customExerciseIdStart }
        guard let maxId = customExercises.map({ $0.id }).max() else { return nil }
        let newId = maxId + 1
        guard newId <= Int16.max else { return nil }
        precondition(newId >= Exercise.customExerciseIdStart)
        return newId
    }
}

extension ExerciseStore {
    static func splitIntoMuscleGroups(exercises: [Exercise]) -> [[Exercise]] {
        var groups = [[Exercise]]()
        var nextIndex = 0
        let exercises = exercises.sorted { (a, b) -> Bool in
            a.muscleGroup < b.muscleGroup
        }
        while (exercises.count > nextIndex) {
            let groupName = exercises[nextIndex].muscleGroup
            var muscleGroup = exercises.filter({ (exercise) -> Bool in
                exercise.muscleGroup == groupName
            })
            
            nextIndex = exercises.firstIndex(where: { (exercise) -> Bool in
                exercise.id == muscleGroup.last!.id
            })! + 1
            
            // do this after nextIndex is set
            muscleGroup = muscleGroup.sorted(by: { (a, b) -> Bool in
                a.title < b.title
            })
            groups.append(muscleGroup)
        }
        return groups
    }
}

extension ExerciseStore {
    func find(with id: Int) -> Exercise? {
        Self.find(in: exercises, with: id)
    }
    
    static func find(in exercises: [Exercise], with id: Int) -> Exercise? {
        exercises.first { $0.id == id }
    }
}

extension ExerciseStore {
    private static func titleMatchesFilter(title: String, filter: String) -> Bool {
        for s in filter.split(separator: " ") {
            if !title.lowercased().contains(s) {
                return false
            }
        }
        return true
    }

    static func filter(exercises: [Exercise], using filter: String) -> [Exercise] {
        let filter = filter.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !filter.isEmpty else { return exercises }
        
        return exercises.filter { exercise in
            for title in [exercise.title] + exercise.alias {
                if titleMatchesFilter(title: title, filter: filter) {
                    return true
                }
            }
            return false
        }
    }
    
    static func filter(exercises: [[Exercise]], using filter: String) -> [[Exercise]] {
        exercises
            .map { Self.filter(exercises: $0, using: filter) }
            .filter { !$0.isEmpty }
    }
}

// singleton
let appExerciseStore = ExerciseStore(
    builtInExercisesURL: Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent("exercises.json"),
    customExercisesURL: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("custom_exercises.json")
)
