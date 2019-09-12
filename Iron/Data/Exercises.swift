//
//  Exercises.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 22.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

enum Exercises {
    static let exercises = loadExercises() ?? []
    static let exercisesGrouped = splitIntoMuscleGroups(exercises: loadExercises() ?? [])
    
    static func findExercise(id: Int) -> Exercise? {
        exercises.first { $0.id == id }
    }
    
    private static func loadExercises() -> [Exercise]? {
        let jsonUrl = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent("exercises.json")
        let decoder = JSONDecoder()
        do {
            return try decoder.decode([Exercise].self, from: Data(contentsOf: jsonUrl))
        } catch {
            print(error)
            assertionFailure()
            return nil
        }
    }

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
    
    private static func titleMatchesFilter(title: String, filter: String) -> Bool {
        for s in filter.split(separator: " ") {
            if !title.lowercased().contains(s) {
                return false
            }
        }
        return true
    }

    static func filterExercises(exercises: [Exercise], using filter: String) -> [Exercise] {
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
    
    static func filterExercises(exercises: [[Exercise]], using filter: String) -> [[Exercise]] {
        exercises
            .map { Self.filterExercises(exercises: $0, using: filter) }
            .filter { !$0.isEmpty }
    }
}
