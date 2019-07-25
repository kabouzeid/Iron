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
        let array = ["Hello","Me","That","Me","Hello","Me","as","the"]
        XCTAssertEqual(array.uniq(), ["Hello","Me","That","as","the"])
    }
    
    func testSortByFrequency() {
        let array = ["Hello","Me","That","Me","Hello","Me"]
        XCTAssertEqual(array.sortedByFrequency(), ["Me","Hello","That"])
    }

    func testDoubleShortStringValue() {
        XCTAssertEqual(Double(1.23456).shortStringValue, "1.23")
        XCTAssertEqual(Double(1.2).shortStringValue, "1.2")
        XCTAssertEqual(Double(1).shortStringValue, "1")
    }
    
    func testWeightUnitConversion() {
        XCTAssertEqual(WeightUnit.convert(weight: 20, from: .metric, to: .imperial).rounded(), 44)
        XCTAssertEqual(WeightUnit.convert(weight: 45, from: .imperial, to: .metric).rounded(), 20)
    }
    
    func testSignificantFractionDigits() {
        XCTAssertEqual(Double(1.23456).significantFractionDigits(precision: 0), 0)
        XCTAssertEqual(Double(1.23456).significantFractionDigits(precision: 1), 1)
        XCTAssertEqual(Double(1.23456).significantFractionDigits(precision: 3), 3)
        XCTAssertEqual(Double(1.23456).significantFractionDigits(precision: 5), 5)
        XCTAssertEqual(Double(1.23456).significantFractionDigits(precision: 6), 5)

        XCTAssertEqual(Double(1.20456).significantFractionDigits(precision: 0), 0)
        XCTAssertEqual(Double(1.20456).significantFractionDigits(precision: 1), 1)
        XCTAssertEqual(Double(1.20456).significantFractionDigits(precision: 2), 1)
        XCTAssertEqual(Double(1.20456).significantFractionDigits(precision: 3), 3)
        XCTAssertEqual(Double(1.20456).significantFractionDigits(precision: 4), 4)
        XCTAssertEqual(Double(1.20456).significantFractionDigits(precision: 5), 5)
        XCTAssertEqual(Double(1.20456).significantFractionDigits(precision: 6), 5)

        XCTAssertEqual(Double(1.20999).significantFractionDigits(precision: 0), 0)
        XCTAssertEqual(Double(1.20999).significantFractionDigits(precision: 1), 1)
        XCTAssertEqual(Double(1.20999).significantFractionDigits(precision: 2), 1)
        XCTAssertEqual(Double(1.20999).significantFractionDigits(precision: 3), 3)
        XCTAssertEqual(Double(1.20999).significantFractionDigits(precision: 4), 4)
        XCTAssertEqual(Double(1.20999).significantFractionDigits(precision: 5), 5)
    }
    
}
