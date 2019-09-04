//
//  Rhino_FitTests.swift
//  Rhino FitTests
//
//  Created by Karim Abou Zeid on 14.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import XCTest
@testable import Sunrise_Fit

class Sunrise_FitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEverkineticParseSpeed() {
        let jsonUrl = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent("exercises.json")
        let jsonString = try! String(contentsOf: jsonUrl)
        self.measure {
            _ = EverkineticParser.parse(jsonString: jsonString)
        }
    }
    
    func testEverkineticGroupingSpeed() {
        let jsonUrl = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent("exercises.json")
        let jsonString = try! String(contentsOf: jsonUrl)
        let exercises = EverkineticParser.parse(jsonString: jsonString)
        self.measure {
            _ = EverkineticDataProvider.splitIntoMuscleGroups(exercises: exercises)
        }
    }
    
    func testEverkineticGrouping() {
        let jsonUrl = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent("exercises.json")
        let jsonString = try! String(contentsOf: jsonUrl)
        let exercises = EverkineticParser.parse(jsonString: jsonString)
        let groups = EverkineticDataProvider.splitIntoMuscleGroups(exercises: exercises)
        var totalCount = 0
        for group in groups {
            totalCount += group.count

            for exercise in group {
                XCTAssert(exercise.muscleGroup == group.first!.muscleGroup)
            }
        }
        XCTAssert(totalCount == exercises.count)
    }

    func testEverkineticPNGsExist() {
        let jsonUrl = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent("exercises.json")
        let jsonString = try! String(contentsOf: jsonUrl)
        let exercises = EverkineticParser.parse(jsonString: jsonString)
        for exercise in exercises {
            for png in exercise.png {
                let url = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent(png)
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
