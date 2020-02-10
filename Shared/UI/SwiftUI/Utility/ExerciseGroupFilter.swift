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
                exerciseGroups = originalExerciseGroups
            }
            searchSubject.send(filter) // send even if filter.isEmpty because otherwise the searchSubject doesn't work correctly
        }
    }
    
    private let originalExerciseGroups: [ExerciseGroup]

    @Published var exerciseGroups: [ExerciseGroup]
    
    private var searchSubject = PassthroughSubject<String, Never>()
    private var cancellable: Cancellable?
    
    init(exerciseGroups: [ExerciseGroup]) {
        originalExerciseGroups = exerciseGroups
        self.exerciseGroups = exerciseGroups
        
        cancellable = searchSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.global(qos: .userInteractive))
            .map { ExerciseStore.filter(exerciseGroups: self.originalExerciseGroups, using: $0) }
            .receive(on: DispatchQueue.main)
            .assign(to: \.exerciseGroups, on: self)
    }
}
