//
//  Benchmark.swift
//  Benchmark
//
//  Created by shoji on 2016/05/24.
//  Copyright © 2016年 com.shoji. All rights reserved.
//

import CoreFoundation

public struct Benchmark {

    private let startTimeInterval: CFAbsoluteTime
    private let key: String
    private static var sharedInstance: Benchmark?

    public init(key: String) {
        startTimeInterval = CFAbsoluteTimeGetCurrent()
        self.key = key
    }

    public func finish() {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTimeInterval
        let formatedElapsed = String(format: "%.5f", elapsed)
        print("\(key): \(formatedElapsed) sec.")
    }

    public static func start(_ key: String = "Benchmark") {
        sharedInstance = Benchmark(key: key)
    }

    public static func finish() {
        sharedInstance?.finish()
        sharedInstance = nil
    }
    
    @discardableResult
    public static func measure<T>(key: String = "Benchmark", _ block: () -> T) -> T {
        let benchmark = Benchmark(key: key)
        let result = block()
        benchmark.finish()
        return result
    }

    @discardableResult
    public static func measure<T>(key: String = "Benchmark", _ block: () throws -> T) rethrows -> T {
        let benchmark = Benchmark(key: key)
        let result = try block()
        benchmark.finish()
        return result
    }
}

prefix operator ⏲
public prefix func ⏲<T>(handler: () -> T) -> T {
    return Benchmark.measure(handler)
}
