//
//  ExerciseFilter.swift
//  Iron
//
//  Created by Karim Abou Zeid on 16.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Combine

class ExerciseFilter: ObservableObject {
    var filter: String {
        willSet {
            if isEmpty != newValue.isEmpty {
                isEmpty = newValue.isEmpty
            }
            searchSubject.send(newValue)
        }
    }
    
    @Published var exercises: [Exercise]
    @Published var isEmpty: Bool
    
    private var searchSubject = PassthroughSubject<String, Never>()
    private var cancellable: Cancellable?
    
    init(exercises: [Exercise], filter: String = "") {
        self.exercises = exercises
        self.filter = filter
        self.isEmpty = filter.isEmpty
        
        cancellable = searchSubject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.global(qos: .userInteractive))
            .removeDuplicates()
            .map { Exercises.filterExercises(exercises: exercises, using: $0) }
            .receive(on: DispatchQueue.main)
            .assign(to: \.exercises, on: self)
    }
}
