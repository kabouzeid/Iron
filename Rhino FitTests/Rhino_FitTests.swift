//
//  Rhino_FitTests.swift
//  Rhino FitTests
//
//  Created by Karim Abou Zeid on 14.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import XCTest
@testable import Rhino_Fit

class Rhino_FitTests: XCTestCase {
    
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
        if let jsonString = try? String(contentsOf: jsonUrl) {
            self.measure {
                _ = EverkineticParser.parse(jsonString: jsonString)
            }
        }
    }
    
    func testEverkineticGroupingSpeed() {
        let jsonUrl = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent("exercises.json")
        if let jsonString = try? String(contentsOf: jsonUrl) {
            let exercises = EverkineticParser.parse(jsonString: jsonString)
            self.measure {
                _ = EverkineticDataProvider.splitIntoMuscleGroups(exercises: exercises)
            }
        }
    }
    
    func testEverkineticGrouping() {
        let jsonUrl = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent("exercises.json")
        if let jsonString = try? String(contentsOf: jsonUrl) {
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
    }
    
    func testUniq() {
        let array = ["Hello","Me","That","Me","Hello","Me","as","the"]
        XCTAssertEqual(array.uniq(), ["Hello","Me","That","as","the"])
    }
    
    func testSortByFrequency() {
        let array = ["Hello","Me","That","Me","Hello","Me"]
        XCTAssertEqual(array.sortedByFrequency(), ["Me","Hello","That"])
    }
    
}
