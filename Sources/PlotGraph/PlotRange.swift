//
//  PlotRange.swift
//  Graph
//
//  Created by Ulf Akerstedt-Inoue on 2019/06/17.
//  Copyright © 2019 hakkabon software. All rights reserved.
//

import Foundation
import UIKit

public struct PlotRange {

    // Ticks of range.
    private(set) var delta: CGFloat = 0
    private(set) var min: CGFloat = 0
    private(set) var max: CGFloat = 0
    
    // Length of range.
    var range: CGFloat { return max - min }

    var minPoint: CGFloat
    var maxPoint: CGFloat
    var maxTicks: CGFloat = 10

    /// Instantiates a new instance of the PlotRange class.
    ///
    /// - Parameters:
    ///   - min: The minimum data point on the axis
    ///   - max: The maximum data point on the axis
    public init(min: CGFloat, max: CGFloat) {
        self.minPoint = min
        self.maxPoint = max
        calculate()
    }
    
    /// Calculate and update values for tick spacing and nice
    /// minimum and maximum data points on the axis.
    mutating private func calculate() {
        let span = maxPoint - minPoint
        let range = approximate(x: span == 0 ? 1 : span, round: false)
        self.delta = approximate(x: range / (maxTicks - 1), round: true)
        self.min = floor(minPoint / delta) * delta
        self.max = ceil(maxPoint / delta) * delta
    }
    
    /// Returns the largest approximation to the given number. Rounds
    /// the number if round = true. Takes the ceiling if round = false.
    ///
    /// - Parameters:
    ///   - range: The data range
    ///   - round: Whether to round the result
    /// - Returns: A "nice" number to be used for the data range.
    private func approximate(x: CGFloat, round: Bool) -> CGFloat {
        let exponent: CGFloat = floor(log10(x))   // exponent of x
        let f: CGFloat = x / pow(10, exponent)   // fractional part of x
        var rf: CGFloat = 0                      // 'rounded' fraction
        
        if round {
            if f < 1.5 { rf = 1 }
            else if f < 3 { rf = 2 }
            else if f < 7 { rf = 5 }
            else { rf = 10 }
        } else {
            if f <= 1 { rf = 1 }
            else if f <= 2 { rf = 2 }
            else if f <= 5 { rf = 5 }
            else { rf = 10 }
        }
        return rf * pow(10, exponent)
    }
}
