//
//  Workout+.swift
//  IronData
//
//  Created by Karim Abou Zeid on 02.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension Workout {
    public var dateInterval: DateInterval? {
        end.map { DateInterval(start: start, end: $0) }
    }
    
    public func displayTitle(infos: [(exercise: Exercise, workoutSets: [WorkoutSet])]) -> String {
        title ?? generatedTitle(infos: infos) ?? "Untitled"
    }

    public func generatedTitle(infos: [(exercise: Exercise, workoutSets: [WorkoutSet])]) -> String? {
        let bodyParts = bodyParts(infos: infos)
        switch bodyParts.count {
        case 1:
            return bodyParts[0].name.capitalized
        case 2...:
            return "\(bodyParts[0].name.capitalized) & \(bodyParts[1].name.capitalized)"
        default:
            return nil
        }
    }
    
    public func bodyParts(infos: [(exercise: Exercise, workoutSets: [WorkoutSet])]) -> [Exercise.BodyPart] {
        infos.flatMap { exerciseInfo in
            exerciseInfo.exercise.bodyPart.map { bodyPart in
                Array(repeating: bodyPart, count: max(exerciseInfo.workoutSets.count, 1))
            } ?? []
        }.sortedByFrequency().uniqed().reversed()
    }
}

private extension Array where Element : Hashable {
    func sortedByFrequency() -> [Element] {
        let frequencies = self.frequencies(from: self)
        return self.sorted { frequencies[$0]! < frequencies[$1]! }
    }
    
    mutating func sortByFrequency() {
        let frequencies = self.frequencies(from: self)
        self.sort { frequencies[$0]! < frequencies[$1]! }
    }
    
    private func frequencies(from array: Self) -> [Element: Int] {
        var frequencies = [Element: Int]()
        // count the frequency of each element
        for e in self {
            if frequencies[e] == nil {
                frequencies[e] = 1
            } else {
                frequencies[e] = frequencies[e]! + 1
            }
        }
        return frequencies
    }
}

private extension Array where Element: Equatable {
    func uniqed() -> [Element] {
        var arrayCopy = self
        arrayCopy.uniq()
        return arrayCopy
    }
    
    mutating func uniq() {
        var seen = [Element]()
        var index = 0
        while self.count > index {
            let element = self[index]
            if seen.contains(element) {
                remove(at: index)
            } else {
                seen.append(element)
                index += 1
            }
        }
    }
}
