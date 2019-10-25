//
//  ExerciseStore.swift
//  Iron
//
//  Created by Karim Abou Zeid on 17.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

final class ExerciseStore: ObservableObject {
    static let shared = ExerciseStore(
        builtInExercisesURL: Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent("exercises.json"),
        customExercisesURL: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("custom_exercises.json")
    )
    
    let builtInExercises: [Exercise]
    
    @Published private(set) var customExercises: [Exercise]
    
    var exercises: [Exercise] {
        builtInExercises + customExercises
    }
    
    var shownExercises: [Exercise] {
        exercises.filter { !isHidden(exercise: $0) }
    }
    
    var hiddenExercises: [Exercise] {
        exercises.filter { isHidden(exercise: $0) }
    }
    
    private let customExercisesURL: URL?
    
    fileprivate init(builtInExercisesURL: URL, customExercisesURL: URL?) {
        builtInExercises = Self.loadBuiltInExercises(builtInExercisesURL: builtInExercisesURL)
        self.customExercisesURL = customExercisesURL
        customExercises = Self.loadCustomExercises(customExercisesURL: customExercisesURL)
        assert(!customExercises.contains { !$0.isCustom }, "Decoded custom exercise that is not custom.")
    }
    
    private static func loadBuiltInExercises(builtInExercisesURL: URL?) -> [Exercise] {
        guard let builtInExercisesURL = builtInExercisesURL else { fatalError("Built in exercises URL invalid") }
        do {
            return try JSONDecoder().decode([Exercise].self, from: Data(contentsOf: builtInExercisesURL))
        } catch {
            print(error)
            fatalError("Error decoding built in exercises")
        }
    }
    
    private static func loadCustomExercises(customExercisesURL: URL?) -> [Exercise] {
        guard let url = customExercisesURL else { return [] }
        do {
            return try JSONDecoder().decode([Exercise].self, from: Data(contentsOf: url))
        } catch {
            // try to migrate the exercises to the new UUID format
            let success = Self.migrateCustomExercises(customExercisesURL: url)
            guard success else { return [] }
            print("Successfully migrated custom exercises")
            return (try? JSONDecoder().decode([Exercise].self, from: Data(contentsOf: url))) ?? []
        }
    }
}

// MARK: - Hidden Exercises
extension ExerciseStore {
    func show(exercise: Exercise) {
        assert(!exercise.isCustom, "Makes no sense to show custom exercise.")
        self.objectWillChange.send()
        UserDefaults.standard.hiddenExerciseUuids.removeAll { $0 == exercise.uuid }
    }
    
    func hide(exercise: Exercise) {
        assert(!exercise.isCustom, "Makes no sense to hide custom exercise.")
        guard !isHidden(exercise: exercise) else { return }
        self.objectWillChange.send()
        UserDefaults.standard.hiddenExerciseUuids.append(exercise.uuid)
    }
    
    func isHidden(exercise: Exercise) -> Bool {
        UserDefaults.standard.hiddenExerciseUuids.contains(exercise.uuid)
    }
}

// MARK: - Split
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
                exercise.uuid == muscleGroup.last!.uuid
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

// MARK: - Find
extension ExerciseStore {
    func find(with uuid: UUID) -> Exercise? {
        Self.find(in: exercises, with: uuid)
    }
    
    static func find(in exercises: [Exercise], with uuid: UUID?) -> Exercise? {
        guard let uuid = uuid else { return nil }
        return exercises.first { $0.uuid == uuid }
    }
}

// MARK: - Filter
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

// MARK: - Custom Exercises
extension ExerciseStore {
    func createCustomExercise(title: String, description: String?, primaryMuscle: [String], secondaryMuscle: [String], type: Exercise.ExerciseType) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        guard !exercises.contains(where: { $0.title == title }) else { return }
        
        var description = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let d = description, d.isEmpty {
            description = nil
        }
        
        guard let url = customExercisesURL else { return }
        var customExercises = (try? JSONDecoder().decode([Exercise].self, from: Data(contentsOf: url))) ?? []
        
        customExercises.append(Exercise(uuid: UUID(), everkineticId: Exercise.customEverkineticId, title: title, alias: [], description: description, primaryMuscle: primaryMuscle, secondaryMuscle: secondaryMuscle, equipment: type.equipment.map { [$0] } ?? [], steps: [], tips: [], references: [], pdfPaths: []))
        do { try JSONEncoder().encode(customExercises).write(to: url, options: .atomic) } catch { return }
        
        self.customExercises = (try? JSONDecoder().decode([Exercise].self, from: Data(contentsOf: url))) ?? []
    }
    
    func updateCustomExercise(with uuid: UUID, title: String, description: String?, primaryMuscle: [String], secondaryMuscle: [String], type: Exercise.ExerciseType) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        guard !exercises.contains(where: { $0.title == title && $0.uuid != uuid }) else { return }
        
        var description = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let d = description, d.isEmpty {
            description = nil
        }
        
        guard let url = customExercisesURL else { return }
        var customExercises = (try? JSONDecoder().decode([Exercise].self, from: Data(contentsOf: url))) ?? []
        
        guard customExercises.contains(where: { $0.uuid == uuid }) else { return } // make sure the exercise exists
        customExercises.removeAll { $0.uuid == uuid } // remove the old exercise
        customExercises.append(Exercise(uuid: uuid, everkineticId: Exercise.customEverkineticId, title: title, alias: [], description: description, primaryMuscle: primaryMuscle, secondaryMuscle: secondaryMuscle, equipment: type.equipment.map { [$0] } ?? [], steps: [], tips: [], references: [], pdfPaths: []))
        do { try JSONEncoder().encode(customExercises).write(to: url, options: .atomic) } catch { return }
        
        self.customExercises = ((try? JSONDecoder().decode([Exercise].self, from: Data(contentsOf: url))) ?? [])
    }
    
    func deleteCustomExercise(with uuid: UUID) {
        guard let url = customExercisesURL else { return }
        guard var customExercises = try? JSONDecoder().decode([Exercise].self, from: Data(contentsOf: url)) else { return }
        customExercises.removeAll { $0.uuid == uuid }
        do { try JSONEncoder().encode(customExercises).write(to: url, options: .atomic) } catch { return }
        self.customExercises = (try? JSONDecoder().decode([Exercise].self, from: Data(contentsOf: url))) ?? []
    }
}

// MARK: - Custom Exercise Migration
extension ExerciseStore {
    private static func migrateCustomExercises(customExercisesURL: URL) -> Bool { // returns true if a migration was made successfully
        do { _ = try JSONDecoder().decode([Exercise].self, from: Data(contentsOf: customExercisesURL)) } catch {
            let oldExercises: [ExerciseWithOldId]
            do { oldExercises = try JSONDecoder().decode([ExerciseWithOldId].self, from: Data(contentsOf: customExercisesURL)) } catch { return false }
            let newExercises = oldExercises
                .map {
                    // NOTE: don't overwrite id here, because we still need it in the Core Data migration
                    Exercise(uuid: UUID(), everkineticId: $0.id, title: $0.title, alias: [], description: $0.primer, primaryMuscle: $0.primary, secondaryMuscle: $0.secondary, equipment: $0.equipment, steps: [], tips: [], references: [], pdfPaths: [])
                }
            do { try JSONEncoder().encode(newExercises).write(to: customExercisesURL, options: .atomic) } catch { return false }
            return true
        }
        // no migration needed
        return false
    }
    
    struct ExerciseWithOldId: Codable {
        let id: Int // the old id (before we switched to UUID)
        let title: String
        let primer: String?
        let primary: [String]
        let secondary: [String]
        let equipment: [String]
    }
}
