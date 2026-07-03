//
//  PlotData.swift
//  Graph
//
//  Created by Ulf Akerstedt-Inoue on 2019/06/11.
//  Copyright © 2019 hakkabon software. All rights reserved.
//

import Foundation
import UIKit

public struct PlotData {

    public enum PointStyle {
        case none
        case cross
        case circle
        case prism
        case square
        case star
        case triangle
    }

    var xy: [CGPoint]
    var x: [CGFloat]
    var y: [CGFloat]

    var pointStyle: PointStyle = .none
  
    var min: (x: CGFloat, y: CGFloat)
    var max: (x: CGFloat, y: CGFloat)

    var range: (y: CGFloat, x: CGFloat) {
        return (y: max.y - min.y, x: max.x - min.x)
    }
    var endpoints: (min: CGPoint, max: CGPoint) {
        return (min: CGPoint(x: min.x, y: min.y), max: CGPoint(x: max.x, y: max.y))
    }
    
    public typealias Fun = (Double) -> Double
    public typealias stride = StrideThrough<Double>

    public init(xs: [CGFloat], ys: [CGFloat], pointStyle: PointStyle = .none) {
        precondition(!xs.isEmpty, "PlotData requires at least one data point.")
        precondition(xs.count == ys.count, "xs and ys must have the same number of elements, got \(xs.count) and \(ys.count).")
        self.xy = Array(zip(xs, ys)).map{ CGPoint(x: $0.0, y: $0.1) }.sorted { $0.x < $1.x }
        x = self.xy.map() { $0.x }
        y = self.xy.map() { $0.y }
        
        self.pointStyle = pointStyle
        
        min = (x: x.min()!, y: y.min()!)
        max = (x: x.max()!, y: y.max()!)
    }

    public init(xs: [Double], ys: [Double], pointStyle: PointStyle = .none) {
        precondition(!xs.isEmpty, "PlotData requires at least one data point.")
        precondition(xs.count == ys.count, "xs and ys must have the same number of elements, got \(xs.count) and \(ys.count).")
        self.xy = Array(zip(xs, ys)).map{ CGPoint(x: $0.0, y: $0.1) }.sorted { $0.x < $1.x }
        x = self.xy.map() { $0.x }
        y = self.xy.map() { $0.y }
        
        self.pointStyle = pointStyle
        
        min = (x: x.min()!, y: y.min()!)
        max = (x: x.max()!, y: y.max()!)
    }

    public init(xs: StrideThrough<Double>, f: Fun, pointStyle: PointStyle = .none) {
        let ys = xs.map { f($0) }
        self.xy = Array(zip(xs, ys)).map{ CGPoint(x: $0.0, y: $0.1) }.sorted { $0.x < $1.x }
        precondition(!self.xy.isEmpty, "PlotData requires at least one data point.")
        x = self.xy.map() { $0.x }
        y = self.xy.map() { $0.y }
        
        self.pointStyle = pointStyle
        
        min = (x: x.min()!, y: y.min()!)
        max = (x: x.max()!, y: y.max()!)
    }
    
    public init(points: [CGPoint], pointStyle: PointStyle = .none) {
        precondition(!points.isEmpty, "PlotData requires at least one data point.")
        self.xy = points.sorted { $0.x < $1.x }
        x = self.xy.map() { $0.x }
        y = self.xy.map() { $0.y }

        self.pointStyle = pointStyle

        min = (x: x.min()!, y: y.min()!)
        max = (x: x.max()!, y: y.max()!)
    }
}
