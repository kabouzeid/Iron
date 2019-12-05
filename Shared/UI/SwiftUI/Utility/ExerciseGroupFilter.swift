//
//  ExerciseGroupFilter.swift
//  Iron
//
//  Created by Karim Abou Zeid on 16.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Combine
import WorkoutDataKit

class ExerciseGroupFilter: ObservableObject {
    var filter: String = "" {
        didSet {
            if filter.isEmpty {
                // not necessary, but when the user clears the search this makes it happen immediately
                exercises = originalExercises
            }
            searchSubject.send(filter) // send even if filter.isEmpty because otherwise the searchSubject doesn't work correctly
        }
    }
    
    private let originalExercises: [[Exercise]]

    @Published var exercises: [[Exercise]]
    
    private var searchSubject = PassthroughSubject<String, Never>()
    private var cancellable: Cancellable?
    
    init(exercises: [[Exercise]]) {
        originalExercises = exercises
        self.exercises = exercises
        
        cancellable = searchSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.global(qos: .userInteractive))
            .map { ExerciseStore.filter(exercises: self.originalExercises, using: $0) }
            .receive(on: DispatchQueue.main)
            .assign(to: \.exercises, on: self)
    }
}
