//
//  GeneralTests.swift
//  IronTests
//
//  Created by Karim Abou Zeid on 14.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import XCTest
import WorkoutDataKit
@testable import Iron

class GeneralTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    private func loadExercises() -> [Exercise] {
        let data = try! Data(contentsOf: ExerciseStore.defaultBuiltInExercisesURL)
        return try! JSONDecoder().decode([Exercise].self, from: data)
    }
    
    func testEverkineticGroupingSpeed() {
        let exercises = loadExercises()
        self.measure {
            _ = ExerciseStore.splitIntoMuscleGroups(exercises: exercises)
        }
    }
    
    func testEverkineticGrouping() {
        let exercises = loadExercises()
        let groups = ExerciseStore.splitIntoMuscleGroups(exercises: exercises)
        var totalCount = 0
        for group in groups {
            totalCount += group.exercises.count

            for exercise in group.exercises {
                XCTAssert(exercise.muscleGroup == group.title)
            }
        }
        XCTAssert(totalCount == exercises.count)
    }

    func testEverkineticPDFsExist() {
        let exercises = loadExercises()
        for exercise in exercises {
            for pdf in exercise.pdfPaths {
                let url = ExerciseStore.defaultBuiltInExercisesResourceURL.appendingPathComponent(pdf)
                XCTAssertNoThrow(try Data(contentsOf: url))
            }
        }
    }

    func testUniq() {
        var array = ["Hello","Me","That","Me","Hello","Me","as","the"]
        
        let arrayUniqed = array.uniqed()
        XCTAssertEqual(arrayUniqed, ["Hello","Me","That","as","the"])
        
        array.uniq()
        XCTAssertEqual(array, arrayUniqed)
    }
    
    func testSortByFrequency() {
        var array = ["Hello","Me","That","Me","Hello","Me"]
        
        let arraySorted = array.sortedByFrequency()
        XCTAssertEqual(arraySorted, ["That", "Hello", "Hello", "Me", "Me", "Me"])
        
        array.sortByFrequency()
        XCTAssertEqual(array, arraySorted)
    }

    func testWeightUnitConversion() {
        // correct conversion
        XCTAssertEqual(WeightUnit.convert(weight: 20, from: .metric, to: .imperial).rounded(), 44)
        XCTAssertEqual(WeightUnit.convert(weight: 45, from: .imperial, to: .metric).rounded(), 20)
        
        // no precision loss when converting back and forth
        XCTAssertEqual(WeightUnit.convert(weight: WeightUnit.convert(weight: 20, from: .metric, to: .imperial), from: .imperial, to: .metric), 20)
        XCTAssertEqual(WeightUnit.convert(weight: WeightUnit.convert(weight: 127.5, from: .metric, to: .imperial), from: .imperial, to: .metric), 127.5)
        XCTAssertEqual(WeightUnit.convert(weight: WeightUnit.convert(weight: 123980323.59392, from: .metric, to: .imperial), from: .imperial, to: .metric), 123980323.59392)
        
        XCTAssertEqual(WeightUnit.convert(weight: WeightUnit.convert(weight: 45, from: .imperial, to: .metric), from: .metric, to: .imperial), 45)
        XCTAssertEqual(WeightUnit.convert(weight: WeightUnit.convert(weight: 900, from: .imperial, to: .metric), from: .metric, to: .imperial), 900)
        XCTAssertEqual(WeightUnit.convert(weight: WeightUnit.convert(weight: 123980323.59392, from: .imperial, to: .metric), from: .metric, to: .imperial), 123980323.59392)
    }
}
